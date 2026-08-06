import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/hazard_module.dart';
import '../../widgets/app_button.dart';

/// A plain confirm/cancel dialog for a reset that's about to happen —
/// states what's about to be erased, in plain language, and that it can't
/// be undone. Returns `true` if the parent confirmed, `false`/`null`
/// otherwise.
Future<bool?> showResetConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required Color confirmColor,
}) {
  return showDialog<bool>(
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
              Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.sm),
              Text(body, style: AppTextStyles.bodyGrey, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.lg),
              // Stacked full-width (not side-by-side) so neither label is
              // ever squeezed into half the dialog's width.
              AppButton(
                label: 'yes_reset'.tr,
                color: confirmColor,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'cancel'.tr,
                variant: AppButtonVariant.secondary,
                color: confirmColor,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Lets the parent pick exactly one hazard module to reset, showing each
/// module's real completed/not-yet-completed state. Returns the chosen
/// module id, or `null` if cancelled.
Future<String?> showModulePickerDialog(
  BuildContext context, {
  required List<HazardModule> modules,
  required Set<String> completedModuleIds,
}) {
  final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
  return showDialog<String>(
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
              Text('reset_single_picker_title'.tr, style: AppTextStyles.h2, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.md),
              for (final module in modules) ...[
                _ModulePickerRow(
                  module: module,
                  isCompleted: completedModuleIds.contains(module.id),
                  langCode: langCode,
                  onTap: () => Navigator.of(context).pop(module.id),
                ),
                SizedBox(height: AppSpacing.sm),
              ],
              SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'cancel'.tr,
                variant: AppButtonVariant.secondary,
                color: AppColors.accent,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ModulePickerRow extends StatelessWidget {
  const _ModulePickerRow({
    required this.module,
    required this.isCompleted,
    required this.langCode,
    required this.onTap,
  });

  final HazardModule module;
  final bool isCompleted;
  final String langCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.fromHex(module.themeColorHex);
    return Semantics(
      button: true,
      label: module.title.resolve(langCode),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.borderMd,
        child: Container(
          constraints: BoxConstraints(minHeight: 56.r),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.08),
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: themeColor.withValues(alpha: 0.4)),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: themeColor,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(child: Text(module.title.resolve(langCode), style: AppTextStyles.body)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The strongest confirm step, reserved for wiping everything: the parent
/// must press and hold the button for a moment (not a single tap) before
/// it fires. Returns `true` once held to completion, `false`/`null` if
/// cancelled.
Future<bool?> showHoldToConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 40.sp),
              SizedBox(height: AppSpacing.sm),
              Text('reset_hold_title'.tr, style: AppTextStyles.h2, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.sm),
              Text('reset_hold_body'.tr, style: AppTextStyles.bodyGrey, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.lg),
              _HoldToConfirmButton(onConfirmed: () => Navigator.of(context).pop(true)),
              SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'cancel'.tr,
                variant: AppButtonVariant.secondary,
                color: AppColors.error,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A press-and-hold button that fires [onConfirmed] once held for the full
/// [_holdDuration] — deliberate friction for the single most destructive
/// action in the app. Assistive-technology users can activate it via the
/// standard long-press accessibility action without needing to sustain a
/// physical touch.
class _HoldToConfirmButton extends StatefulWidget {
  const _HoldToConfirmButton({required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  State<_HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<_HoldToConfirmButton> with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _holdDuration);
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatusChange);
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_confirmed) {
      _confirmed = true;
      widget.onConfirmed();
    }
  }

  void _confirmImmediately() {
    if (_confirmed) return;
    _confirmed = true;
    widget.onConfirmed();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'reset_hold_button'.tr,
      onLongPress: _confirmImmediately,
      child: GestureDetector(
        onLongPressStart: (_) => _controller.forward(from: 0),
        onLongPressEnd: (_) => _controller.reverse(),
        onLongPressCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              constraints: BoxConstraints(minHeight: 56.r),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.35),
                borderRadius: AppRadii.borderMd,
                border: Border.all(color: AppColors.error, width: 2),
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _controller.value,
                      child: Container(color: AppColors.error),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Text(
                      'reset_hold_button'.tr,
                      style: AppTextStyles.button.copyWith(color: AppColors.textOnPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A brief success or friendly-failure dialog shown after a reset attempt.
Future<void> showResetResultDialog(BuildContext context, Result<void> result, {required String successBody}) {
  return switch (result) {
    Success<void>() => showDialog<void>(
        context: context,
        builder: (context) => _ResetResultDialog(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: 'reset_success_title'.tr,
          body: successBody,
        ),
      ),
    Failure<void>(failure: final failure) => showDialog<void>(
        context: context,
        builder: (context) => _ResetResultDialog(
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
          title: 'something_went_wrong'.tr,
          body: failure.message,
        ),
      ),
  };
}

class _ResetResultDialog extends StatelessWidget {
  const _ResetResultDialog({required this.icon, required this.color, required this.title, required this.body});

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, color: color, size: 40.sp),
              SizedBox(height: AppSpacing.sm),
              Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.sm),
              Text(body, style: AppTextStyles.bodyGrey, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.lg),
              AppButton(label: 'done'.tr, color: color, onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}
