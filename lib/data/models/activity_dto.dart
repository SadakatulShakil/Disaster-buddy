import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_type.dart';
import 'activity_content_dto.dart';
import 'badge_info_dto.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses a whole `assets/content/activities/<id>.json` manifest into an
/// [Activity]. Common fields are read here; the `type`-specific payload is
/// delegated to [ActivityContentDto].
final class ActivityDto {
  const ActivityDto({
    required this.id,
    required this.title,
    required this.themeColorHex,
    required this.iconAsset,
    required this.instructions,
    required this.content,
    this.badge,
  });

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    const context = 'activity manifest';
    final type = requireString(json, 'type', context);
    final badgeJson = optionalObject(json, 'badge');
    return ActivityDto(
      id: requireString(json, 'id', context),
      title: LocalizedTextDto.fromJson(requireObject(json, 'title', context), '$context.title'),
      themeColorHex: requireString(json, 'themeColor', context),
      iconAsset: requireString(json, 'iconAsset', context),
      instructions: LocalizedTextDto.fromJson(requireObject(json, 'instructions', context), '$context.instructions'),
      content: ActivityContentDto.fromJson(json, type, context),
      badge: badgeJson != null ? BadgeInfoDto.fromJson(badgeJson) : null,
    );
  }

  final String id;
  final LocalizedTextDto title;
  final String themeColorHex;
  final String iconAsset;
  final LocalizedTextDto instructions;
  final ActivityContentDto content;
  final BadgeInfoDto? badge;

  Activity toDomain() => Activity(
        id: id,
        type: _typeOf(content),
        title: title.toDomain(),
        themeColorHex: themeColorHex,
        iconAsset: iconAsset,
        instructions: instructions.toDomain(),
        content: content.toDomain(),
        badge: badge?.toDomain(),
      );

  /// Derived from the concrete [ActivityContentDto] subtype rather than
  /// re-reading the raw `type` string, so [ActivityContentDto.fromJson]'s
  /// switch stays the single source of truth for which types are valid.
  static ActivityType _typeOf(ActivityContentDto content) => switch (content) {
        KitBuilderContentDto() => ActivityType.kitBuilder,
        SignalColoursContentDto() => ActivityType.signalColours,
        SafeSpotContentDto() => ActivityType.safeSpotFinder,
      };
}
