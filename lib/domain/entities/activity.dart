import 'package:equatable/equatable.dart';

import 'badge_info.dart';
import 'kit_item.dart';
import 'localized_text.dart';

/// The full static content for one cross-cutting activity (e.g. the
/// Emergency Kit Builder), loaded from `assets/content/activities/<id>.json`.
/// Module-independent: not tied to any single hazard, reachable from its own
/// Activities entry point rather than the Adventure Map's module chain.
final class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.title,
    required this.themeColorHex,
    required this.iconAsset,
    required this.instructions,
    required this.items,
    this.badge,
  });

  final String id;
  final LocalizedText title;

  /// Hex colour string, e.g. `"#F2896B"`. Never hard-code hex in widgets —
  /// parse this via `AppColors.fromHex`.
  final String themeColorHex;

  /// Placeholder-safe asset filename; see `PlaceholderArt`.
  final String iconAsset;
  final LocalizedText instructions;
  final List<KitItem> items;

  /// Not every activity awards a badge.
  final BadgeInfo? badge;

  @override
  List<Object?> get props => [id, title, themeColorHex, iconAsset, instructions, items, badge];
}
