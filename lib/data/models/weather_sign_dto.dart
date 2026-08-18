import '../../domain/entities/weather_sign.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';
import 'manifest_exception.dart';
import 'weather_sign_option_dto.dart';

/// Parses one entry of a Read the Sky manifest's `signs` array.
final class WeatherSignDto {
  const WeatherSignDto({
    required this.id,
    required this.image,
    required this.description,
    required this.correctHazard,
    required this.options,
    required this.feedback,
    required this.action,
  });

  factory WeatherSignDto.fromJson(Map<String, dynamic> json, String context) {
    final optionsJson = requireList(json, 'options', context);
    if (optionsJson.isEmpty) {
      throw ManifestValidationException('"options" must not be empty in $context.');
    }
    final options = [
      for (var i = 0; i < optionsJson.length; i++)
        WeatherSignOptionDto.fromJson(
          requireListItemObject(optionsJson[i], '$context.options[$i]'),
          '$context.options[$i]',
        ),
    ];
    if (!options.any((option) => option.isCorrect)) {
      throw ManifestValidationException('"options" must contain exactly one correct option in $context.');
    }

    return WeatherSignDto(
      id: requireString(json, 'id', context),
      image: requireString(json, 'image', context),
      description: LocalizedTextDto.fromJson(requireObject(json, 'description', context), '$context.description'),
      correctHazard: LocalizedTextDto.fromJson(requireObject(json, 'correctHazard', context), '$context.correctHazard'),
      options: options,
      feedback: LocalizedTextDto.fromJson(requireObject(json, 'feedback', context), '$context.feedback'),
      action: LocalizedTextDto.fromJson(requireObject(json, 'action', context), '$context.action'),
    );
  }

  final String id;
  final String image;
  final LocalizedTextDto description;
  final LocalizedTextDto correctHazard;
  final List<WeatherSignOptionDto> options;
  final LocalizedTextDto feedback;
  final LocalizedTextDto action;

  WeatherSign toDomain() => WeatherSign(
        id: id,
        image: image,
        description: description.toDomain(),
        correctHazard: correctHazard.toDomain(),
        options: [for (final option in options) option.toDomain()],
        feedback: feedback.toDomain(),
        action: action.toDomain(),
      );
}
