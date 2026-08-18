import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/beat.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/entities/streak_state.dart';
import '../../domain/services/streak_milestones.dart';
import '../lesson/lesson_runner_callbacks.dart';
import '../lesson/widgets/practice_runner.dart';
import '../lesson/widgets/quiz_runner.dart';
import '../widgets/app_button.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/feedback_bubble.dart';
import '../widgets/mascot_view.dart';
import '../widgets/placeholder_art.dart';
import '../widgets/streak_chip.dart';
import 'daily_challenge_controller.dart';

/// Hosts today's daily challenge, rendered entirely through the existing
/// Phase 3 runners ([QuizRunner]/[PracticeRunner]) — this page adds no new
/// interaction widgets, only the chrome around them.
class DailyChallengePage extends GetView<DailyChallengeController> {
  const DailyChallengePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showSkyDecoration: true,
      statusBarStyle: SystemUiOverlayStyle.light,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Get.back()),
        title: Text('daily_challenge_title'.tr),
      ),
      body: Obx(() {
        switch (controller.status.value) {
          case DailyChallengeViewStatus.loading:
            return const AppLoader();
          case DailyChallengeViewStatus.error:
            return AppErrorView(message: controller.errorMessage.value, onRetry: controller.load);
          case DailyChallengeViewStatus.alreadyDoneToday:
            return _AlreadyDoneToday(streak: controller.streakState.value);
          case DailyChallengeViewStatus.playing:
            return _DailyChallengeRunner(controller: controller);
          case DailyChallengeViewStatus.celebrating:
            return _DailyChallengeCelebration(controller: controller);
        }
      }),
    );
  }
}

class _DailyChallengeRunner extends StatefulWidget {
  const _DailyChallengeRunner({required this.controller});

  final DailyChallengeController controller;

  @override
  State<_DailyChallengeRunner> createState() => _DailyChallengeRunnerState();
}

class _DailyChallengeRunnerState extends State<_DailyChallengeRunner> {
  final Rx<MascotMood> _mascotMood = MascotMood.idle.obs;

  @override
  Widget build(BuildContext context) {
    final challenge = widget.controller.challenge.value!;
    final callbacks = LessonRunnerCallbacks(
      narrate: widget.controller.narrate,
      stopNarration: widget.controller.stopNarration,
      isSpeaking: widget.controller.isSpeaking,
      setMascotMood: (mood) => _mascotMood.value = mood,
      onBeatFinished: () {
        // Practice-style challenges have no correct/incorrect score of
        // their own — reaching "finished" means every correct item was
        // found, since the runner never lets the child move on otherwise.
        if (challenge.payload is PracticeChallengePayload) {
          widget.controller.completeChallenge(wasCorrect: true);
        }
      },
      recordQuizResult: ({required quizId, required correct, required total}) =>
          widget.controller.completeChallenge(wasCorrect: correct >= total),
      showFeedback: ({required message, required isCorrect}) =>
          widget.controller.presentFeedback(message: message, isCorrect: isCorrect),
      clearFeedback: widget.controller.dismissFeedback,
    );

    return Column(
      children: [
        SizedBox(height: AppSpacing.sm),
        Obx(() => MascotView(mood: _mascotMood.value, size: 88)),
        Expanded(
          child: Stack(
            children: [
              switch (challenge.payload) {
                QuizChallengePayload(:final question) => QuizRunner(
                    key: ValueKey(challenge.id),
                    beat: QuizBeat(id: challenge.id, order: 0, questions: [question]),
                    themeColor: AppColors.accent,
                    callbacks: callbacks,
                  ),
                PracticeChallengePayload(:final gameId, :final config) => PracticeRunner(
                    key: ValueKey(challenge.id),
                    beat: PracticeBeat(id: challenge.id, order: 0, gameId: gameId, config: config),
                    themeColor: AppColors.accent,
                    callbacks: callbacks,
                  ),
              },
              Obx(() {
                final feedback = widget.controller.activeFeedback.value;
                if (feedback == null) return const SizedBox.shrink();
                return Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: FeedbackBubble(
                    message: feedback.message,
                    isCorrect: feedback.isCorrect,
                    onTap: widget.controller.dismissFeedback,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlreadyDoneToday extends StatelessWidget {
  const _AlreadyDoneToday({required this.streak});

  final StreakState? streak;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotView(mood: MascotMood.happy, size: 170),
            SizedBox(height: AppSpacing.lg),
            Text('daily_challenge_done_title'.tr, style: AppTextStyles.display, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text(
              'daily_challenge_come_back_tomorrow'.tr,
              style: AppTextStyles.bodyGrey,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            if (streak != null) StreakChip(streak: streak!),
            SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'view_streak'.tr,
              icon: Icons.local_fire_department_rounded,
              color: AppColors.accent,
              onPressed: () => Get.toNamed(AppRoutes.streakChain),
            ),
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'back_to_map'.tr,
              variant: AppButtonVariant.secondary,
              color: AppColors.accent,
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyChallengeCelebration extends StatelessWidget {
  const _DailyChallengeCelebration({required this.controller});

  final DailyChallengeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streak = controller.streakState.value;
      final milestone = controller.newMilestone.value;
      final badge = milestone != null ? StreakMilestones.badgeFor(milestone) : null;
      final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MascotView(mood: MascotMood.cheer, size: 170),
                SizedBox(height: AppSpacing.lg),
                Text('well_done'.tr, style: AppTextStyles.display, textAlign: TextAlign.center),
                SizedBox(height: AppSpacing.md),
                if (streak != null) StreakChip(streak: streak),
                if (badge != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  PlaceholderArt(
                    assetPath: badge.iconAsset,
                    themeColor: AppColors.accent,
                    fallbackIcon: Icons.local_fire_department_rounded,
                    size: 100.r,
                    borderRadius: AppRadii.borderPill,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(badge.title.resolve(langCode), style: AppTextStyles.h2, textAlign: TextAlign.center),
                ],
                SizedBox(height: AppSpacing.lg),
                Text(
                  'daily_challenge_come_back_tomorrow'.tr,
                  style: AppTextStyles.bodyGrey,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xl),
                if (badge != null) ...[
                  AppButton(
                    label: 'tuku_den'.tr,
                    icon: Icons.cottage_rounded,
                    color: AppColors.accent,
                    onPressed: () {
                      Get.offNamed(AppRoutes.home);
                      Get.toNamed(AppRoutes.den);
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
                AppButton(
                  label: 'back_to_map'.tr,
                  icon: Icons.map_rounded,
                  variant: badge != null ? AppButtonVariant.secondary : AppButtonVariant.primary,
                  color: AppColors.accent,
                  onPressed: () => Get.offNamed(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
