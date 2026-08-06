import '../../domain/entities/quiz_question.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';
import 'manifest_exception.dart';
import 'quiz_option_dto.dart';

/// Parses one entry of a [QuizBeat]'s `questions` array.
final class QuizQuestionDto {
  const QuizQuestionDto({
    required this.id,
    required this.prompt,
    this.imageAsset,
    required this.options,
  });

  factory QuizQuestionDto.fromJson(Map<String, dynamic> json, String context) {
    final optionsJson = requireList(json, 'options', context);
    if (optionsJson.isEmpty) {
      throw ManifestValidationException('"options" must not be empty in $context.');
    }
    final options = <QuizOptionDto>[
      for (var i = 0; i < optionsJson.length; i++)
        QuizOptionDto.fromJson(
          requireListItemObject(optionsJson[i], '$context.options[$i]'),
          '$context.options[$i]',
        ),
    ];
    if (!options.any((o) => o.isCorrect)) {
      throw ManifestValidationException('"options" must contain at least one correct answer in $context.');
    }
    return QuizQuestionDto(
      id: requireString(json, 'id', context),
      prompt: LocalizedTextDto.fromJson(requireObject(json, 'prompt', context), '$context.prompt'),
      imageAsset: optionalString(json, 'imageAsset'),
      options: options,
    );
  }

  final String id;
  final LocalizedTextDto prompt;
  final String? imageAsset;
  final List<QuizOptionDto> options;

  QuizQuestion toDomain() => QuizQuestion(
        id: id,
        prompt: prompt.toDomain(),
        imageAsset: imageAsset,
        options: [for (final option in options) option.toDomain()],
      );
}
