import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/beat.dart';
import '../widgets/app_button.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/feedback_bubble.dart';
import '../widgets/mascot_view.dart';
import 'beat_intro.dart';
import 'lesson_controller.dart';
import 'lesson_runner_callbacks.dart';
import 'widgets/beat_type_header.dart';
import 'widgets/practice_runner.dart';
import 'widgets/quiz_runner.dart';
import 'widgets/slide_player.dart';

/// Single host page for the active beat: dispatches to the right runner by
/// beat type, and provides the consistent in-lesson chrome (type header,
/// a confirming close button, the mascot with mood reactions, and the
/// shared feedback bubble).
class BeatRunnerPage extends GetView<LessonController> {
  const BeatRunnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case LessonViewStatus.loading:
          return const AppScaffold(body: AppLoader());
        case LessonViewStatus.error:
          return AppScaffold(
            body: AppErrorView(message: controller.errorMessage.value, onRetry: controller.load),
          );
        case LessonViewStatus.data:
          return _LessonBody(controller: controller);
      }
    });
  }
}

class _LessonBody extends StatefulWidget {
  const _LessonBody({required this.controller});

  final LessonController controller;

  @override
  State<_LessonBody> createState() => _LessonBodyState();
}

class _LessonBodyState extends State<_LessonBody> {
  late final Rx<MascotMood> _mascotMood = beatIntroMood(widget.controller.currentBeat).obs;

  /// A brief, skippable "Story time!"-style cue shown before the beat's own
  /// runner mounts — kept as a separate phase (rather than overlaying the
  /// runner) so the runner's own on-mount narration never collides with the
  /// intro's.
  bool _showIntro = true;

  Color get _themeColor => AppColors.fromHex(widget.controller.module.value!.themeColorHex);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runIntro());
  }

  /// Narrates the intro cue and waits for it to actually finish — never a
  /// guessed fixed duration — then dismisses. [AppDurations.beatIntroHold]
  /// is only a calm minimum so the cue isn't a instant flash when muted; it
  /// never cuts the narration itself short if that runs longer.
  Future<void> _runIntro() async {
    final beat = widget.controller.currentBeat;
    await Future.wait([
      widget.controller.narrateBeatIntro(beat),
      Future.delayed(AppDurations.beatIntroHold),
    ]);
    _dismissIntro();
  }

  void _dismissIntro() {
    if (!mounted || !_showIntro) return;
    widget.controller.stopNarration();
    setState(() => _showIntro = false);
  }

  Future<void> _handleLeaveRequest() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => _LeaveLessonDialog(themeColor: _themeColor),
    );
    if (shouldLeave ?? false) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final themeColor = _themeColor;
    final beat = controller.currentBeat;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLeaveRequest();
      },
      child: AppScaffold(
        showSkyDecoration: true,
        appBar: AppBar(
          backgroundColor: themeColor,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _handleLeaveRequest,
          ),
        ),
        body: Column(
          children: [
            SizedBox(height: AppSpacing.sm),
            BeatTypeHeader(
              beat: beat,
              current: controller.currentBeatIndex.value,
              total: controller.beatCount,
              color: themeColor,
            ),
            SizedBox(height: AppSpacing.sm),
            Obx(() => MascotView(mood: _mascotMood.value, size: 88)),
            Expanded(
              child: _showIntro
                  ? _BeatIntroCue(beat: beat, themeColor: themeColor, onSkip: _dismissIntro)
                  : Stack(
                      children: [
                        _BeatRunnerHost(
                          beat: beat,
                          themeColor: themeColor,
                          controller: controller,
                          setMascotMood: (mood) => _mascotMood.value = mood,
                        ),
                        Obx(() {
                          final feedback = controller.activeFeedback.value;
                          if (feedback == null) return const SizedBox.shrink();
                          return Positioned(
                            left: AppSpacing.md,
                            right: AppSpacing.md,
                            bottom: AppSpacing.md,
                            child: FeedbackBubble(
                              message: feedback.message,
                              isCorrect: feedback.isCorrect,
                              onTap: controller.dismissFeedback,
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hosts the beat's own runner, given the intro cue has already played.
/// Kept as its own widget (rather than inline) so it only builds — and only
/// starts its own on-mount narration — once the intro phase ends.
class _BeatRunnerHost extends StatelessWidget {
  const _BeatRunnerHost({
    required this.beat,
    required this.themeColor,
    required this.controller,
    required this.setMascotMood,
  });

  final Beat beat;
  final Color themeColor;
  final LessonController controller;
  final void Function(MascotMood mood) setMascotMood;

  @override
  Widget build(BuildContext context) {
    final callbacks = LessonRunnerCallbacks(
      narrate: controller.narrate,
      stopNarration: controller.stopNarration,
      isSpeaking: controller.isSpeaking,
      setMascotMood: setMascotMood,
      onBeatFinished: controller.completeCurrentBeat,
      recordQuizResult: controller.recordQuizResult,
      showFeedback: ({required message, required isCorrect}) =>
          controller.presentFeedback(message: message, isCorrect: isCorrect),
      clearFeedback: controller.dismissFeedback,
    );

    // Bound to a local so the switch patterns below can promote its type —
    // an instance field (`this.beat`) isn't promotable.
    final currentBeat = beat;
    return switch (currentBeat) {
      StoryBeat() => SlidePlayer(
          key: ValueKey(currentBeat.id),
          slides: currentBeat.slides,
          themeColor: themeColor,
          emphasizeSteps: false,
          callbacks: callbacks,
        ),
      StepsBeat() => SlidePlayer(
          key: ValueKey(currentBeat.id),
          slides: currentBeat.slides,
          themeColor: themeColor,
          emphasizeSteps: true,
          callbacks: callbacks,
        ),
      PracticeBeat() =>
        PracticeRunner(key: ValueKey(currentBeat.id), beat: currentBeat, themeColor: themeColor, callbacks: callbacks),
      QuizBeat() =>
        QuizRunner(key: ValueKey(currentBeat.id), beat: currentBeat, themeColor: themeColor, callbacks: callbacks),
    };
  }
}

/// The brief "Story time!"-style intro moment: big, calm, and tappable to
/// skip right away.
class _BeatIntroCue extends StatelessWidget {
  const _BeatIntroCue({required this.beat, required this.themeColor, required this.onSkip});

  final Beat beat;
  final Color themeColor;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: beatIntroTrKey(beat).tr,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSkip,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  beatIntroTrKey(beat).tr,
                  style: AppTextStyles.display.copyWith(color: themeColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text('skip'.tr, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveLessonDialog extends StatelessWidget {
  const _LeaveLessonDialog({required this.themeColor});

  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('leave_lesson_prompt'.tr, style: AppTextStyles.body, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'stay'.tr,
                    variant: AppButtonVariant.secondary,
                    color: themeColor,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'leave'.tr,
                    color: themeColor,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
