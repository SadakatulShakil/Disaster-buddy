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

/// Celebratory summary shown once every correct item is packed: the full
/// kit, and the badge if this was the first time earning it.
class KitCompleteSummary extends StatelessWidget {
  const KitCompleteSummary({
    super.key,
    required this.activity,
    required this.packedItemIds,
    required this.badgeAwarded,
    required this.themeColor,
  });

  final Activity activity;
  final Set<String> packedItemIds;
  final bool badgeAwarded;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final packed = activity.items.where((item) => packedItemIds.contains(item.id)).toList();
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
          Text('kit_complete_summary'.tr, style: AppTextStyles.body, textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in packed)
                PlaceholderArt(
                  assetPath: item.imageAsset,
                  themeColor: themeColor,
                  fallbackIcon: Icons.check_circle_rounded,
                  size: 56.r,
                  borderRadius: AppRadii.borderMd,
                ),
            ],
          ),
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
