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
  });

  factory QuizOptionDto.fromJson(Map<String, dynamic> json, String context) {
    return QuizOptionDto(
      id: requireString(json, 'id', context),
      imageAsset: optionalString(json, 'imageAsset'),
      label: LocalizedTextDto.fromJson(requireObject(json, 'label', context), '$context.label'),
      isCorrect: requireBool(json, 'isCorrect', context),
    );
  }

  final String id;
  final String? imageAsset;
  final LocalizedTextDto label;
  final bool isCorrect;

  QuizOption toDomain() => QuizOption(
        id: id,
        imageAsset: imageAsset,
        label: label.toDomain(),
        isCorrect: isCorrect,
      );
}
