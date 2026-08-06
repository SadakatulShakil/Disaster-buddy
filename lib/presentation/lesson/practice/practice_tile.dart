import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/practice_item.dart';
import '../../widgets/placeholder_art.dart';

/// Visual state of a [PracticeTile].
enum PracticeTileState { neutral, correct, wrong }

/// A big, tappable target shared by every practice mini-game: an image (via
/// [PlaceholderArt]) with a label underneath, tinted by [state]. Always at
/// least 56dp tall so small hands can hit it reliably.
class PracticeTile extends StatelessWidget {
  const PracticeTile({
    super.key,
    required this.item,
    required this.themeColor,
    required this.state,
    required this.onTap,
  });

  final PracticeItem item;
  final Color themeColor;
  final PracticeTileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = switch (state) {
      PracticeTileState.neutral => themeColor,
      PracticeTileState.correct => AppColors.success,
      PracticeTileState.wrong => AppColors.error,
    };
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final label = item.label.resolve(langCode);

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: BoxConstraints(minWidth: 96.r, minHeight: 96.r),
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: state == PracticeTileState.neutral ? 0.08 : 0.18),
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: tint, width: state == PracticeTileState.neutral ? 2 : 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlaceholderArt(
                assetPath: item.imageAsset ?? '',
                themeColor: tint,
                fallbackIcon: Icons.touch_app_rounded,
                size: 56.r,
                borderRadius: AppRadii.borderMd,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
