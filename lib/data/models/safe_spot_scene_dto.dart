import '../../domain/entities/safe_spot_scene.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';
import 'manifest_exception.dart';
import 'safe_spot_hotspot_dto.dart';

/// Parses one entry of a Safe Spot Finder manifest's `scenes` array.
final class SafeSpotSceneDto {
  const SafeSpotSceneDto({
    required this.id,
    required this.sceneImage,
    required this.prompt,
    required this.spots,
  });

  factory SafeSpotSceneDto.fromJson(Map<String, dynamic> json, String context) {
    final spotsJson = requireList(json, 'spots', context);
    if (spotsJson.isEmpty) {
      throw ManifestValidationException('"spots" must not be empty in $context.');
    }
    final spots = [
      for (var i = 0; i < spotsJson.length; i++)
        SafeSpotHotspotDto.fromJson(requireListItemObject(spotsJson[i], '$context.spots[$i]'), '$context.spots[$i]'),
    ];
    if (!spots.any((spot) => spot.isSafe)) {
      throw ManifestValidationException('"spots" must contain at least one safe spot in $context.');
    }
    return SafeSpotSceneDto(
      id: requireString(json, 'id', context),
      sceneImage: requireString(json, 'sceneImage', context),
      prompt: LocalizedTextDto.fromJson(requireObject(json, 'prompt', context), '$context.prompt'),
      spots: spots,
    );
  }

  final String id;
  final String sceneImage;
  final LocalizedTextDto prompt;
  final List<SafeSpotHotspotDto> spots;

  SafeSpotScene toDomain() => SafeSpotScene(
        id: id,
        sceneImage: sceneImage,
        prompt: prompt.toDomain(),
        spots: [for (final spot in spots) spot.toDomain()],
      );
}
