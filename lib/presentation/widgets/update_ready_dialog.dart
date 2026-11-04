import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

/// Shown once a flexible Play Store update has finished downloading in the
/// background. Mirrors the look of the reset confirm dialogs — plain
/// language, one primary action. Dismissible by tapping outside (the user
/// can keep playing; the update installs next time the app is restarted
/// anyway), so this never blocks anything.
Future<void> showUpdateReadyDialog() {
  final context = Get.overlayContext;
  if (context == null) return Future.value();

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('update_ready_title'.tr, style: AppTextStyles.h2, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.sm),
              Text('update_ready_body'.tr, style: AppTextStyles.bodyGrey, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'restart_now'.tr,
                color: AppColors.primary,
                onPressed: () {
                  Navigator.of(context).pop();
                  InAppUpdate.completeFlexibleUpdate();
                },
              ),
              SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'later'.tr,
                variant: AppButtonVariant.secondary,
                color: AppColors.primary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
