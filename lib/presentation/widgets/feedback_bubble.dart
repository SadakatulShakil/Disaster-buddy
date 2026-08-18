import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_card.dart';

/// The one shared "kind feedback" bubble used everywhere a child answers
/// something — quizzes, practice mini-games, and the three activities — so
/// wrong/correct feedback always looks and behaves the same: a friendly
/// card with a status icon and a specific, calm message. Tappable to
/// dismiss (and stop narrating) early; otherwise cleared by its caller
/// once the message finishes narrating (see `FeedbackPresenterMixin`).
class FeedbackBubble extends StatelessWidget {
  const FeedbackBubble({
    super.key,
    required this.message,
    required this.isCorrect,
    this.onTap,
  });

  final String message;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = isCorrect ? AppColors.success : AppColors.error;

    return Semantics(
      liveRegion: true,
      label: message,
      child: AppCard(
        onTap: onTap,
        color: tint.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              isCorrect ? Icons.celebration_rounded : Icons.favorite_rounded,
              color: tint,
              size: 28.sp,
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: AppTextStyles.body.copyWith(color: tint)),
            ),
          ],
        ),
      ),
    );
  }
}
