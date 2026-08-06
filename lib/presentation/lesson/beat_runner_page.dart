import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/beat.dart';
import '../widgets/app_button.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/mascot_view.dart';
import 'lesson_controller.dart';
import 'lesson_runner_callbacks.dart';
import 'widgets/lesson_progress_dots.dart';
import 'widgets/practice_runner.dart';
import 'widgets/quiz_runner.dart';
import 'widgets/slide_player.dart';

/// Single host page for the active beat: dispatches to the right runner by
/// beat type, and provides the consistent in-lesson chrome (progress dots,
/// a confirming close button, the mascot with mood reactions).
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
  final Rx<MascotMood> _mascotMood = MascotMood.idle.obs;

  Color get _themeColor => AppColors.fromHex(widget.controller.module.value!.themeColorHex);

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleLeaveRequest();
      },
      child: AppScaffold(
        appBar: AppBar(
          backgroundColor: themeColor,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _handleLeaveRequest,
          ),
          title: Obx(
            () => LessonProgressDots(
              count: controller.beatCount,
              current: controller.currentBeatIndex.value,
              color: AppColors.textOnPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            SizedBox(height: AppSpacing.sm),
            Obx(() => MascotView(mood: _mascotMood.value, size: 88)),
            Expanded(
              // Reads `controller.currentBeat` (backed by the reactive
              // `currentBeatIndex`), so advancing to the next beat swaps in
              // its runner immediately — without this, the old runner (and
              // its "Done" button bound to the beat it was built for) would
              // stay on screen and silently complete every later beat.
              child: Obx(() {
                final beat = controller.currentBeat;
                final callbacks = LessonRunnerCallbacks(
                  narrate: controller.narrate,
                  stopNarration: controller.stopNarration,
                  isSpeaking: controller.isSpeaking,
                  setMascotMood: (mood) => _mascotMood.value = mood,
                  onBeatFinished: controller.completeCurrentBeat,
                  recordQuizResult: controller.recordQuizResult,
                );

                return switch (beat) {
                  StoryBeat() => SlidePlayer(
                      key: ValueKey(beat.id),
                      slides: beat.slides,
                      themeColor: themeColor,
                      emphasizeSteps: false,
                      callbacks: callbacks,
                    ),
                  StepsBeat() => SlidePlayer(
                      key: ValueKey(beat.id),
                      slides: beat.slides,
                      themeColor: themeColor,
                      emphasizeSteps: true,
                      callbacks: callbacks,
                    ),
                  PracticeBeat() =>
                    PracticeRunner(key: ValueKey(beat.id), beat: beat, themeColor: themeColor, callbacks: callbacks),
                  QuizBeat() =>
                    QuizRunner(key: ValueKey(beat.id), beat: beat, themeColor: themeColor, callbacks: callbacks),
                };
              }),
            ),
          ],
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
