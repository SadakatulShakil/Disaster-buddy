import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../domain/entities/safe_spot_hotspot.dart';

/// One tappable marker over a scene image, positioned by the caller to
/// exactly cover a hotspot's rendered rect (already inflated to at least a
/// 56dp tap target). Shows a gentle pulsing hint while unfound, a static
/// check once a safe spot is found, and a brief flash when an unsafe spot
/// is tapped — never a hard fail state.
class SafeSpotHotspotOverlay extends StatefulWidget {
  const SafeSpotHotspotOverlay({
    super.key,
    required this.spot,
    required this.isFound,
    required this.isWrongFlash,
    required this.onTap,
  });

  final SafeSpotHotspot spot;
  final bool isFound;
  final bool isWrongFlash;
  final VoidCallback onTap;

  @override
  State<SafeSpotHotspotOverlay> createState() => _SafeSpotHotspotOverlayState();
}

class _SafeSpotHotspotOverlayState extends State<SafeSpotHotspotOverlay> with SingleTickerProviderStateMixin {
  // Assigned eagerly in initState (not as a lazy `late` field initializer):
  // under reduce-motion, didChangeDependencies never starts the repeating
  // animation, so a lazy initializer would go untouched until dispose()
  // first reads it, constructing a controller on an already-deactivating
  // element and crashing. Mirrors MascotView's identical fix.
  late final AnimationController _pulseController;
  bool _startedPulsing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: AppDurations.pulse);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedPulsing) return;
    _startedPulsing = true;
    if (!MediaQuery.of(context).disableAnimations) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final label = widget.spot.label.resolve(langCode);
    final semanticsLabel = (widget.spot.isSafe ? 'safe_spot_hotspot_semantics_safe' : 'safe_spot_hotspot_semantics_unsafe')
        .trParams({'label': label});

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.isFound ? _foundMarker() : _hintMarker(),
      ),
    );
  }

  Widget _foundMarker() {
    return Center(
      child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36.r),
    );
  }

  Widget _hintMarker() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final tint = widget.isWrongFlash ? AppColors.error : AppColors.surface;

    if (reduceMotion) {
      return Center(
        child: Icon(Icons.location_searching_rounded, color: tint.withValues(alpha: 0.9), size: 30.r),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulseController.value);
        final opacity = widget.isWrongFlash ? 1.0 : 0.35 + 0.35 * t;
        return Center(
          child: Container(
            width: (40 + 8 * t).r,
            height: (40 + 8 * t).r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tint.withValues(alpha: opacity), width: 3),
            ),
          ),
        );
      },
    );
  }
}
