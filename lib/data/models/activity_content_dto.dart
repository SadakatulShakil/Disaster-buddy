import '../../domain/entities/activity_content.dart';
import 'json_helpers.dart';
import 'kit_item_dto.dart';
import 'manifest_exception.dart';
import 'safe_spot_scene_dto.dart';
import 'signal_info_dto.dart';
import 'weather_sign_dto.dart';

/// Parses the type-specific fields of an activity manifest, dispatching on
/// its top-level `type` field to the matching [ActivityContent] subtype.
/// Mirrors how `BeatDto` dispatches on a beat's `type`.
sealed class ActivityContentDto {
  const ActivityContentDto();

  static ActivityContentDto fromJson(Map<String, dynamic> json, String type, String context) {
    switch (type) {
      case 'kit_builder':
        return KitBuilderContentDto(items: _kitItems(json, context));
      case 'signal_colours':
        return SignalColoursContentDto(signals: _signals(json, context));
      case 'safe_spot_finder':
        return SafeSpotContentDto(scenes: _scenes(json, context));
      case 'read_the_sky':
        return ReadTheSkyContentDto(signs: _signs(json, context));
      default:
        throw ManifestValidationException('Unknown activity "type": "$type" in $context.');
    }
  }

  static List<KitItemDto> _kitItems(Map<String, dynamic> json, String context) {
    final itemsJson = requireList(json, 'items', context);
    if (itemsJson.isEmpty) {
      throw ManifestValidationException('"items" must not be empty in $context.');
    }
    final items = [
      for (var i = 0; i < itemsJson.length; i++)
        KitItemDto.fromJson(requireListItemObject(itemsJson[i], '$context.items[$i]'), '$context.items[$i]'),
    ];
    if (!items.any((item) => item.isCorrect)) {
      throw ManifestValidationException('"items" must contain at least one correct item in $context.');
    }
    return items;
  }

  static List<SignalInfoDto> _signals(Map<String, dynamic> json, String context) {
    final signalsJson = requireList(json, 'signals', context);
    if (signalsJson.isEmpty) {
      throw ManifestValidationException('"signals" must not be empty in $context.');
    }
    return [
      for (var i = 0; i < signalsJson.length; i++)
        SignalInfoDto.fromJson(requireListItemObject(signalsJson[i], '$context.signals[$i]'), '$context.signals[$i]'),
    ];
  }

  static List<SafeSpotSceneDto> _scenes(Map<String, dynamic> json, String context) {
    final scenesJson = requireList(json, 'scenes', context);
    if (scenesJson.isEmpty) {
      throw ManifestValidationException('"scenes" must not be empty in $context.');
    }
    return [
      for (var i = 0; i < scenesJson.length; i++)
        SafeSpotSceneDto.fromJson(requireListItemObject(scenesJson[i], '$context.scenes[$i]'), '$context.scenes[$i]'),
    ];
  }

  static List<WeatherSignDto> _signs(Map<String, dynamic> json, String context) {
    final signsJson = requireList(json, 'signs', context);
    if (signsJson.isEmpty) {
      throw ManifestValidationException('"signs" must not be empty in $context.');
    }
    return [
      for (var i = 0; i < signsJson.length; i++)
        WeatherSignDto.fromJson(requireListItemObject(signsJson[i], '$context.signs[$i]'), '$context.signs[$i]'),
    ];
  }

  ActivityContent toDomain();
}

final class KitBuilderContentDto extends ActivityContentDto {
  const KitBuilderContentDto({required this.items});

  final List<KitItemDto> items;

  @override
  ActivityContent toDomain() => KitBuilderContent(items: [for (final item in items) item.toDomain()]);
}

final class SignalColoursContentDto extends ActivityContentDto {
  const SignalColoursContentDto({required this.signals});

  final List<SignalInfoDto> signals;

  @override
  ActivityContent toDomain() => SignalColoursContent(signals: [for (final signal in signals) signal.toDomain()]);
}

final class SafeSpotContentDto extends ActivityContentDto {
  const SafeSpotContentDto({required this.scenes});

  final List<SafeSpotSceneDto> scenes;

  @override
  ActivityContent toDomain() => SafeSpotContent(scenes: [for (final scene in scenes) scene.toDomain()]);
}

final class ReadTheSkyContentDto extends ActivityContentDto {
  const ReadTheSkyContentDto({required this.signs});

  final List<WeatherSignDto> signs;

  @override
  ActivityContent toDomain() => ReadTheSkyContent(signs: [for (final sign in signs) sign.toDomain()]);
}
