import '../../domain/entities/localized_text.dart';
import 'json_helpers.dart';

/// Parses the `{"bn": "...", "en": "..."}` shape used throughout manifests.
final class LocalizedTextDto {
  const LocalizedTextDto({required this.bn, required this.en});

  factory LocalizedTextDto.fromJson(Map<String, dynamic> json, String context) {
    return LocalizedTextDto(
      bn: requireString(json, 'bn', context),
      en: requireString(json, 'en', context),
    );
  }

  final String bn;
  final String en;

  LocalizedText toDomain() => LocalizedText(bn: bn, en: en);
}
