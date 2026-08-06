import '../../domain/entities/beat.dart';
import 'json_helpers.dart';
import 'manifest_exception.dart';
import 'practice_config_dto.dart';
import 'quiz_question_dto.dart';
import 'slide_dto.dart';

/// Parses one entry of a hazard manifest's `beats` array, dispatching on its
/// `type` field to the matching [Beat] subtype.
sealed class BeatDto {
  const BeatDto({required this.id, required this.order});

  final String id;
  final int order;

  static BeatDto fromJson(Map<String, dynamic> json, String context) {
    final type = requireString(json, 'type', context);
    final id = requireString(json, 'id', context);
    final order = requireInt(json, 'order', context);
    switch (type) {
      case 'story':
        return StoryBeatDto(id: id, order: order, slides: _slides(json, context));
      case 'steps':
        return StepsBeatDto(id: id, order: order, slides: _slides(json, context));
      case 'practice':
        return PracticeBeatDto(
          id: id,
          order: order,
          gameId: requireString(json, 'gameId', context),
          config: PracticeConfigDto.fromJson(requireObject(json, 'config', context), '$context.config'),
        );
      case 'quiz':
        return QuizBeatDto(id: id, order: order, questions: _questions(json, context));
      default:
        throw ManifestValidationException('Unknown beat "type": "$type" in $context.');
    }
  }

  static List<SlideDto> _slides(Map<String, dynamic> json, String context) {
    final slidesJson = requireList(json, 'slides', context);
    if (slidesJson.isEmpty) {
      throw ManifestValidationException('"slides" must not be empty in $context.');
    }
    return [
      for (var i = 0; i < slidesJson.length; i++)
        SlideDto.fromJson(requireListItemObject(slidesJson[i], '$context.slides[$i]'), '$context.slides[$i]'),
    ];
  }

  static List<QuizQuestionDto> _questions(Map<String, dynamic> json, String context) {
    final questionsJson = requireList(json, 'questions', context);
    if (questionsJson.isEmpty) {
      throw ManifestValidationException('"questions" must not be empty in $context.');
    }
    return [
      for (var i = 0; i < questionsJson.length; i++)
        QuizQuestionDto.fromJson(
          requireListItemObject(questionsJson[i], '$context.questions[$i]'),
          '$context.questions[$i]',
        ),
    ];
  }

  Beat toDomain();
}

final class StoryBeatDto extends BeatDto {
  const StoryBeatDto({required super.id, required super.order, required this.slides});

  final List<SlideDto> slides;

  @override
  Beat toDomain() => StoryBeat(id: id, order: order, slides: [for (final s in slides) s.toDomain()]);
}

final class StepsBeatDto extends BeatDto {
  const StepsBeatDto({required super.id, required super.order, required this.slides});

  final List<SlideDto> slides;

  @override
  Beat toDomain() => StepsBeat(id: id, order: order, slides: [for (final s in slides) s.toDomain()]);
}

final class PracticeBeatDto extends BeatDto {
  const PracticeBeatDto({
    required super.id,
    required super.order,
    required this.gameId,
    required this.config,
  });

  final String gameId;
  final PracticeConfigDto config;

  @override
  Beat toDomain() => PracticeBeat(id: id, order: order, gameId: gameId, config: config.toDomain());
}

final class QuizBeatDto extends BeatDto {
  const QuizBeatDto({required super.id, required super.order, required this.questions});

  final List<QuizQuestionDto> questions;

  @override
  Beat toDomain() => QuizBeat(id: id, order: order, questions: [for (final q in questions) q.toDomain()]);
}
