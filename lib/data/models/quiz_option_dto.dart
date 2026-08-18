import '../../domain/entities/quiz_option.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses one entry of a quiz question's `options` array.
final class QuizOptionDto {
  const QuizOptionDto({
    required this.id,
    this.imageAsset,
    required this.label,
    required this.isCorrect,
    this.feedback,
  });

  factory QuizOptionDto.fromJson(Map<String, dynamic> json, String context) {
    final feedbackJson = optionalObject(json, 'feedback');
    return QuizOptionDto(
      id: requireString(json, 'id', context),
      imageAsset: optionalString(json, 'imageAsset'),
      label: LocalizedTextDto.fromJson(requireObject(json, 'label', context), '$context.label'),
      isCorrect: requireBool(json, 'isCorrect', context),
      feedback: feedbackJson != null ? LocalizedTextDto.fromJson(feedbackJson, '$context.feedback') : null,
    );
  }

  final String id;
  final String? imageAsset;
  final LocalizedTextDto label;
  final bool isCorrect;
  final LocalizedTextDto? feedback;

  QuizOption toDomain() => QuizOption(
        id: id,
        imageAsset: imageAsset,
        label: label.toDomain(),
        isCorrect: isCorrect,
        feedback: feedback?.toDomain(),
      );
}
