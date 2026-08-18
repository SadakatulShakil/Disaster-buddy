import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/weather_sign_option.dart';

/// One tappable hazard-name choice for the current sign.
class HazardOptionTile extends StatelessWidget {
  const HazardOptionTile({
    super.key,
    required this.option,
    required this.themeColor,
    required this.isCorrectReveal,
    required this.isWrongReveal,
    required this.onTap,
  });

  final WeatherSignOption option;
  final Color themeColor;
  final bool isCorrectReveal;
  final bool isWrongReveal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final label = option.label.resolve(langCode);
    final tint = isCorrectReveal
        ? AppColors.success
        : isWrongReveal
            ? AppColors.error
            : themeColor;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: BoxConstraints(minWidth: 140.r, minHeight: 56.r),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: isCorrectReveal || isWrongReveal ? 0.18 : 0.08),
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: tint, width: isCorrectReveal || isWrongReveal ? 3 : 2),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.body, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
