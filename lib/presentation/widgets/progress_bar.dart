import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radii.dart';

/// A horizontal progress indicator that animates its fill to [progress]
/// (0.0–1.0).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.progress,
    this.color = AppColors.primary,
    this.height = 12,
  });

  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: AppRadii.borderPill,
      child: Container(
        height: height.r,
        color: AppColors.divider,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: clamped),
          duration: reduceMotion ? Duration.zero : AppDurations.slow,
          curve: Curves.easeOut,
          builder: (context, value, child) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}
