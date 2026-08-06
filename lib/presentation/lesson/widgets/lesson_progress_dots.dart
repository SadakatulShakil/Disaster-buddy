import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

/// Indicates progress through a lesson's beats: a filled, widened dot marks
/// the current beat, filled dots mark ones already passed.
class LessonProgressDots extends StatelessWidget {
  const LessonProgressDots({super.key, required this.count, required this.current, required this.color});

  final int count;
  final int current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: i == current ? 20.r : 10.r,
              height: 10.r,
              decoration: BoxDecoration(
                color: i <= current ? color : color.withValues(alpha: 0.3),
                borderRadius: AppRadii.borderPill,
              ),
            ),
          ),
      ],
    );
  }
}
