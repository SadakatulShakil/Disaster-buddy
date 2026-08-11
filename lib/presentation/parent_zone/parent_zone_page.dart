import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/badge_chip.dart';
import '../widgets/section_header.dart';
import 'parent_zone_controller.dart';
import 'widgets/reset_dialogs.dart';

/// Parent Zone skeleton: a real progress summary plus clearly-labelled
/// stubs for the Phase 5 features (family emergency plan, official
/// resources), and a link into Settings. Reached only via [ParentGatePage].
class ParentZonePage extends GetView<ParentZoneController> {
  const ParentZonePage({super.key});

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
                  'parent_zone'.tr,
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
                case ParentZoneViewStatus.loading:
                  return const AppLoader();
                case ParentZoneViewStatus.error:
                  return AppErrorView(message: controller.errorMessage.value, onRetry: controller.load);
                case ParentZoneViewStatus.data:
                  return ListView(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    children: [
                      SectionHeader(title: 'progress_summary'.tr),
                      SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                icon: Icons.map_rounded,
                                value: '${controller.completedModules.value}/${controller.totalModules.value}',
                                label: 'modules_completed'.tr,
                              ),
                            ),
                            Container(width: 1, height: 48.r, color: AppColors.divider),
                            Expanded(
                              child: _StatColumn(
                                icon: Icons.backpack_rounded,
                                value: '${controller.completedActivities.value}/${controller.totalActivities.value}',
                                label: 'activities_completed'.tr,
                              ),
                            ),
                            Container(width: 1, height: 48.r, color: AppColors.divider),
                            Expanded(
                              child: _StatColumn(
                                icon: Icons.emoji_events_rounded,
                                value: '${controller.badgesEarned.value}',
                                label: 'badges_earned'.tr,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      SectionHeader(title: 'settings'.tr),
                      SizedBox(height: AppSpacing.sm),
                      AppCard(
                        onTap: () => Get.toNamed(AppRoutes.settings),
                        semanticsLabel: 'open_settings'.tr,
                        child: Row(
                          children: [
                            const Icon(Icons.settings_rounded, color: AppColors.primary),
                            SizedBox(width: AppSpacing.md),
                            Expanded(child: Text('open_settings'.tr, style: AppTextStyles.body)),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      SectionHeader(title: 'manage_progress_section'.tr),
                      SizedBox(height: AppSpacing.sm),
                      Obx(
                        () => _ResetOptionCard(
                          icon: Icons.restart_alt_rounded,
                          color: AppColors.primary,
                          title: 'reset_learning_title'.tr,
                          subtitle: 'reset_learning_subtitle'.tr,
                          enabled: !controller.isResetting.value,
                          onTap: () => _handleResetLearning(context, controller),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Obx(
                        () => _ResetOptionCard(
                          icon: Icons.map_outlined,
                          color: AppColors.accent,
                          title: 'reset_single_title'.tr,
                          subtitle: 'reset_single_subtitle'.tr,
                          enabled: !controller.isResetting.value,
                          onTap: () => _handleResetSingleModule(context, controller),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Obx(
                        () => _ResetOptionCard(
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.error,
                          title: 'reset_everything_title'.tr,
                          subtitle: 'reset_everything_subtitle'.tr,
                          enabled: !controller.isResetting.value,
                          onTap: () => _handleResetEverything(context, controller),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      SectionHeader(title: 'family_emergency_plan'.tr),
                      SizedBox(height: AppSpacing.sm),
                      const _StubCard(icon: Icons.family_restroom_rounded),
                      SizedBox(height: AppSpacing.xl),
                      SectionHeader(title: 'official_resources'.tr),
                      SizedBox(height: AppSpacing.sm),
                      const _StubCard(icon: Icons.link_rounded),
                    ],
                  );
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28.sp),
        SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.h1),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

/// A clearly-labelled "not built yet" row — never styled as an error.
class _StubCard extends StatelessWidget {
  const _StubCard({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGrey),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: BadgeChip(label: 'coming_in_phase5'.tr, icon: Icons.schedule_rounded, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

/// One reset option: a themed icon, title, and a plain-language
/// description of exactly what it erases and what it keeps — so a parent
/// is never surprised by what a tap leads to.
class _ResetOptionCard extends StatelessWidget {
  const _ResetOptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: enabled ? onTap : null,
      semanticsLabel: '$title. $subtitle',
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.title),
                SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: AppTextStyles.bodyGrey),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
        ],
      ),
    );
  }
}

Future<void> _handleResetLearning(BuildContext context, ParentZoneController controller) async {
  final confirmed = await showResetConfirmDialog(
    context,
    title: 'reset_learning_confirm_title'.tr,
    body: 'reset_learning_confirm_body'.tr,
    confirmColor: AppColors.primary,
  );
  if (confirmed != true || !context.mounted) return;

  final result = await controller.performResetLearningProgress();
  if (!context.mounted) return;
  await showResetResultDialog(context, result, successBody: 'reset_learning_success_body'.tr);
}

Future<void> _handleResetSingleModule(BuildContext context, ParentZoneController controller) async {
  final moduleId = await showModulePickerDialog(
    context,
    modules: controller.modules,
    completedModuleIds: controller.completedModuleIds,
  );
  if (moduleId == null || !context.mounted) return;

  final langCode = Get.locale?.languageCode ?? 'bn';
  final module = controller.modules.firstWhere((m) => m.id == moduleId);
  final moduleTitle = module.title.resolve(langCode);

  final confirmed = await showResetConfirmDialog(
    context,
    title: 'reset_single_confirm_title'.trParams({'module': moduleTitle}),
    body: 'reset_single_confirm_body'.trParams({'module': moduleTitle}),
    confirmColor: AppColors.accent,
  );
  if (confirmed != true || !context.mounted) return;

  final result = await controller.performResetSingleModule(moduleId);
  if (!context.mounted) return;
  await showResetResultDialog(
    context,
    result,
    successBody: 'reset_single_success_body'.trParams({'module': moduleTitle}),
  );
}

Future<void> _handleResetEverything(BuildContext context, ParentZoneController controller) async {
  final confirmed = await showResetConfirmDialog(
    context,
    title: 'reset_everything_confirm_title'.tr,
    body: 'reset_everything_confirm_body'.tr,
    confirmColor: AppColors.error,
  );
  if (confirmed != true || !context.mounted) return;

  final held = await showHoldToConfirmDialog(context);
  if (held != true || !context.mounted) return;

  final result = await controller.performResetEverything();
  if (!context.mounted) return;
  await showResetResultDialog(context, result, successBody: 'reset_everything_success_body'.tr);
}
