import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/mascot_view.dart';
import 'kit_builder_controller.dart';
import 'widgets/go_bag_drop_target.dart';
import 'widgets/kit_complete_summary.dart';
import 'widgets/kit_item_pool.dart';

/// The Emergency Kit Builder: drag every correct item into the go-bag.
/// Fully data-driven from the activity's manifest — item sets, correctness,
/// affirmations, and the badge can all change with zero code edits.
class KitBuilderPage extends GetView<KitBuilderController> {
  const KitBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case KitBuilderViewStatus.loading:
          return const AppScaffold(body: AppLoader());
        case KitBuilderViewStatus.error:
          return AppScaffold(
            body: AppErrorView(message: controller.errorMessage.value, onRetry: controller.load),
          );
        case KitBuilderViewStatus.data:
          return _KitBuilderBody(controller: controller);
      }
    });
  }
}

class _KitBuilderBody extends StatefulWidget {
  const _KitBuilderBody({required this.controller});

  final KitBuilderController controller;

  @override
  State<_KitBuilderBody> createState() => _KitBuilderBodyState();
}

class _KitBuilderBodyState extends State<_KitBuilderBody> {
  final Rx<MascotMood> _mascotMood = MascotMood.idle.obs;
  bool _narratedInstructions = false;

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
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(activity.title.resolve(langCode)),
      ),
      // Reads `controller.isComplete`/`packedItemIds`, so packing the last
      // item swaps straight to the summary without needing another tap.
      body: Obx(() {
        if (controller.isComplete.value) {
          return KitCompleteSummary(
            activity: activity,
            packedItemIds: controller.packedItemIds.toSet(),
            badgeAwarded: controller.badgeAwarded.value,
            themeColor: themeColor,
          );
        }

        return Column(
          children: [
            SizedBox(height: AppSpacing.sm),
            Obx(() => MascotView(mood: _mascotMood.value, size: 88)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Text(
                activity.instructions.resolve(langCode),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 4,
              child: GoBagDropTarget(
                controller: controller,
                themeColor: themeColor,
                onDrop: (item) {
                  controller.handleDrop(item);
                  _mascotMood.value = item.isCorrect ? MascotMood.cheer : MascotMood.idle;
                },
              ),
            ),
            Expanded(
              flex: 5,
              child: KitItemPool(controller: controller, themeColor: themeColor),
            ),
          ],
        );
      }),
    );
  }
}
