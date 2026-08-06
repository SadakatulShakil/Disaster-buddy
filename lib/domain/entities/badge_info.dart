import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// The sticker/badge a child earns for finishing a [HazardModule].
final class BadgeInfo extends Equatable {
  const BadgeInfo({
    required this.id,
    required this.title,
    required this.iconAsset,
  });

  final String id;
  final LocalizedText title;

  /// Placeholder-safe asset filename; see `SafeAssetImage`.
  final String iconAsset;

  @override
  List<Object?> get props => [id, title, iconAsset];
}
