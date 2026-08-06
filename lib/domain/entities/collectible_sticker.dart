import 'package:equatable/equatable.dart';

import 'badge_info.dart';
import 'localized_text.dart';

/// Where a [CollectibleSticker] comes from — determines how the tray
/// composes a locked hint ("Complete Flood to earn this!" vs "Reach a
/// 7-day streak to earn this!").
enum CollectibleSourceKind { module, activity, streak }

/// One entry in a child's full sticker collection — every badge the app can
/// award, whether earned yet or not. Unearned entries are shown as an
/// aspirational, never-sad locked placeholder in the collection tray.
final class CollectibleSticker extends Equatable {
  const CollectibleSticker({
    required this.badge,
    required this.earned,
    required this.sourceKind,
    required this.sourceLabel,
    this.streakLength,
  });

  final BadgeInfo badge;
  final bool earned;
  final CollectibleSourceKind sourceKind;

  /// The module/activity title this sticker comes from. Unused (but always
  /// present) when [sourceKind] is [CollectibleSourceKind.streak].
  final LocalizedText sourceLabel;

  /// The streak length (in days) this sticker celebrates. Only set when
  /// [sourceKind] is [CollectibleSourceKind.streak].
  final int? streakLength;

  @override
  List<Object?> get props => [badge, earned, sourceKind, sourceLabel, streakLength];
}
