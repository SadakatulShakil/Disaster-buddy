import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/badge_chip.dart';
import '../widgets/placeholder_art.dart';
import '../widgets/staggered_entrance.dart';
import 'activities_controller.dart';
import 'activity_stub.dart';
import 'widgets/activity_card.dart';

/// Activities entry point: cross-cutting, module-independent things to try
/// anytime, reachable from the Adventure Map. Shows implemented activities
/// (the Emergency Kit Builder) with real completion state, plus clearly
/// labelled future stubs so the list reads as extensible, not broken.
class ActivitiesPage extends GetView<ActivitiesController> {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showSkyDecoration: true,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                AppButton(
                  variant: AppButtonVariant.icon,
                  icon: Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  semanticsLabel: 'back'.tr,
                  onPressed: () => Get.back(),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  'activities'.tr,
                  style: AppTextStyles.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              switch (controller.status.value) {
                case ActivitiesViewStatus.loading:
                  return const AppLoader();
                case ActivitiesViewStatus.error:
                  return AppErrorView(message: controller.errorMessage.value, onRetry: controller.load);
                case ActivitiesViewStatus.data:
                  return _ActivitiesGrid(controller: controller);
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _ActivitiesGrid extends StatelessWidget {
  const _ActivitiesGrid({required this.controller});

  final ActivitiesController controller;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final activity in controller.activities)
        ActivityCard(
          activity: activity,
          isCompleted: controller.isActivityCompleted(activity.id),
          onTap: () => _open(activity.id),
        ),
      for (final stub in kFutureActivityStubs) _ActivityStubTile(stub: stub),
    ];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
          sliver: SliverToBoxAdapter(
            child: Text('activities_subtitle'.tr, style: AppTextStyles.bodyGrey),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              // A fixed cell height (not an aspect ratio) — content height
              // doesn't scale with card width, so this is what actually
              // guarantees no overflow at any screen width.
              mainAxisExtent: ActivityGridConstants.cellHeight,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => StaggeredEntrance(index: index, child: tiles[index]),
              childCount: tiles.length,
            ),
          ),
        ),
      ],
    );
  }

  void _open(String activityId) {
    if (activityId == AppConstants.activityEmergencyKit) {
      Get.toNamed(AppRoutes.kitBuilder, arguments: activityId);
    }
  }
}

/// A future activity with no manifest yet — dimmed, non-interactive,
/// clearly labelled "coming soon" rather than looking broken. Matches
/// [ActivityCard]'s sizing exactly (via [ActivityGridConstants]) so the
/// grid looks like one consistent set of cards, not two different shapes.
class _ActivityStubTile extends StatelessWidget {
  const _ActivityStubTile({required this.stub});

  final ActivityStub stub;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: stub.titleKey.tr,
      hint: 'coming_soon_title'.tr,
      child: Opacity(
        opacity: 0.6,
        child: AppCard(
          color: AppColors.surfaceTint,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlaceholderArt(
                assetPath: '',
                themeColor: AppColors.textGrey,
                fallbackIcon: stub.icon,
                size: ActivityGridConstants.iconSize,
                borderRadius: AppRadii.borderPill,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                stub.titleKey.tr,
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: ActivityGridConstants.statusRowHeight,
                child: Center(
                  child: BadgeChip(label: 'coming_soon_title'.tr, icon: Icons.schedule_rounded, color: AppColors.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
