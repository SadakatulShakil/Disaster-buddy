import '../../domain/entities/slide.dart';
import 'json_helpers.dart';
import 'localized_text_dto.dart';

/// Parses one entry of a `slides` array.
final class SlideDto {
  const SlideDto({required this.imageAsset, required this.text});

  factory SlideDto.fromJson(Map<String, dynamic> json, String context) {
    return SlideDto(
      imageAsset: requireString(json, 'imageAsset', context),
      text: LocalizedTextDto.fromJson(requireObject(json, 'text', context), '$context.text'),
    );
  }

  final String imageAsset;
  final LocalizedTextDto text;

  Slide toDomain() => Slide(imageAsset: imageAsset, text: text.toDomain());
}
