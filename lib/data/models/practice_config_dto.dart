import '../../domain/entities/practice_config.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';
import 'manifest_exception.dart';
import 'practice_item_dto.dart';

/// Parses the `config` object of a `practice` beat.
final class PracticeConfigDto {
  const PracticeConfigDto({required this.instructions, required this.items});

  factory PracticeConfigDto.fromJson(Map<String, dynamic> json, String context) {
    final itemsJson = requireList(json, 'items', context);
    if (itemsJson.isEmpty) {
      throw ManifestValidationException('"items" must not be empty in $context.');
    }
    return PracticeConfigDto(
      instructions: LocalizedTextDto.fromJson(
        requireObject(json, 'instructions', context),
        '$context.instructions',
      ),
      items: [
        for (var i = 0; i < itemsJson.length; i++)
          PracticeItemDto.fromJson(requireListItemObject(itemsJson[i], '$context.items[$i]'), '$context.items[$i]'),
      ],
    );
  }

  final LocalizedTextDto instructions;
  final List<PracticeItemDto> items;

  PracticeConfig toDomain() => PracticeConfig(
        instructions: instructions.toDomain(),
        items: [for (final item in items) item.toDomain()],
      );
}
