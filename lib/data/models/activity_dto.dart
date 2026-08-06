import '../../domain/entities/activity.dart';
import 'badge_info_dto.dart';
import 'json_helpers.dart';
import 'kit_item_dto.dart';
import 'localized_text_dto.dart';
import 'manifest_exception.dart';

/// Parses a whole `assets/content/activities/<id>.json` manifest into an
/// [Activity].
final class ActivityDto {
  const ActivityDto({
    required this.id,
    required this.title,
    required this.themeColorHex,
    required this.iconAsset,
    required this.instructions,
    required this.items,
    this.badge,
  });

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    const context = 'activity manifest';
    final itemsJson = requireList(json, 'items', context);
    if (itemsJson.isEmpty) {
      throw const ManifestValidationException('"items" must not be empty in activity manifest.');
    }
    final items = [
      for (var i = 0; i < itemsJson.length; i++)
        KitItemDto.fromJson(requireListItemObject(itemsJson[i], '$context.items[$i]'), '$context.items[$i]'),
    ];
    if (!items.any((item) => item.isCorrect)) {
      throw const ManifestValidationException('"items" must contain at least one correct item in activity manifest.');
    }

    final badgeJson = optionalObject(json, 'badge');
    return ActivityDto(
      id: requireString(json, 'id', context),
      title: LocalizedTextDto.fromJson(requireObject(json, 'title', context), '$context.title'),
      themeColorHex: requireString(json, 'themeColor', context),
      iconAsset: requireString(json, 'iconAsset', context),
      instructions: LocalizedTextDto.fromJson(requireObject(json, 'instructions', context), '$context.instructions'),
      items: items,
      badge: badgeJson != null ? BadgeInfoDto.fromJson(badgeJson) : null,
    );
  }

  final String id;
  final LocalizedTextDto title;
  final String themeColorHex;
  final String iconAsset;
  final LocalizedTextDto instructions;
  final List<KitItemDto> items;
  final BadgeInfoDto? badge;

  Activity toDomain() => Activity(
        id: id,
        title: title.toDomain(),
        themeColorHex: themeColorHex,
        iconAsset: iconAsset,
        instructions: instructions.toDomain(),
        items: [for (final item in items) item.toDomain()],
        badge: badge?.toDomain(),
      );
}
