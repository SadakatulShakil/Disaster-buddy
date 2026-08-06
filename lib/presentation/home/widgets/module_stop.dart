import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/hazard_module.dart';
import '../../widgets/badge_chip.dart';
import '../../widgets/mascot_view.dart';
import '../../widgets/placeholder_art.dart';
import '../home_controller.dart';

/// One stop on the Adventure Map: a module's icon, title, and its
/// available/completed/locked state.
///
/// - available: interactive, gentle idle pulse, Tuku points at it.
/// - completed: a check badge, no error styling.
/// - locked: dimmed with a lock badge — a calm "coming next", not an error.
class ModuleStop extends StatefulWidget {
  const ModuleStop({
    super.key,
    required this.module,
    required this.state,
    required this.onTap,
    this.bubbleKey,
  });

  final HazardModule module;
  final ModuleStopState state;
  final VoidCallback? onTap;

  /// Attached to the circular bubble specifically (not the whole stop,
  /// which also includes the title/badge below it) so a caller can measure
  /// exactly where the circle is — e.g. to anchor the Adventure Map's
  /// connecting path to its true edge.
  final Key? bubbleKey;

  /// Shared Hero tag so tapping an available module smoothly morphs its icon
  /// into the ModuleHome header icon.
  static String heroTagFor(String moduleId) => 'module_hero_$moduleId';

  @override
  State<ModuleStop> createState() => _ModuleStopState();
}

class _ModuleStopState extends State<ModuleStop> with SingleTickerProviderStateMixin {
  // Assigned eagerly in initState (not as a lazy `late` field initializer):
  // if a stop never actually pulses, a lazy initializer would only run when
  // dispose() first reads it, constructing a controller on an
  // already-deactivating element and crashing.
  late final AnimationController _pulse;

  bool _startedTicking = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppDurations.pulse);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only ever start the repeating ticker once, and never under
    // reduce-motion — otherwise it would spin forever in the background.
    if (_startedTicking) return;
    _startedTicking = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.state == ModuleStopState.available && !reduceMotion) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final themeColor = AppColors.fromHex(widget.module.themeColorHex);
    final locked = widget.state == ModuleStopState.locked;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final shouldPulse = widget.state == ModuleStopState.available && !reduceMotion;

    // KeyedSubtree (not the key directly on Container) so `bubbleKey`
    // resolves to a RenderBox whose size is exactly the 96.r circle,
    // unaffected by the pulse animation's Transform.scale below (which
    // changes paint, not layout size or center).
    final bubbleCore = KeyedSubtree(
      key: widget.bubbleKey,
      child: Container(
        width: 96.r,
        height: 96.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: locked ? AppColors.divider.withValues(alpha: 0.4) : AppColors.surface,
          boxShadow: locked ? const [] : AppShadows.raised,
          border: Border.all(color: locked ? AppColors.divider : themeColor, width: 3),
        ),
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Opacity(
          opacity: locked ? 0.5 : 1,
          child: PlaceholderArt(
            assetPath: widget.module.iconAsset,
            themeColor: themeColor,
            fallbackIcon: _iconFor(widget.module.id),
            size: 72.r,
            borderRadius: AppRadii.borderPill,
          ),
        ),
      ),
    );

    final animatedBubble = shouldPulse
        ? AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Transform.scale(scale: 1 + 0.05 * _pulse.value, child: child),
            child: bubbleCore,
          )
        : bubbleCore;

    return Semantics(
      button: !locked,
      label: widget.module.title.resolve(langCode),
      hint: switch (widget.state) {
        ModuleStopState.locked => 'locked_module_hint'.tr,
        ModuleStopState.completed => 'module_completed'.tr,
        ModuleStopState.available => 'start_adventure'.tr,
      },
      child: GestureDetector(
        onTap: locked ? null : widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: ModuleStop.heroTagFor(widget.module.id),
                  child: Material(color: Colors.transparent, child: animatedBubble),
                ),
                if (widget.state == ModuleStopState.completed)
                  Positioned(
                    right: -4.r,
                    bottom: -4.r,
                    child: _statusDot(icon: Icons.check_rounded, color: AppColors.success),
                  ),
                if (locked)
                  Positioned(
                    right: -4.r,
                    bottom: -4.r,
                    child: _statusDot(icon: Icons.lock_rounded, color: AppColors.textGrey),
                  ),
                if (shouldPulse)
                  Positioned(
                    left: -12.r,
                    top: -12.r,
                    child: const MascotView(mood: MascotMood.point, size: 56),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              widget.module.title.resolve(langCode),
              style: locked ? AppTextStyles.caption : AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: switch (widget.state) {
                ModuleStopState.completed =>
                  BadgeChip(label: 'module_completed'.tr, icon: Icons.check_circle, color: AppColors.success),
                ModuleStopState.locked =>
                  BadgeChip(label: 'coming_next'.tr, icon: Icons.lock_outline_rounded, color: AppColors.textGrey),
                ModuleStopState.available => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot({required IconData icon, required Color color}) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.textOnPrimary, size: 16.sp),
    );
  }

  IconData _iconFor(String hazardId) => switch (hazardId) {
        AppConstants.hazardFlood => Icons.water_drop_rounded,
        AppConstants.hazardLightning => Icons.bolt_rounded,
        AppConstants.hazardEarthquake => Icons.terrain_rounded,
        // First Aid is a helper module, not a hazard — a caring heart
        // instead of a danger icon, so its stop reads differently on sight.
        AppConstants.hazardFirstAid => Icons.favorite_rounded,
        _ => Icons.shield_rounded,
      };
}
