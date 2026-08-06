import '../entities/daily_challenge.dart';

/// Pure, deterministic pick of "today's" challenge from the bundled pool.
///
/// The same [today] (local calendar date) always yields the same result —
/// stable across app restarts on the same day — while a different date
/// yields a different index into the (possibly filtered) candidate list, so
/// the challenge changes day to day.
class DailyChallengeSelector {
  DailyChallengeSelector._();

  static DailyChallenge selectFor({
    required List<DailyChallenge> pool,
    required DateTime today,
    required Set<String> preferredHazardIds,
    required Set<String> recentChallengeIds,
  }) {
    assert(pool.isNotEmpty, 'DailyChallengeSelector requires a non-empty pool.');

    var candidates = pool;

    // Prefer challenges reinforcing an already-completed hazard; fall back
    // to the full pool if the child hasn't completed enough hazards yet.
    final preferred = pool.where((c) => preferredHazardIds.contains(c.relatedHazardId)).toList();
    if (preferred.isNotEmpty) candidates = preferred;

    // Avoid repeating a recently-played challenge where possible.
    final fresh = candidates.where((c) => !recentChallengeIds.contains(c.id)).toList();
    if (fresh.isNotEmpty) candidates = fresh;

    // Deterministic order so the same candidate set always indexes the
    // same way, independent of the pool's original JSON ordering.
    final sorted = [...candidates]..sort((a, b) => a.id.compareTo(b.id));

    final seed = today.year * 10000 + today.month * 100 + today.day;
    return sorted[seed % sorted.length];
  }
}
