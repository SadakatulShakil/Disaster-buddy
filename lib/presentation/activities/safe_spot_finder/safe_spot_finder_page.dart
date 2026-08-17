import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mascot_view.dart';
import 'safe_spot_finder_controller.dart';
import 'widgets/safe_spot_complete_summary.dart';
import 'widgets/safe_spot_scene_view.dart';

/// Safe Spot Finder: tap every safe spot hiding in each illustrated scene.
/// Fully data-driven from the activity's manifest — scenes, hotspots, and
/// the badge can all change with zero code edits.
class SafeSpotFinderPage extends GetView<SafeSpotFinderController> {
  const SafeSpotFinderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case SafeSpotFinderViewStatus.loading:
          return const AppScaffold(body: AppLoader());
        case SafeSpotFinderViewStatus.error:
          return AppScaffold(
            body: AppErrorView(message: controller.errorMessage.value, onRetry: controller.load),
          );
        case SafeSpotFinderViewStatus.data:
          return _SafeSpotFinderBody(controller: controller);
      }
    });
  }
}

class _SafeSpotFinderBody extends StatefulWidget {
  const _SafeSpotFinderBody({required this.controller});

  final SafeSpotFinderController controller;

  @override
  State<_SafeSpotFinderBody> createState() => _SafeSpotFinderBodyState();
}

class _SafeSpotFinderBodyState extends State<_SafeSpotFinderBody> {
  final Rx<MascotMood> _mascotMood = MascotMood.point.obs;
  bool _narratedInstructions = false;
  int? _narratedSceneIndex;

  Color get _themeColor => AppColors.fromHex(widget.controller.activity.value!.themeColorHex);

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final themeColor = _themeColor;
    final activity = controller.activity.value!;
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    if (!_narratedInstructions) {
      _narratedInstructions = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.narrate(activity.instructions));
    }

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
                Expanded(
                  child: Text(
                    activity.title.resolve(langCode),
                    style: AppTextStyles.h1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isComplete.value) {
                return SafeSpotCompleteSummary(
                  activity: activity,
                  badgeAwarded: controller.badgeAwarded.value,
                  themeColor: themeColor,
                );
              }

              final sceneIndex = controller.sceneIndex.value;
              final scene = controller.currentScene;
              final found = controller.foundSafeIds.toSet();
              final feedback = controller.lastFeedback.value;

              if (_narratedSceneIndex != sceneIndex) {
                _narratedSceneIndex = sceneIndex;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) controller.narrate(scene.prompt);
                });
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'safe_spot_scene_progress'.trParams({
                        'current': '${sceneIndex + 1}',
                        'total': '${controller.scenes.length}',
                      }),
                      style: AppTextStyles.caption,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Obx(() => MascotView(mood: _mascotMood.value, size: 64)),
                    SizedBox(height: AppSpacing.sm),
                    Text(scene.prompt.resolve(langCode), style: AppTextStyles.h2, textAlign: TextAlign.center),
                    SizedBox(height: AppSpacing.md),
                    SafeSpotSceneView(
                      scene: scene,
                      themeColor: themeColor,
                      foundSafeIds: found,
                      lastUnsafeSpotId: controller.lastUnsafeSpotId.value,
                      onTapHotspot: (spot) async {
                        final outcome = await controller.handleTap(spot);
                        if (outcome == SafeSpotTapOutcome.newlySafe) {
                          _mascotMood.value = MascotMood.cheer;
                        } else if (outcome == SafeSpotTapOutcome.unsafe) {
                          _mascotMood.value = MascotMood.think;
                        }
                      },
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'safe_spot_found_progress'.trParams({
                        'found': '${found.length}',
                        'total': '${scene.safeSpotCount}',
                      }),
                      style: AppTextStyles.body,
                    ),
                    if (feedback != null) ...[
                      SizedBox(height: AppSpacing.sm),
                      Text(feedback.resolve(langCode), style: AppTextStyles.bodyGrey, textAlign: TextAlign.center),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
