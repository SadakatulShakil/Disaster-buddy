import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/activity.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/mascot_view.dart';
import '../../../widgets/placeholder_art.dart';

/// Celebratory summary shown once every scene's safe spots have been found:
/// the badge, if this was the first time earning it.
class SafeSpotCompleteSummary extends StatelessWidget {
  const SafeSpotCompleteSummary({
    super.key,
    required this.activity,
    required this.badgeAwarded,
    required this.themeColor,
  });

  final Activity activity;
  final bool badgeAwarded;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final badge = activity.badge;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MascotView(mood: MascotMood.cheer, size: 150),
          SizedBox(height: AppSpacing.md),
          Text('well_done'.tr, style: AppTextStyles.display, textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.sm),
          Text('safe_spot_complete_summary'.tr, style: AppTextStyles.body, textAlign: TextAlign.center),
          if (badgeAwarded && badge != null) ...[
            SizedBox(height: AppSpacing.xl),
            PlaceholderArt(
              assetPath: badge.iconAsset,
              themeColor: themeColor,
              fallbackIcon: Icons.emoji_events_rounded,
              size: 96.r,
              borderRadius: AppRadii.borderPill,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(badge.title.resolve(langCode), style: AppTextStyles.h2, textAlign: TextAlign.center),
          ],
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'back_to_activities'.tr,
            icon: Icons.arrow_back_rounded,
            color: themeColor,
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }
}
