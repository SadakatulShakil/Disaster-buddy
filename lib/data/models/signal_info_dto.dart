import '../../domain/entities/signal_info.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses one entry of a Signal Colours manifest's `signals` array.
final class SignalInfoDto {
  const SignalInfoDto({
    required this.id,
    required this.colorHex,
    required this.meaning,
    required this.action,
    required this.actionIcon,
    this.affirmation,
  });

  factory SignalInfoDto.fromJson(Map<String, dynamic> json, String context) {
    final affirmationJson = optionalObject(json, 'affirmation');
    return SignalInfoDto(
      id: requireString(json, 'id', context),
      colorHex: requireString(json, 'colorHex', context),
      meaning: LocalizedTextDto.fromJson(requireObject(json, 'meaning', context), '$context.meaning'),
      action: LocalizedTextDto.fromJson(requireObject(json, 'action', context), '$context.action'),
      actionIcon: requireString(json, 'actionIcon', context),
      affirmation:
          affirmationJson != null ? LocalizedTextDto.fromJson(affirmationJson, '$context.affirmation') : null,
    );
  }

  final String id;
  final String colorHex;
  final LocalizedTextDto meaning;
  final LocalizedTextDto action;
  final String actionIcon;
  final LocalizedTextDto? affirmation;

  SignalInfo toDomain() => SignalInfo(
        id: id,
        colorHex: colorHex,
        meaning: meaning.toDomain(),
        action: action.toDomain(),
        actionIcon: actionIcon,
        affirmation: affirmation?.toDomain(),
      );
}
