import '../../domain/entities/kit_item.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses one entry of an activity manifest's `items` array.
final class KitItemDto {
  const KitItemDto({
    required this.id,
    required this.label,
    required this.imageAsset,
    required this.isCorrect,
    this.affirmation,
    this.feedback,
  });

  factory KitItemDto.fromJson(Map<String, dynamic> json, String context) {
    final affirmationJson = optionalObject(json, 'affirmation');
    final feedbackJson = optionalObject(json, 'feedback');
    return KitItemDto(
      id: requireString(json, 'id', context),
      label: LocalizedTextDto.fromJson(requireObject(json, 'label', context), '$context.label'),
      imageAsset: requireString(json, 'imageAsset', context),
      isCorrect: optionalBool(json, 'isCorrect'),
      affirmation:
          affirmationJson != null ? LocalizedTextDto.fromJson(affirmationJson, '$context.affirmation') : null,
      feedback: feedbackJson != null ? LocalizedTextDto.fromJson(feedbackJson, '$context.feedback') : null,
    );
  }

  final String id;
  final LocalizedTextDto label;
  final String imageAsset;
  final bool isCorrect;
  final LocalizedTextDto? affirmation;
  final LocalizedTextDto? feedback;

  KitItem toDomain() => KitItem(
        id: id,
        label: label.toDomain(),
        imageAsset: imageAsset,
        isCorrect: isCorrect,
        affirmation: affirmation?.toDomain(),
        feedback: feedback?.toDomain(),
      );
}
