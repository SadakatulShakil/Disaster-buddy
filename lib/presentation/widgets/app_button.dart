import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Visual style of an [AppButton].
enum AppButtonVariant {
  /// Filled, high-emphasis action.
  primary,

  /// Outlined, lower-emphasis action.
  secondary,

  /// Circular, icon-only tap target (e.g. corner nav buttons).
  icon,
}

/// The app's single button widget. Always at least 56dp tall (or in
/// diameter, for [AppButtonVariant.icon]) so every tap target is
/// comfortably reachable by small hands. Presses give a gentle scale +
/// shadow micro-interaction.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    this.label = '',
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.color,
    this.semanticsLabel,
  }) : assert(
          variant == AppButtonVariant.icon || label != '',
          'label is required unless variant is AppButtonVariant.icon',
        );

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Leading icon for [AppButtonVariant.primary]/[AppButtonVariant.secondary],
  /// or the sole content for [AppButtonVariant.icon].
  final IconData? icon;

  /// Overrides the brand primary colour, e.g. with a module's themeColor.
  final Color? color;

  /// Overrides [label] as the accessible name (useful for icon buttons).
  final String? semanticsLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final baseColor = widget.color ?? AppColors.primary;
    final isSecondary = widget.variant == AppButtonVariant.secondary;
    final isIcon = widget.variant == AppButtonVariant.icon;

    final Color background;
    final Color foreground;
    if (disabled) {
      background = AppColors.divider;
      foreground = AppColors.textGrey;
    } else if (isSecondary) {
      background = AppColors.surface;
      foreground = baseColor;
    } else {
      background = baseColor;
      foreground = AppColors.textOnPrimary;
    }

    final shadow = disabled || _pressed ? AppShadows.subtle : AppShadows.soft;

    final Widget content = isIcon
        ? Icon(widget.icon, color: foreground, size: 24.sp)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: foreground, size: 20.sp),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(widget.label, style: AppTextStyles.button.copyWith(color: foreground)),
            ],
          );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticsLabel ?? widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: isIcon ? 50.r : null,
            height: isIcon ? 50.r : null,
            constraints: isIcon ? null : BoxConstraints(minHeight: 56.r),
            padding: isIcon ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              shape: isIcon ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isIcon ? null : AppRadii.borderMd,
              border: isSecondary && !disabled ? Border.all(color: baseColor, width: 2) : null,
              boxShadow: shadow,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
