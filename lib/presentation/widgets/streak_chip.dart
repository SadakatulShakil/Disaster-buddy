import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/streak_state.dart';
import 'badge_chip.dart';

/// Compact "N-day streak" indicator, reused in the Adventure Map's daily
/// card, the daily challenge screens, and the streak chain view. Rewards
/// framing only — never shows a loss/warning state, even when the streak is
/// zero (a fresh chain is just as worth celebrating as a long one).
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.streak});

  final StreakState streak;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'streak_chip_semantics'.trParams({'count': '${streak.currentStreak}'}),
      excludeSemantics: true,
      child: BadgeChip(
        label: '${streak.currentStreak}',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.accent,
      ),
    );
  }
}
