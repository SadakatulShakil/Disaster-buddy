import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/beat.dart';
import '../home/widgets/module_stop.dart';
import '../lesson/lesson_args.dart';
import '../widgets/app_button.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/placeholder_art.dart';
import 'module_controller.dart';
import 'widgets/beat_stone.dart';

/// ModuleHome: one hazard module's 4 beats (story, steps, practice, quiz) as
/// stepping stones, themed to the module's colour, with the first
/// incomplete beat highlighted as "resume here". Tapping the resume beat (or
/// any not-yet-completed beat) opens the lesson and walks forward from
/// there; tapping an already-completed beat replays just that beat. Back
/// returns to the Adventure Map.
class ModulePage extends GetView<ModuleController> {
  const ModulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final module = controller.module.value;
      final themeColor = module != null ? AppColors.fromHex(module.themeColorHex) : AppColors.primary;

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
                    color: themeColor,
                    semanticsLabel: 'back'.tr,
                    onPressed: () => Get.back(),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    module?.title.resolve(Get.locale?.languageCode ?? AppConstants.langBn) ?? '',
                    style: AppTextStyles.h1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (controller.status.value) {
                ModuleViewStatus.loading => const AppLoader(),
                ModuleViewStatus.error => AppErrorView(
                    message: controller.errorMessage.value,
                    onRetry: controller.load,
                  ),
                ModuleViewStatus.data => _ModuleBody(controller: controller, themeColor: themeColor),
              },
            ),
          ],
        ),
      );
    });
  }
}

class _ModuleBody extends StatelessWidget {
  const _ModuleBody({required this.controller, required this.themeColor});

  final ModuleController controller;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final module = controller.module.value!;
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final resumeIndex = controller.resumeIndex;

    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Hero(
              tag: ModuleStop.heroTagFor(module.id),
              child: Material(
                color: Colors.transparent,
                child: PlaceholderArt(
                  assetPath: module.iconAsset,
                  themeColor: themeColor,
                  fallbackIcon: Icons.shield_rounded,
                  size: 72.r,
                  borderRadius: AppRadii.borderPill,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(module.safeAction.resolve(langCode), style: AppTextStyles.body),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < module.beats.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: BeatStone(
              beat: module.beats[i],
              themeColor: themeColor,
              isCompleted: controller.isBeatCompleted(module.beats[i]),
              isResume: i == resumeIndex,
              onTap: () => _openBeat(module.id, module.beats[i]),
            ),
          ),
      ],
    );
  }

  /// Opens the lesson at [beat]. An already-completed beat opens in replay
  /// mode (shows just that beat, then returns); otherwise the lesson walks
  /// forward from here. Refreshes ModuleHome's own state on return so the
  /// resume highlight and completion badges reflect what just happened.
  Future<void> _openBeat(String moduleId, Beat beat) async {
    await Get.toNamed(
      AppRoutes.lesson,
      arguments: LessonArgs(
        moduleId: moduleId,
        startBeatId: beat.id,
        isReplay: controller.isBeatCompleted(beat),
      ),
    );
    controller.load();
  }
}
