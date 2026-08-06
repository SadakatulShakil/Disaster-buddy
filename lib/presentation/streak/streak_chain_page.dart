import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/local_day.dart';
import '../../domain/services/streak_calculator.dart';
import '../../domain/usecases/get_streak_overview.dart';
import '../widgets/app_card.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import 'streak_chain_controller.dart';

/// Shows the child's "chain with grace" streak: current/best length,
/// freezes left, and the last few weeks as a day-by-day chain. Every state
/// is framed warmly — a missed-beyond-grace day is a neutral, not a red or
/// scary, mark.
class StreakChainPage extends GetView<StreakChainController> {
  const StreakChainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showSkyDecoration: true,
      appBar: AppBar(backgroundColor: AppColors.accent, title: Text('streak_chain_title'.tr)),
      body: Obx(() {
        switch (controller.status.value) {
          case StreakChainViewStatus.loading:
            return const AppLoader();
          case StreakChainViewStatus.error:
            return AppErrorView(message: controller.errorMessage.value, onRetry: controller.load);
          case StreakChainViewStatus.data:
            return _StreakChainBody(overview: controller.overview.value!);
        }
      }),
    );
  }
}

class _StreakChainBody extends StatelessWidget {
  const _StreakChainBody({required this.overview});

  final StreakOverview overview;

  @override
  Widget build(BuildContext context) {
    final state = overview.state;
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'current_streak'.tr,
                  value: '${state.currentStreak}',
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(label: 'best_streak'.tr, value: '${state.bestStreak}', icon: Icons.emoji_events_rounded),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(label: 'freezes_left'.tr, value: '${state.freezesAvailable}', icon: Icons.ac_unit_rounded),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Text('streak_chain_subtitle'.tr, style: AppTextStyles.bodyGrey, textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final entry in overview.chain) _DayChainDot(entry: entry)],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 28.sp),
          SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.h1),
          SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DayChainDot extends StatelessWidget {
  const _DayChainDot({required this.entry});

  final DayChainEntry entry;

  @override
  Widget build(BuildContext context) {
    final Color tint;
    final IconData? icon;
    final double fillOpacity;
    switch (entry.state) {
      case DayChainState.completed:
        tint = AppColors.accent;
        icon = Icons.local_fire_department_rounded;
        fillOpacity = 0.22;
      case DayChainState.frozen:
        tint = AppColors.primary;
        icon = Icons.ac_unit_rounded;
        fillOpacity = 0.18;
      case DayChainState.today:
        tint = AppColors.primary;
        icon = null;
        fillOpacity = 0.1;
      case DayChainState.missed:
        tint = AppColors.textGrey;
        icon = null;
        fillOpacity = 0.06;
      case DayChainState.none:
        tint = AppColors.divider;
        icon = null;
        fillOpacity = 0.05;
    }

    final dayOfMonth = LocalDay.parseKey(entry.dateKey).day;

    return Semantics(
      label: 'streak_day_semantics'.trParams({'day': '$dayOfMonth', 'state': _stateLabel(entry.state)}),
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: fillOpacity),
          shape: BoxShape.circle,
          border: entry.state == DayChainState.today ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 16.sp, color: tint)
            : Text('$dayOfMonth', style: AppTextStyles.caption.copyWith(color: tint)),
      ),
    );
  }

  String _stateLabel(DayChainState state) => switch (state) {
        DayChainState.completed => 'streak_day_done'.tr,
        DayChainState.frozen => 'streak_day_frozen'.tr,
        DayChainState.today => 'streak_day_today'.tr,
        DayChainState.missed => 'streak_day_missed'.tr,
        DayChainState.none => '',
      };
}
