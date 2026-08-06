import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/activity.dart';
import '../../widgets/app_card.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/placeholder_art.dart';

/// A tappable card for one implemented [Activity], showing its real
/// completion state.
///
/// Sized to match [ActivityGridConstants] exactly (icon size, title lines,
/// status-row height) so it lines up pixel-for-pixel with the "coming
/// soon" stub tiles in the same grid — and, being a fixed-height grid cell,
/// never overflows regardless of how long a title's translation is.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity, required this.isCompleted, required this.onTap});

  final Activity activity;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final themeColor = AppColors.fromHex(activity.themeColorHex);

    return Semantics(
      button: true,
      label: activity.title.resolve(langCode),
      child: AppCard(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlaceholderArt(
              assetPath: activity.iconAsset,
              themeColor: themeColor,
              fallbackIcon: Icons.backpack_rounded,
              size: ActivityGridConstants.iconSize,
              borderRadius: AppRadii.borderPill,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              activity.title.resolve(langCode),
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: ActivityGridConstants.statusRowHeight,
              child: Center(
                child: isCompleted
                    ? BadgeChip(label: 'module_completed'.tr, icon: Icons.check_circle, color: AppColors.success)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared sizing so [ActivityCard] and the "coming soon" stub tiles line up
/// exactly in the Activities grid — one source of truth instead of two
/// screens' worth of copy-pasted numbers.
class ActivityGridConstants {
  ActivityGridConstants._();

  static double get iconSize => 60.r;

  /// Always-reserved height for the status chip row, so a card without one
  /// (e.g. a not-yet-completed activity) is exactly as tall as one with it.
  static double get statusRowHeight => 28.r;

  /// Fixed grid-cell height covering icon + gaps + a full 2-line title +
  /// the status row + the card's own padding. Generously margined — a
  /// 2-line Bangla title needs more line-height than the equivalent
  /// English text, and the margin also absorbs a larger system font-scale
  /// setting.
  static double get cellHeight => 232.r;
}
