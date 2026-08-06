// Phase E1: the "chain with grace" streak must never punish a missed day
// outright — a single gap is covered by a freeze when one is available,
// and only a gap beyond available freezes gently starts a new chain. All
// dates are injected explicitly so this suite is fully deterministic.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/domain/entities/streak_state.dart';
import 'package:bipod_bondhu/domain/services/streak_calculator.dart';

void main() {
  group('StreakCalculator.recordCompletion', () {
    test('first ever completion starts a streak of 1', () {
      final update = StreakCalculator.recordCompletion(
        previous: const StreakState.initial(),
        today: DateTime(2026, 8, 3),
      );

      expect(update.state.currentStreak, 1);
      expect(update.state.bestStreak, 1);
      expect(update.state.lastCompletedDateKey, '2026-08-03');
      expect(update.newMilestone, isNull);
    });

    test('completing the next consecutive day extends the streak', () {
      const previous = StreakState(currentStreak: 3, bestStreak: 3, freezesAvailable: 2, lastCompletedDateKey: '2026-08-02');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3));

      expect(update.state.currentStreak, 4);
      expect(update.state.bestStreak, 4);
      expect(update.state.freezesAvailable, 2);
    });

    test('re-opening an already-completed day does not double count', () {
      const previous = StreakState(currentStreak: 4, bestStreak: 4, freezesAvailable: 2, lastCompletedDateKey: '2026-08-03');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3));

      expect(update.state, previous);
      expect(update.newMilestone, isNull);
    });

    test('calling recordCompletion twice for the same day is fully idempotent', () {
      const initial = StreakState.initial();
      final first = StreakCalculator.recordCompletion(previous: initial, today: DateTime(2026, 8, 3));
      final second = StreakCalculator.recordCompletion(previous: first.state, today: DateTime(2026, 8, 3));

      expect(second.state, first.state);
      expect(second.newMilestone, isNull);
    });

    test('a single missed day is covered by a freeze, preserving the streak', () {
      // Last completed 2026-08-01; today is 2026-08-03 -> 2026-08-02 was missed.
      const previous = StreakState(currentStreak: 5, bestStreak: 5, freezesAvailable: 2, lastCompletedDateKey: '2026-08-01');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3));

      // The gap (1 day) consumes 1 freeze, then today's completion extends
      // the preserved streak by 1.
      expect(update.state.currentStreak, 6);
      expect(update.state.freezesAvailable, 1);
    });

    test('a miss with no freeze available gently resets to a fresh chain of 1', () {
      const previous = StreakState(currentStreak: 5, bestStreak: 8, freezesAvailable: 0, lastCompletedDateKey: '2026-08-01');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3));

      expect(update.state.currentStreak, 1);
      // Best streak is never erased by a reset.
      expect(update.state.bestStreak, 8);
      // Freezes are a separate resource — never forfeited by a reset.
      expect(update.state.freezesAvailable, 0);
    });

    test('a multi-day gap beyond available freezes resets the chain', () {
      // Gap of 4 missed days, only 2 freezes available.
      const previous = StreakState(currentStreak: 10, bestStreak: 10, freezesAvailable: 2, lastCompletedDateKey: '2026-08-01');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 6));

      expect(update.state.currentStreak, 1);
      expect(update.state.freezesAvailable, 2);
    });

    test('a multi-day gap exactly covered by available freezes preserves the chain', () {
      // Gap of 2 missed days, exactly 2 freezes available.
      const previous = StreakState(currentStreak: 10, bestStreak: 10, freezesAvailable: 2, lastCompletedDateKey: '2026-08-01');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 4));

      expect(update.state.currentStreak, 11);
      expect(update.state.freezesAvailable, 0);
    });

    test('freezes regenerate by 1 (capped) every 7-day streak milestone', () {
      const previous = StreakState(currentStreak: 6, bestStreak: 6, freezesAvailable: 0, lastCompletedDateKey: '2026-08-06');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 7));

      expect(update.state.currentStreak, 7);
      expect(update.state.freezesAvailable, 1);
      expect(update.newMilestone, 7);
    });

    test('freeze regeneration never exceeds freezeCapacity', () {
      const previous = StreakState(currentStreak: 6, bestStreak: 6, freezesAvailable: 2, lastCompletedDateKey: '2026-08-06');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 7));

      expect(update.state.freezesAvailable, StreakCalculator.freezeCapacity);
    });

    test('reports a milestone at 3 days', () {
      const previous = StreakState(currentStreak: 2, bestStreak: 2, freezesAvailable: 2, lastCompletedDateKey: '2026-08-02');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3));

      expect(update.newMilestone, 3);
    });

    test('reports no milestone on a non-milestone day', () {
      const previous = StreakState(currentStreak: 3, bestStreak: 3, freezesAvailable: 2, lastCompletedDateKey: '2026-08-02');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3));

      expect(update.newMilestone, isNull);
    });

    test('a local-midnight rollover a few minutes apart is still a new calendar day', () {
      const previous = StreakState(currentStreak: 1, bestStreak: 1, freezesAvailable: 2, lastCompletedDateKey: '2026-08-02');

      // 2026-08-02 23:59 -> 2026-08-03 00:01: less than 2 minutes apart in
      // wall-clock time, but a different local calendar day.
      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3, 0, 1));

      expect(update.state.currentStreak, 2);
      expect(update.state.lastCompletedDateKey, '2026-08-03');
    });

    test('a same calendar day many hours apart is not a new day', () {
      const previous = StreakState(currentStreak: 1, bestStreak: 1, freezesAvailable: 2, lastCompletedDateKey: '2026-08-03');

      final update = StreakCalculator.recordCompletion(previous: previous, today: DateTime(2026, 8, 3, 23, 58));

      expect(update.state, previous);
    });
  });

  group('StreakCalculator.evaluate', () {
    test('never-completed state is returned unchanged', () {
      final result = StreakCalculator.evaluate(previous: const StreakState.initial(), today: DateTime(2026, 8, 3));
      expect(result, const StreakState.initial());
    });

    test('yesterday completed, today not yet done -> not a miss', () {
      const previous = StreakState(currentStreak: 4, bestStreak: 4, freezesAvailable: 2, lastCompletedDateKey: '2026-08-02');
      final result = StreakCalculator.evaluate(previous: previous, today: DateTime(2026, 8, 3));
      expect(result, previous);
    });

    test('a gap covered by freezes is consumed without completing today', () {
      const previous = StreakState(currentStreak: 4, bestStreak: 4, freezesAvailable: 2, lastCompletedDateKey: '2026-08-01');
      final result = StreakCalculator.evaluate(previous: previous, today: DateTime(2026, 8, 3));
      expect(result.currentStreak, 4);
      expect(result.freezesAvailable, 1);
    });

    test('a gap beyond freezes gently resets ahead of any new completion', () {
      const previous = StreakState(currentStreak: 4, bestStreak: 9, freezesAvailable: 0, lastCompletedDateKey: '2026-08-01');
      final result = StreakCalculator.evaluate(previous: previous, today: DateTime(2026, 8, 3));
      expect(result.currentStreak, 0);
      expect(result.bestStreak, 9);
    });
  });

  group('StreakCalculator.buildChain', () {
    test('renders a completed day, a frozen gap day, and today correctly', () {
      final chain = StreakCalculator.buildChain(
        completedDateKeys: {'2026-08-01', '2026-08-03'},
        today: DateTime(2026, 8, 3),
        windowDays: 5,
      );

      final byKey = {for (final entry in chain) entry.dateKey: entry.state};
      expect(byKey['2026-08-01'], DayChainState.completed);
      expect(byKey['2026-08-02'], DayChainState.frozen);
      expect(byKey['2026-08-03'], DayChainState.completed);
    });

    test('days before any activity render as none, not missed', () {
      final chain = StreakCalculator.buildChain(
        completedDateKeys: {'2026-08-03'},
        today: DateTime(2026, 8, 3),
        windowDays: 5,
      );

      final byKey = {for (final entry in chain) entry.dateKey: entry.state};
      expect(byKey['2026-07-30'], DayChainState.none);
      expect(byKey['2026-08-03'], DayChainState.completed);
    });

    test('a gap beyond freeze capacity renders as missed, not frozen', () {
      final chain = StreakCalculator.buildChain(
        completedDateKeys: {'2026-08-01', '2026-08-06'},
        today: DateTime(2026, 8, 6),
        windowDays: 10,
      );

      final byKey = {for (final entry in chain) entry.dateKey: entry.state};
      expect(byKey['2026-08-03'], DayChainState.missed);
      expect(byKey['2026-08-06'], DayChainState.completed);
    });

    test('today with no completion yet renders as today, not missed', () {
      final chain = StreakCalculator.buildChain(
        completedDateKeys: {'2026-08-02'},
        today: DateTime(2026, 8, 3),
        windowDays: 5,
      );

      final byKey = {for (final entry in chain) entry.dateKey: entry.state};
      expect(byKey['2026-08-03'], DayChainState.today);
    });
  });
}
