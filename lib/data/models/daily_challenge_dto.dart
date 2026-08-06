import '../../domain/entities/daily_challenge.dart';
import 'json_helpers.dart';
import 'manifest_exception.dart';
import 'practice_config_dto.dart';
import 'quiz_question_dto.dart';

/// Parses one entry of `daily_challenges.json`'s `payload`, dispatching on
/// the challenge's `type`. Reuses [QuizQuestionDto] for `quiz`/
/// `whatWouldYouDo` and [PracticeConfigDto] for `spotTheDanger`/`kitRound` —
/// no new payload parsing logic, just the exact same shapes already used by
/// hazard-module manifests.
sealed class DailyChallengePayloadDto {
  const DailyChallengePayloadDto();

  DailyChallengePayload toDomain();
}

final class QuizChallengePayloadDto extends DailyChallengePayloadDto {
  const QuizChallengePayloadDto(this.question);

  final QuizQuestionDto question;

  @override
  DailyChallengePayload toDomain() => QuizChallengePayload(question.toDomain());
}

final class PracticeChallengePayloadDto extends DailyChallengePayloadDto {
  const PracticeChallengePayloadDto({required this.gameId, required this.config});

  final String gameId;
  final PracticeConfigDto config;

  @override
  DailyChallengePayload toDomain() => PracticeChallengePayload(gameId: gameId, config: config.toDomain());
}

/// Parses one entry of `daily_challenges.json`'s top-level `challenges`
/// array.
final class DailyChallengeDto {
  const DailyChallengeDto({
    required this.id,
    required this.type,
    required this.relatedHazardId,
    required this.difficulty,
    required this.payload,
  });

  factory DailyChallengeDto.fromJson(Map<String, dynamic> json, String context) {
    final id = requireString(json, 'id', context);
    final type = _typeFromJson(requireString(json, 'type', context), context);
    final relatedHazardId = requireString(json, 'relatedHazardId', context);
    final difficulty = optionalInt(json, 'difficulty') ?? 1;
    final payloadJson = requireObject(json, 'payload', context);
    final payloadContext = '$context.payload';

    final DailyChallengePayloadDto payload = switch (type) {
      DailyChallengeType.quiz || DailyChallengeType.whatWouldYouDo =>
        QuizChallengePayloadDto(QuizQuestionDto.fromJson(payloadJson, payloadContext)),
      DailyChallengeType.spotTheDanger || DailyChallengeType.kitRound => PracticeChallengePayloadDto(
          gameId: requireString(payloadJson, 'gameId', payloadContext),
          config: PracticeConfigDto.fromJson(payloadJson, payloadContext),
        ),
    };

    return DailyChallengeDto(
      id: id,
      type: type,
      relatedHazardId: relatedHazardId,
      difficulty: difficulty,
      payload: payload,
    );
  }

  static DailyChallengeType _typeFromJson(String value, String context) {
    for (final type in DailyChallengeType.values) {
      if (type.name == value) return type;
    }
    throw ManifestValidationException('Unknown daily challenge "type": "$value" in $context.');
  }

  final String id;
  final DailyChallengeType type;
  final String relatedHazardId;
  final int difficulty;
  final DailyChallengePayloadDto payload;

  DailyChallenge toDomain() => DailyChallenge(
        id: id,
        type: type,
        relatedHazardId: relatedHazardId,
        difficulty: difficulty,
        payload: payload.toDomain(),
      );
}

/// Parses the root object of `daily_challenges.json`.
final class DailyChallengePoolDto {
  const DailyChallengePoolDto(this.challenges);

  factory DailyChallengePoolDto.fromJson(Map<String, dynamic> json) {
    const context = 'daily_challenges';
    final challengesJson = requireList(json, 'challenges', context);
    if (challengesJson.isEmpty) {
      throw const ManifestValidationException('"challenges" must not be empty in daily_challenges.');
    }
    return DailyChallengePoolDto([
      for (var i = 0; i < challengesJson.length; i++)
        DailyChallengeDto.fromJson(
          requireListItemObject(challengesJson[i], '$context.challenges[$i]'),
          '$context.challenges[$i]',
        ),
    ]);
  }

  final List<DailyChallengeDto> challenges;

  List<DailyChallenge> toDomain() => [for (final challenge in challenges) challenge.toDomain()];
}
