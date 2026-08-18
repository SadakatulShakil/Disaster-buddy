import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/sound_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/mascot_view.dart';
import '../widgets/placeholder_art.dart';
import 'reward_args.dart';

/// Delightful full-screen celebration shown once, the first time a module
/// is completed: confetti (native `CustomPainter`, no extra dependency),
/// a popping badge reveal, and Tuku cheering. Respects reduce-motion with a
/// calm, static fallback. "Back to map" returns to a freshly-unlocked
/// Adventure Map.
class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> with SingleTickerProviderStateMixin {
  late final RewardArgs _args = Get.arguments as RewardArgs;
  late final AnimationController _confettiController = AnimationController(
    vsync: this,
    duration: AppDurations.slow * 3,
  );
  late final List<_ConfettiParticle> _particles = List.generate(20, (i) => _ConfettiParticle.random(Random(i)));

  bool _startedForMotion = false;

  @override
  void initState() {
    super.initState();
    Get.find<SoundService>().playReward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedForMotion) return;
    _startedForMotion = true;
    if (MediaQuery.of(context).disableAnimations) {
      _confettiController.value = 1;
    } else {
      _confettiController.forward();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final themeColor = AppColors.fromHex(_args.themeColorHex);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AppScaffold(
      backgroundColor: themeColor.withValues(alpha: 0.08),
      body: Stack(
        children: [
          if (!reduceMotion)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(progress: _confettiController.value, particles: _particles),
                  ),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MascotView(mood: MascotMood.cheer, size: 170),
                  SizedBox(height: AppSpacing.lg),
                  Text('well_done'.tr, style: AppTextStyles.display, textAlign: TextAlign.center),
                  SizedBox(height: AppSpacing.md),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                    duration: reduceMotion ? Duration.zero : AppDurations.slow,
                    curve: Curves.elasticOut,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: PlaceholderArt(
                      assetPath: _args.badge.iconAsset,
                      themeColor: themeColor,
                      fallbackIcon: Icons.emoji_events_rounded,
                      size: 120.r,
                      borderRadius: AppRadii.borderPill,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(_args.badge.title.resolve(langCode), style: AppTextStyles.h1, textAlign: TextAlign.center),
                  SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'tuku_den'.tr,
                    icon: Icons.cottage_rounded,
                    color: themeColor,
                    onPressed: () {
                      Get.offAllNamed(AppRoutes.home);
                      Get.toNamed(AppRoutes.den);
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'back_to_map'.tr,
                    icon: Icons.map_rounded,
                    variant: AppButtonVariant.secondary,
                    color: themeColor,
                    onPressed: () => Get.offAllNamed(AppRoutes.home),
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

/// One confetti piece's fixed randomised parameters, generated once so the
/// fall pattern is deterministic across frames.
final class _ConfettiParticle {
  const _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.speed,
    required this.colorIndex,
    required this.size,
  });

  factory _ConfettiParticle.random(Random random) => _ConfettiParticle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.5,
        speed: 0.7 + random.nextDouble() * 0.6,
        colorIndex: random.nextInt(_ConfettiPainter.palette.length),
        size: 6 + random.nextDouble() * 6,
      );

  final double x;
  final double delay;
  final double speed;
  final int colorIndex;
  final double size;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_ConfettiParticle> particles;

  static const List<Color> palette = [
    AppColors.accent,
    AppColors.primary,
    AppColors.success,
    AppColors.flood,
    AppColors.lightning,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final localT = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final dy = localT * particle.speed * size.height;
      final dx = particle.x * size.width + sin(localT * pi * 4) * 12;
      final paint = Paint()
        ..color = palette[particle.colorIndex].withValues(alpha: (1 - localT).clamp(0.2, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(localT * pi * 3);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 1.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
