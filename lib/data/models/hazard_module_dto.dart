import '../../domain/entities/hazard_module.dart';
import 'badge_info_dto.dart';
import 'beat_dto.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';
import 'manifest_exception.dart';

/// Parses a whole `assets/content/<id>.json` manifest into a [HazardModule].
final class HazardModuleDto {
  const HazardModuleDto({
    required this.id,
    required this.order,
    required this.title,
    required this.themeColorHex,
    required this.iconAsset,
    required this.safeAction,
    required this.badge,
    required this.beats,
  });

  factory HazardModuleDto.fromJson(Map<String, dynamic> json) {
    const context = 'manifest';
    final id = requireString(json, 'id', context);
    final beatsJson = requireList(json, 'beats', context);
    if (beatsJson.isEmpty) {
      throw const ManifestValidationException('"beats" must not be empty in manifest.');
    }
    final beats = [
      for (var i = 0; i < beatsJson.length; i++)
        BeatDto.fromJson(requireListItemObject(beatsJson[i], '$context.beats[$i]'), '$context.beats[$i]'),
    ];
    return HazardModuleDto(
      id: id,
      order: requireInt(json, 'order', context),
      title: LocalizedTextDto.fromJson(requireObject(json, 'title', context), '$context.title'),
      themeColorHex: requireString(json, 'themeColor', context),
      iconAsset: requireString(json, 'iconAsset', context),
      safeAction: LocalizedTextDto.fromJson(requireObject(json, 'safeAction', context), '$context.safeAction'),
      badge: BadgeInfoDto.fromJson(requireObject(json, 'badge', context)),
      beats: beats,
    );
  }

  final String id;
  final int order;
  final LocalizedTextDto title;
  final String themeColorHex;
  final String iconAsset;
  final LocalizedTextDto safeAction;
  final BadgeInfoDto badge;
  final List<BeatDto> beats;

  HazardModule toDomain() => HazardModule(
        id: id,
        order: order,
        title: title.toDomain(),
        themeColorHex: themeColorHex,
        iconAsset: iconAsset,
        safeAction: safeAction.toDomain(),
        badge: badge.toDomain(),
        beats: [for (final beat in beats) beat.toDomain()],
      );
}
