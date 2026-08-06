import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_text_styles.dart';

/// A circular progress indicator that animates to [progress] (0.0–1.0) and
/// optionally shows a short [label] (e.g. "2/4") in its center.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 56,
    this.color = AppColors.primary,
    this.label,
  });

  final double progress;
  final double size;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size.r,
      height: size.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 6,
            color: color.withValues(alpha: 0.15),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: reduceMotion ? Duration.zero : AppDurations.slow,
            curve: Curves.easeOut,
            builder: (context, value, child) => CircularProgressIndicator(
              value: value,
              strokeWidth: 6,
              color: color,
              backgroundColor: Colors.transparent,
            ),
          ),
          if (label != null) Text(label!, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
