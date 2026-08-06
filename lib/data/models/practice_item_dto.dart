import '../../domain/entities/practice_item.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses one entry of a practice beat's `config.items` array.
final class PracticeItemDto {
  const PracticeItemDto({
    required this.id,
    required this.label,
    this.imageAsset,
    required this.isCorrect,
    this.sequenceOrder,
  });

  factory PracticeItemDto.fromJson(Map<String, dynamic> json, String context) {
    return PracticeItemDto(
      id: requireString(json, 'id', context),
      label: LocalizedTextDto.fromJson(requireObject(json, 'label', context), '$context.label'),
      imageAsset: optionalString(json, 'imageAsset'),
      isCorrect: optionalBool(json, 'isCorrect'),
      sequenceOrder: optionalInt(json, 'sequenceOrder'),
    );
  }

  final String id;
  final LocalizedTextDto label;
  final String? imageAsset;
  final bool isCorrect;
  final int? sequenceOrder;

  PracticeItem toDomain() => PracticeItem(
        id: id,
        label: label.toDomain(),
        imageAsset: imageAsset,
        isCorrect: isCorrect,
        sequenceOrder: sequenceOrder,
      );
}
