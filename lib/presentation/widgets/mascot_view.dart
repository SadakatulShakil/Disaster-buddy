import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';

/// A mood Tuku (the tiger-cub mascot) can be shown in.
enum MascotMood { idle, happy, cheer, point, think }

/// Renders Tuku the mascot in a given [MascotMood].
///
/// Three fallback tiers, richest first, same widget/API throughout so
/// dropping in better art later requires no screen changes:
///  1. A per-mood Lottie file (`assets/animations/mascot_<mood>.json`).
///  2. A per-mood static illustration (`assets/images/mascot/tuku_<mood>.png`),
///     played with the same hand-built bob/scale/rotate motion as tier 3.
///  3. A native emoji-in-a-circle placeholder, for moods with no art yet.
class MascotView extends StatefulWidget {
  const MascotView({super.key, this.mood = MascotMood.idle, this.size = 150});

  final MascotMood mood;
  final double size;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with SingleTickerProviderStateMixin {
  // Assigned eagerly in initState (not as a lazy `late` field initializer):
  // the errorBuilder that uses this controller only runs once Lottie's
  // async asset load fails, so a lazy initializer could go untouched until
  // dispose() first reads it, constructing a controller on an
  // already-deactivating element and crashing.
  late final AnimationController _controller;

  bool _startedTicking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.breathing);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only ever start the repeating ticker once, and never under
    // reduce-motion — otherwise it would spin forever in the background.
    if (_startedTicking) return;
    _startedTicking = true;
    if (!MediaQuery.of(context).disableAnimations) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'meet_tuku'.tr,
      image: true,
      child: SizedBox(
        width: widget.size.r,
        height: widget.size.r,
        child: Lottie.asset(
          AssetPaths.mascotAnimation(widget.mood.name),
          repeat: true,
          errorBuilder: (context, error, stackTrace) => _NativeMascot(
            mood: widget.mood,
            controller: _controller,
            animate: !reduceMotion,
          ),
        ),
      ),
    );
  }
}

/// Gentle idle bob/scale/rotate motion, tuned per mood, played over either
/// a static mascot image (if bundled for this mood) or an emoji-in-a-circle
/// placeholder.
class _NativeMascot extends StatelessWidget {
  const _NativeMascot({required this.mood, required this.controller, required this.animate});

  final MascotMood mood;
  final AnimationController controller;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!animate) return _face();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value; // 0..1, breathing back and forth
        final wave = Curves.easeInOut.transform(t);

        double bobPixels;
        double scale;
        double rotationTurns;

        switch (mood) {
          case MascotMood.idle:
            bobPixels = -4 * wave;
            scale = 1 + 0.02 * wave;
            rotationTurns = 0;
          case MascotMood.happy:
            bobPixels = -10 * wave;
            scale = 1 + 0.06 * wave;
            rotationTurns = 0;
          case MascotMood.cheer:
            bobPixels = -16 * wave;
            scale = 1 + 0.08 * wave;
            rotationTurns = 0.02 * (wave - 0.5);
          case MascotMood.point:
            bobPixels = -3 * wave;
            scale = 1 + 0.015 * wave;
            rotationTurns = 0.015 * (wave - 0.5);
          case MascotMood.think:
            bobPixels = -2 * wave;
            scale = 1 + 0.01 * wave;
            rotationTurns = 0.01 * (wave - 0.5);
        }

        return Transform.translate(
          offset: Offset(0, bobPixels),
          child: Transform.rotate(
            angle: rotationTurns * 6.28318,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: _face(),
    );
  }

  /// Most exported mascot art keeps a transparent safety margin around the
  /// character, so drawing the PNG at exactly the circle's own size (1.0)
  /// reads as noticeably smaller than the circle behind it. This paint-only
  /// zoom on the image content fixes that without changing `MascotView`'s
  /// own layout size — so it never affects surrounding screens' spacing.
  static const double _imageOverscale = 1.3;

  Widget _face() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Image.asset(
        AssetPaths.mascotImage(mood.name),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Text(_emojiFor(mood), style: TextStyle(fontSize: 56.sp)),
        // Only wraps the successfully-decoded image — the emoji fallback
        // above is returned via errorBuilder instead and never reaches
        // this builder, so it's untouched by the overscale.
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
            Transform.scale(scale: _imageOverscale, child: child),
      ),
    );
  }

  String _emojiFor(MascotMood mood) => switch (mood) {
        MascotMood.idle => '🐯',
        MascotMood.happy => '😄',
        MascotMood.cheer => '🎉',
        MascotMood.point => '👉',
        MascotMood.think => '🤔',
      };
}
