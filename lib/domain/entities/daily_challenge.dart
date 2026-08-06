import 'package:equatable/equatable.dart';

import 'practice_config.dart';
import 'quiz_question.dart';

/// The interaction style of one [DailyChallenge]. Every type renders through
/// an *existing* Phase 3 runner — no new interaction widgets:
///  - [quiz] / [whatWouldYouDo]: a single [QuizQuestion], played via
///    `QuizRunner` inside a synthetic single-question `QuizBeat`.
///  - [spotTheDanger] / [kitRound]: a [PracticeConfig] (tap every correct
///    option), played via a `PracticeGame` from `PracticeGameRegistry`.
enum DailyChallengeType { quiz, spotTheDanger, kitRound, whatWouldYouDo }

/// The type-specific content of a [DailyChallenge]. Sealed so a renderer can
/// switch on it exhaustively without a runtime type check.
sealed class DailyChallengePayload extends Equatable {
  const DailyChallengePayload();
}

/// A single question, reused as-is for [DailyChallengeType.quiz] and
/// [DailyChallengeType.whatWouldYouDo] — a "what would you do?" scenario is
/// structurally identical to a quiz question (a prompt plus 2-3 options).
final class QuizChallengePayload extends DailyChallengePayload {
  const QuizChallengePayload(this.question);

  final QuizQuestion question;

  @override
  List<Object?> get props => [question];
}

/// A tap-every-correct-option round, reused as-is for
/// [DailyChallengeType.spotTheDanger] (tappable danger spots) and
/// [DailyChallengeType.kitRound] (tap the items you'd pack) — both are the
/// same interaction over a themed [PracticeConfig] item set.
final class PracticeChallengePayload extends DailyChallengePayload {
  const PracticeChallengePayload({required this.gameId, required this.config});

  /// A `PracticeGameRegistry` id (e.g. `tap_correct_choice`).
  final String gameId;
  final PracticeConfig config;

  @override
  List<Object?> get props => [gameId, config];
}

/// One entry from the bundled daily-challenge pool
/// (`assets/content/daily/daily_challenges.json`). [GetTodaysChallenge]
/// deterministically picks one of these per local calendar day.
final class DailyChallenge extends Equatable {
  const DailyChallenge({
    required this.id,
    required this.type,
    required this.relatedHazardId,
    required this.difficulty,
    required this.payload,
  });

  final String id;
  final DailyChallengeType type;

  /// A hazard id (e.g. `earthquake`) this challenge reinforces — used to
  /// prefer challenges tied to hazards the child has already completed.
  final String relatedHazardId;
  final int difficulty;
  final DailyChallengePayload payload;

  @override
  List<Object?> get props => [id, type, relatedHazardId, difficulty, payload];
}
