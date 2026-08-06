import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../kit_builder_controller.dart';
import 'draggable_kit_item.dart';

/// The scrollable pool of not-yet-packed items. A correct item disappears
/// from here once packed (it now lives in the bag); a wrong item always
/// stays, ready to be dragged again.
class KitItemPool extends StatelessWidget {
  const KitItemPool({super.key, required this.controller, required this.themeColor});

  final KitBuilderController controller;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activity = controller.activity.value!;
      final unpacked = activity.items.where((item) => !controller.packedItemIds.contains(item.id)).toList();

      return SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in unpacked)
              DraggableKitItem(key: ValueKey(item.id), item: item, controller: controller, themeColor: themeColor),
          ],
        ),
      );
    });
  }
}
