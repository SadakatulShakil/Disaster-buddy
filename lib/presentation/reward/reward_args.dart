import '../../domain/entities/badge_info.dart';

/// Navigation arguments for [RewardPage], passed once a module is freshly
/// completed and its badge has just been awarded.
final class RewardArgs {
  const RewardArgs({required this.moduleId, required this.badge, required this.themeColorHex});

  final String moduleId;
  final BadgeInfo badge;

  /// Hex colour string; parse with `AppColors.fromHex`.
  final String themeColorHex;
}
