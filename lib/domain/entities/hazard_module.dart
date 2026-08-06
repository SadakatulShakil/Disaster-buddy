import 'package:equatable/equatable.dart';

import 'badge_info.dart';
import 'beat.dart';
import 'localized_text.dart';

/// The full static content for one hazard (earthquake, flood, lightning),
/// as loaded from its `assets/content/<id>.json` manifest.
final class HazardModule extends Equatable {
  const HazardModule({
    required this.id,
    required this.order,
    required this.title,
    required this.themeColorHex,
    required this.iconAsset,
    required this.safeAction,
    required this.badge,
    required this.beats,
  });

  /// Matches one of [AppConstants.initialHazards].
  final String id;

  /// Display order on the adventure map.
  final int order;
  final LocalizedText title;

  /// Hex colour string, e.g. `"#A0522D"`. Never hard-code hex in widgets —
  /// parse this instead.
  final String themeColorHex;

  /// Placeholder-safe asset filename; see `SafeAssetImage`.
  final String iconAsset;
  final LocalizedText safeAction;
  final BadgeInfo badge;

  /// Ordered story -> steps -> practice -> quiz beats.
  final List<Beat> beats;

  @override
  List<Object?> get props => [
        id,
        order,
        title,
        themeColorHex,
        iconAsset,
        safeAction,
        badge,
        beats,
      ];
}
