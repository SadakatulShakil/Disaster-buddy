import '../../domain/entities/normalized_rect.dart';
import 'json_helpers.dart';

/// Parses a Safe Spot Finder hotspot's `rect` object: `{"x", "y", "w", "h"}`,
/// all normalized 0..1 fractions of the scene image.
final class NormalizedRectDto {
  const NormalizedRectDto({required this.x, required this.y, required this.width, required this.height});

  factory NormalizedRectDto.fromJson(Map<String, dynamic> json, String context) {
    return NormalizedRectDto(
      x: requireDouble(json, 'x', context),
      y: requireDouble(json, 'y', context),
      width: requireDouble(json, 'w', context),
      height: requireDouble(json, 'h', context),
    );
  }

  final double x;
  final double y;
  final double width;
  final double height;

  NormalizedRect toDomain() => NormalizedRect(x: x, y: y, width: width, height: height);
}
