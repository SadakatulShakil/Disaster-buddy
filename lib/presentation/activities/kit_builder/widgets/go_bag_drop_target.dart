import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/kit_item.dart';
import '../../../widgets/placeholder_art.dart';
import '../kit_builder_controller.dart';

/// The go-bag: a [DragTarget] that accepts any [KitItem], highlighting while
/// something hovers over it, and showing every correctly-packed item so far.
/// Accepts every drop attempt and reports it via [onDrop] rather than
/// deciding correctness itself, so the caller can react (e.g. update the
/// mascot's mood) alongside [KitBuilderController.handleDrop].
class GoBagDropTarget extends StatelessWidget {
  const GoBagDropTarget({super.key, required this.controller, required this.themeColor, required this.onDrop});

  final KitBuilderController controller;
  final Color themeColor;
  final void Function(KitItem item) onDrop;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activity = controller.activity.value!;
      final packed = activity.items.where((item) => controller.packedItemIds.contains(item.id)).toList();

      return DragTarget<KitItem>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) => onDrop(details.data),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Semantics(
            label: 'kit_bag_semantics'.trParams({
              'packed': '${packed.length}',
              'total': '${controller.correctTotal}',
            }),
            container: true,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              margin: EdgeInsets.all(AppSpacing.md),
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: isHovering ? 0.22 : 0.1),
                border: Border.all(color: themeColor, width: isHovering ? 4 : 2),
                borderRadius: AppRadii.borderLg,
              ),
              child: Column(
                children: [
                  PlaceholderArt(
                    assetPath: activity.iconAsset,
                    themeColor: themeColor,
                    fallbackIcon: Icons.backpack_rounded,
                    size: 56.r,
                    borderRadius: AppRadii.borderPill,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text('${packed.length}/${controller.correctTotal}', style: AppTextStyles.h2),
                  SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: packed.isEmpty
                        ? Center(
                            child: Text(
                              'drag_items_hint'.tr,
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final item in packed)
                                  PlaceholderArt(
                                    key: ValueKey('packed-${item.id}'),
                                    assetPath: item.imageAsset,
                                    themeColor: themeColor,
                                    fallbackIcon: Icons.check_circle_rounded,
                                    size: 40.r,
                                    borderRadius: AppRadii.borderMd,
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
