import '../../domain/entities/weather_sign_option.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses one entry of a Read the Sky sign's `options` array.
final class WeatherSignOptionDto {
  const WeatherSignOptionDto({
    required this.id,
    required this.label,
    required this.isCorrect,
  });

  factory WeatherSignOptionDto.fromJson(Map<String, dynamic> json, String context) {
    return WeatherSignOptionDto(
      id: requireString(json, 'id', context),
      label: LocalizedTextDto.fromJson(requireObject(json, 'label', context), '$context.label'),
      isCorrect: requireBool(json, 'isCorrect', context),
    );
  }

  final String id;
  final LocalizedTextDto label;
  final bool isCorrect;

  WeatherSignOption toDomain() => WeatherSignOption(
        id: id,
        label: label.toDomain(),
        isCorrect: isCorrect,
      );
}
