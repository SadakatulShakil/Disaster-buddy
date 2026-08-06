import '../../domain/entities/badge_info.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses the `badge` object of a hazard manifest.
final class BadgeInfoDto {
  const BadgeInfoDto({
    required this.id,
    required this.title,
    required this.iconAsset,
  });

  factory BadgeInfoDto.fromJson(Map<String, dynamic> json) {
    const context = 'badge';
    return BadgeInfoDto(
      id: requireString(json, 'id', context),
      title: LocalizedTextDto.fromJson(requireObject(json, 'title', context), '$context.title'),
      iconAsset: requireString(json, 'iconAsset', context),
    );
  }

  final String id;
  final LocalizedTextDto title;
  final String iconAsset;

  BadgeInfo toDomain() => BadgeInfo(
        id: id,
        title: title.toDomain(),
        iconAsset: iconAsset,
      );
}
