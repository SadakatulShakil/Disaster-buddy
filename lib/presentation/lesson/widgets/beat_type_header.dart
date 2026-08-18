import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/beat.dart';
import '../../module/widgets/beat_stone.dart';
import 'lesson_progress_dots.dart';

/// Persistent header shown on every beat: its type label + icon (reusing
/// `beatMeta`, the same metadata ModuleHome's stepping stones use) and its
/// "Part X of N" position within the module — so the child always knows
/// what kind of activity they're doing and where it sits, even though each
/// lesson visit now shows exactly one beat before returning to ModuleHome.
class BeatTypeHeader extends StatelessWidget {
  const BeatTypeHeader({
    super.key,
    required this.beat,
    required this.current,
    required this.total,
    required this.color,
  });

  final Beat beat;
  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = beatMeta(beat);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.title.copyWith(color: color)),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'beat_position'.trParams({'current': '${current + 1}', 'total': '$total'}),
          style: AppTextStyles.caption,
        ),
        SizedBox(height: AppSpacing.xs),
        LessonProgressDots(count: total, current: current, color: color),
      ],
    );
  }
}
