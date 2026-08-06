import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/beat.dart';
import '../../widgets/app_card.dart';
import '../../widgets/badge_chip.dart';

/// Returns the localized label and icon for a [Beat]'s type.
(String, IconData) beatMeta(Beat beat) => switch (beat) {
      StoryBeat() => ('beat_story'.tr, Icons.auto_stories_rounded),
      StepsBeat() => ('beat_steps'.tr, Icons.list_alt_rounded),
      PracticeBeat() => ('beat_practice'.tr, Icons.sports_esports_rounded),
      QuizBeat() => ('beat_quiz'.tr, Icons.quiz_rounded),
    };

/// One "stepping stone" on the ModuleHome beat list.
class BeatStone extends StatelessWidget {
  const BeatStone({
    super.key,
    required this.beat,
    required this.themeColor,
    required this.isCompleted,
    required this.isResume,
    required this.onTap,
  });

  final Beat beat;
  final Color themeColor;
  final bool isCompleted;
  final bool isResume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = beatMeta(beat);
    final tint = isCompleted || isResume ? themeColor : AppColors.textGrey;

    return Semantics(
      button: true,
      label: label,
      hint: isResume ? 'resume_here'.tr : (isCompleted ? 'module_completed'.tr : null),
      child: AppCard(
        onTap: onTap,
        color: isResume ? themeColor.withValues(alpha: 0.08) : AppColors.surface,
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.15),
                borderRadius: AppRadii.borderMd,
                border: Border.all(color: tint, width: 2),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: tint, size: 24.sp),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTextStyles.title),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle_rounded, color: AppColors.success)
            else if (isResume)
              BadgeChip(label: 'resume_here'.tr, icon: Icons.play_arrow_rounded, color: themeColor),
          ],
        ),
      ),
    );
  }
}
