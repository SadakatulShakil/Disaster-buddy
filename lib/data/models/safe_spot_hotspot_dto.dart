import '../../domain/entities/safe_spot_hotspot.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';
import 'normalized_rect_dto.dart';

/// Parses one entry of a Safe Spot Finder scene's `spots` array.
final class SafeSpotHotspotDto {
  const SafeSpotHotspotDto({
    required this.id,
    required this.rect,
    required this.isSafe,
    required this.label,
    required this.feedback,
  });

  factory SafeSpotHotspotDto.fromJson(Map<String, dynamic> json, String context) {
    return SafeSpotHotspotDto(
      id: requireString(json, 'id', context),
      rect: NormalizedRectDto.fromJson(requireObject(json, 'rect', context), '$context.rect'),
      isSafe: optionalBool(json, 'isSafe'),
      label: LocalizedTextDto.fromJson(requireObject(json, 'label', context), '$context.label'),
      feedback: LocalizedTextDto.fromJson(requireObject(json, 'feedback', context), '$context.feedback'),
    );
  }

  final String id;
  final NormalizedRectDto rect;
  final bool isSafe;
  final LocalizedTextDto label;
  final LocalizedTextDto feedback;

  SafeSpotHotspot toDomain() => SafeSpotHotspot(
        id: id,
        rect: rect.toDomain(),
        isSafe: isSafe,
        label: label.toDomain(),
        feedback: feedback.toDomain(),
      );
}
