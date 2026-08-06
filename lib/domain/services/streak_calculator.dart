import 'package:equatable/equatable.dart';

import '../../core/utils/local_day.dart';
import '../entities/streak_state.dart';

/// How one calendar day renders in a [StreakCalculator.buildChain] result.
enum DayChainState {
  /// The daily challenge was completed that day.
  completed,

  /// Missed, but covered by a freeze — the chain stayed intact.
  frozen,

  /// Missed beyond available grace. Rendered neutrally, never as an error
  /// or loss — a fresh chain simply started again after this point.
  missed,

  /// The current local day.
  today,

  /// Before the child's first-ever completion, or outside any known
  /// activity — an empty placeholder, not a miss.
  none,
}

/// One day's rendered state in a streak chain view.
final class DayChainEntry extends Equatable {
  const DayChainEntry({required this.dateKey, required this.state});

  final String dateKey;
  final DayChainState state;

  @override
  List<Object?> get props => [dateKey, state];
}

/// The outcome of recording a completion: the new [state], and — if this
/// completion just reached a milestone length — the milestone's streak
/// length in [newMilestone] (for awarding a streak sticker).
final class StreakUpdate extends Equatable {
  const StreakUpdate({required this.state, required this.newMilestone});

  final StreakState state;
  final int? newMilestone;

  @override
  List<Object?> get props => [state, newMilestone];
}

/// Pure "chain with grace" streak logic. Every method takes `today`
/// explicitly (never reads the system clock itself) so streak behaviour is
/// fully deterministic and unit-testable across day rollovers, timezones,
/// and repeated same-day calls.
///
/// The rule: a gap of missed days is covered by freezes, one freeze per
/// missed day, up to [freezeCapacity] currently available. A gap longer
/// than the available freezes gently starts a new chain at length 1 rather
/// than showing any "you lost your streak" message — freezes themselves are
/// never forfeited by a reset, only spent by actually covering a gap.
class StreakCalculator {
  StreakCalculator._();

  static const int freezeCapacity = 2;
  static const int daysPerFreezeRegen = 7;
  static const List<int> milestones = [3, 7, 14, 21, 28];

  /// Brings [previous] up to date as of local [today] without recording a
  /// new completion: consumes freezes for a fully-elapsed gap, or gently
  /// resets the chain if the gap exceeds available freezes. Idempotent —
  /// calling this repeatedly for the same [today] returns an unchanged
  /// state once caught up.
  static StreakState evaluate({required StreakState previous, required DateTime today}) {
    final lastKey = previous.lastCompletedDateKey;
    if (lastKey == null) return previous;

    final todayKey = LocalDay.keyFor(today);
    if (lastKey == todayKey) return previous;

    final gap = _gapDays(lastKey: lastKey, today: today);
    if (gap <= 0) return previous;

    if (gap <= previous.freezesAvailable) {
      return previous.copyWith(freezesAvailable: previous.freezesAvailable - gap);
    }
    return previous.copyWith(currentStreak: 0);
  }

  /// Records that today's challenge was just completed, first catching up
  /// via [evaluate]. Idempotent: calling this again for the same [today]
  /// (i.e. re-opening an already-completed day) returns [previous]
  /// unchanged with no milestone — completing a day never double-counts.
  static StreakUpdate recordCompletion({required StreakState previous, required DateTime today}) {
    final todayKey = LocalDay.keyFor(today);
    if (previous.lastCompletedDateKey == todayKey) {
      return StreakUpdate(state: previous, newMilestone: null);
    }

    final caughtUp = evaluate(previous: previous, today: today);
    final newStreak = caughtUp.currentStreak + 1;
    var freezes = caughtUp.freezesAvailable;
    if (newStreak % daysPerFreezeRegen == 0 && freezes < freezeCapacity) {
      freezes++;
    }

    final updated = caughtUp.copyWith(
      currentStreak: newStreak,
      bestStreak: newStreak > caughtUp.bestStreak ? newStreak : caughtUp.bestStreak,
      freezesAvailable: freezes,
      lastCompletedDateKey: todayKey,
    );

    final milestone = milestones.contains(newStreak) ? newStreak : null;
    return StreakUpdate(state: updated, newMilestone: milestone);
  }

  /// Renders the last [windowDays] local calendar days (ending at [today])
  /// as a [DayChainEntry] list, for a streak-chain view. Purely derived
  /// from [completedDateKeys] — no extra per-day storage is needed. This
  /// is a display-only approximation: it replays completions from the
  /// earliest relevant one to resolve each gap as covered-by-freeze or not,
  /// independently of the persisted [StreakState] (which remains the
  /// source of truth for gameplay).
  static List<DayChainEntry> buildChain({
    required Set<String> completedDateKeys,
    required DateTime today,
    int windowDays = 28,
  }) {
    final todayNorm = LocalDay.normalize(today);
    final windowStart = todayNorm.subtract(Duration(days: windowDays - 1));

    final sortedCompleted = completedDateKeys.map(LocalDay.parseKey).toList()..sort();
    final replayStart = sortedCompleted.isEmpty
        ? windowStart
        : (sortedCompleted.first.isBefore(windowStart) ? sortedCompleted.first : windowStart);

    final states = <String, DayChainState>{};
    var streak = const StreakState.initial();
    DateTime? lastCompleted;

    for (var day = replayStart; !day.isAfter(todayNorm); day = day.add(const Duration(days: 1))) {
      final key = LocalDay.keyFor(day);
      if (!completedDateKeys.contains(key)) continue;

      if (lastCompleted != null) {
        _markGap(states: states, from: lastCompleted, to: day, freezesAvailable: streak.freezesAvailable);
      }
      streak = recordCompletion(previous: streak, today: day).state;
      states[key] = DayChainState.completed;
      lastCompleted = day;
    }

    if (lastCompleted != null && lastCompleted != todayNorm) {
      _markGap(states: states, from: lastCompleted, to: todayNorm, freezesAvailable: streak.freezesAvailable);
    }
    // Today's own mark only applies if today wasn't itself a completed day
    // — otherwise this would overwrite a same-day completion's `completed`
    // mark with a plain `today` one.
    states.putIfAbsent(LocalDay.keyFor(todayNorm), () => DayChainState.today);

    final entries = <DayChainEntry>[];
    for (var day = windowStart; !day.isAfter(todayNorm); day = day.add(const Duration(days: 1))) {
      final key = LocalDay.keyFor(day);
      entries.add(DayChainEntry(dateKey: key, state: states[key] ?? DayChainState.none));
    }
    return entries;
  }

  static void _markGap({
    required Map<String, DayChainState> states,
    required DateTime from,
    required DateTime to,
    required int freezesAvailable,
  }) {
    final gapDays = to.difference(from).inDays - 1;
    if (gapDays <= 0) return;
    final covered = gapDays <= freezesAvailable;
    for (var g = 1; g <= gapDays; g++) {
      final missedDay = from.add(Duration(days: g));
      states[LocalDay.keyFor(missedDay)] = covered ? DayChainState.frozen : DayChainState.missed;
    }
  }

  static int _gapDays({required String lastKey, required DateTime today}) {
    final last = LocalDay.parseKey(lastKey);
    final daysSince = LocalDay.normalize(today).difference(last).inDays;
    return daysSince - 1;
  }
}
