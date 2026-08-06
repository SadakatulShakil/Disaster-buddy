import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/kit_item.dart';
import '../../../widgets/placeholder_art.dart';
import '../kit_builder_controller.dart';

/// One draggable card in the item pool. Always at least 56dp so small hands
/// can grab it. Reacts to being wrong-dropped with a brief red border + pop
/// animation (skipped under reduce-motion) — it never leaves the pool, so
/// there's always another chance.
class DraggableKitItem extends StatelessWidget {
  const DraggableKitItem({super.key, required this.item, required this.controller, required this.themeColor});

  final KitItem item;
  final KitBuilderController controller;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final label = item.label.resolve(langCode);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Obx(() {
      final isWrongNow = controller.lastWrongItemId.value == item.id;
      final nonce = controller.wrongNonce.value;

      final card = Container(
        width: 92.r,
        constraints: BoxConstraints(minHeight: 56.r),
        padding: EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.borderMd,
          border: Border.all(color: isWrongNow ? AppColors.error : themeColor, width: isWrongNow ? 3 : 2),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlaceholderArt(
              assetPath: item.imageAsset,
              themeColor: themeColor,
              fallbackIcon: Icons.inventory_2_rounded,
              size: 56.r,
              borderRadius: AppRadii.borderMd,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      );

      final presented = reduceMotion || !isWrongNow
          ? card
          : TweenAnimationBuilder<double>(
              key: ValueKey('wobble-${item.id}-$nonce'),
              tween: Tween(begin: 0.85, end: 1.0),
              duration: AppDurations.normal,
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: card,
            );

      return Semantics(
        button: true,
        label: label,
        child: Draggable<KitItem>(
          data: item,
          feedback: Opacity(opacity: 0.85, child: card),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: presented,
        ),
      );
    });
  }
}
