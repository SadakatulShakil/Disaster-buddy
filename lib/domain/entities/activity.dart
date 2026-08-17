import 'package:equatable/equatable.dart';

import 'activity_content.dart';
import 'activity_type.dart';
import 'badge_info.dart';
import 'localized_text.dart';

/// The full static content for one cross-cutting activity (e.g. the
/// Emergency Kit Builder), loaded from `assets/content/activities/<id>.json`.
/// Module-independent: not tied to any single hazard, reachable from its own
/// Activities entry point rather than the Adventure Map's module chain.
///
/// [type] discriminates which [ActivityContent] subtype [content] carries —
/// every activity page casts it to the one shape it knows how to play.
final class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.type,
    required this.title,
    required this.themeColorHex,
    required this.iconAsset,
    required this.instructions,
    required this.content,
    this.badge,
  });

  final String id;
  final ActivityType type;
  final LocalizedText title;

  /// Hex colour string, e.g. `"#F2896B"`. Never hard-code hex in widgets —
  /// parse this via `AppColors.fromHex`.
  final String themeColorHex;

  /// Placeholder-safe asset filename; see `PlaceholderArt`.
  final String iconAsset;
  final LocalizedText instructions;
  final ActivityContent content;

  /// Not every activity awards a badge.
  final BadgeInfo? badge;

  @override
  List<Object?> get props => [id, type, title, themeColorHex, iconAsset, instructions, content, badge];
}
