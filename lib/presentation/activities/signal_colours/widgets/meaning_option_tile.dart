import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/signal_info.dart';
import '../../../widgets/placeholder_art.dart';

/// One tappable meaning+action option for the current signal. Shows the
/// candidate meaning as its primary label and the matching safe action as a
/// caption, so a single correct tap teaches both.
class MeaningOptionTile extends StatelessWidget {
  const MeaningOptionTile({
    super.key,
    required this.option,
    required this.themeColor,
    required this.isCorrectReveal,
    required this.isWrongReveal,
    required this.onTap,
  });

  final SignalInfo option;
  final Color themeColor;
  final bool isCorrectReveal;
  final bool isWrongReveal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final meaning = option.meaning.resolve(langCode);
    final action = option.action.resolve(langCode);
    final tint = isCorrectReveal
        ? AppColors.success
        : isWrongReveal
            ? AppColors.error
            : themeColor;

    return Semantics(
      button: true,
      label: '$meaning. $action',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: BoxConstraints(minWidth: 140.r, minHeight: 56.r),
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: isCorrectReveal || isWrongReveal ? 0.18 : 0.08),
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: tint, width: isCorrectReveal || isWrongReveal ? 3 : 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlaceholderArt(
                assetPath: option.actionIcon,
                themeColor: tint,
                fallbackIcon: Icons.touch_app_rounded,
                size: 48.r,
                borderRadius: AppRadii.borderMd,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(meaning, style: AppTextStyles.body, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.xs),
              Text(action, style: AppTextStyles.caption, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
