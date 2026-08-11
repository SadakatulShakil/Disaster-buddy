import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/mascot_view.dart';
import 'parent_gate_controller.dart';

/// Child lock in front of [ParentZone]: a small, randomised addition
/// problem with no personal data involved. A wrong tap just regenerates the
/// problem — calm, never punitive.
class ParentGatePage extends GetView<ParentGateController> {
  const ParentGatePage({super.key});

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
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MascotView(mood: MascotMood.idle, size: 130),
                  SizedBox(height: AppSpacing.lg),
                  Text('parent_gate_prompt'.tr, style: AppTextStyles.body, textAlign: TextAlign.center),
                  SizedBox(height: AppSpacing.sm),
                  Obx(
                    () => Text(
                      '${controller.operandA.value} + ${controller.operandB.value} = ?',
                      style: AppTextStyles.display,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Obx(
                    () => AnimatedOpacity(
                      duration: AppDurations.fast,
                      opacity: controller.showError.value ? 1 : 0,
                      child: Text(
                        'parent_gate_wrong'.tr,
                        style: AppTextStyles.body.copyWith(color: AppColors.error),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Obx(
                    () => Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final choice in controller.choices)
                          _ChoiceButton(value: choice, onTap: () => controller.submit(choice)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$value',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72.r,
          height: 72.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Text('$value', style: AppTextStyles.h1),
        ),
      ),
    );
  }
}
