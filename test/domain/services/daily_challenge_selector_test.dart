// Phase E1: today's challenge must be stable across restarts on the same
// day, change on a different day, prefer a hazard the child has already
// completed, and gracefully fall back to the full pool otherwise.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/quiz_option.dart';
import 'package:bipod_bondhu/domain/entities/quiz_question.dart';
import 'package:bipod_bondhu/domain/services/daily_challenge_selector.dart';

const _text = LocalizedText(bn: 'x', en: 'x');

DailyChallenge _challenge(String id, String hazardId) => DailyChallenge(
      id: id,
      type: DailyChallengeType.quiz,
      relatedHazardId: hazardId,
      difficulty: 1,
      payload: QuizChallengePayload(
        QuizQuestion(
          id: '${id}_q',
          prompt: _text,
          options: const [
            QuizOption(id: 'a', label: _text, isCorrect: true),
            QuizOption(id: 'b', label: _text, isCorrect: false),
          ],
        ),
      ),
    );

void main() {
  final pool = [
    _challenge('c1', 'earthquake'),
    _challenge('c2', 'flood'),
    _challenge('c3', 'lightning'),
    _challenge('c4', 'first_aid'),
    _challenge('c5', 'earthquake'),
    _challenge('c6', 'flood'),
  ];

  test('is stable across repeated calls for the same day', () {
    final a = DailyChallengeSelector.selectFor(
      pool: pool,
      today: DateTime(2026, 8, 3),
      preferredHazardIds: const {},
      recentChallengeIds: const {},
    );
    final b = DailyChallengeSelector.selectFor(
      pool: pool,
      today: DateTime(2026, 8, 3),
      preferredHazardIds: const {},
      recentChallengeIds: const {},
    );
    expect(a.id, b.id);
  });

  test('changes across consecutive days within the same month', () {
    final seen = <String>{};
    for (var day = 1; day <= 6; day++) {
      final picked = DailyChallengeSelector.selectFor(
        pool: pool,
        today: DateTime(2026, 8, day),
        preferredHazardIds: const {},
        recentChallengeIds: const {},
      );
      seen.add(picked.id);
    }
    // 6 consecutive days over a 6-item pool with no preference/recency
    // filtering: consecutive integer seeds mod a pool size > 1 always
    // differ day to day, so every day in this span picks a distinct item.
    expect(seen.length, 6);
  });

  test('prefers a challenge tied to an already-completed hazard', () {
    final picked = DailyChallengeSelector.selectFor(
      pool: pool,
      today: DateTime(2026, 8, 3),
      preferredHazardIds: const {'lightning'},
      recentChallengeIds: const {},
    );
    // Only one pool entry is tied to "lightning" — preference narrows the
    // candidate set to exactly that one, regardless of the date seed.
    expect(picked.id, 'c3');
  });

  test('falls back to the full pool when no hazard is completed yet', () {
    final picked = DailyChallengeSelector.selectFor(
      pool: pool,
      today: DateTime(2026, 8, 3),
      preferredHazardIds: const {},
      recentChallengeIds: const {},
    );
    expect(pool.map((c) => c.id), contains(picked.id));
  });

  test('avoids a recently-played challenge when an alternative exists', () {
    final picked = DailyChallengeSelector.selectFor(
      pool: [_challenge('c1', 'earthquake'), _challenge('c2', 'earthquake')],
      today: DateTime(2026, 8, 3),
      preferredHazardIds: const {'earthquake'},
      recentChallengeIds: const {'c1'},
    );
    expect(picked.id, 'c2');
  });

  test('still returns a challenge when every candidate was recently played', () {
    final picked = DailyChallengeSelector.selectFor(
      pool: pool,
      today: DateTime(2026, 8, 3),
      preferredHazardIds: const {},
      recentChallengeIds: {'c1', 'c2', 'c3', 'c4', 'c5', 'c6'},
    );
    expect(pool.map((c) => c.id), contains(picked.id));
  });
}
