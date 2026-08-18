import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/beat.dart';
import '../../../domain/entities/quiz_option.dart';
import '../../../domain/entities/quiz_question.dart';
import '../../widgets/mascot_view.dart' show MascotMood;
import '../../widgets/placeholder_art.dart';
import '../lesson_runner_callbacks.dart';

/// Runs a [QuizBeat] question by question: localized, narrated prompts and
/// 2–4 picture/label options. A correct tap celebrates and moves on; a
/// wrong tap gently prompts a retry with no penalty and no way to get
/// stuck. The aggregate first-try score is persisted via
/// [LessonRunnerCallbacks.recordQuizResult] once every question is done —
/// completing the quiz always completes the beat, regardless of score.
class QuizRunner extends StatefulWidget {
  const QuizRunner({super.key, required this.beat, required this.themeColor, required this.callbacks});

  final QuizBeat beat;
  final Color themeColor;
  final LessonRunnerCallbacks callbacks;

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner> {
  int _questionIndex = 0;
  int _firstTryCorrectCount = 0;
  bool _attemptedCurrent = false;
  bool _currentAnsweredCorrectly = false;
  String? _wrongOptionId;

  QuizQuestion get _question => widget.beat.questions[_questionIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _narrateCurrent());
  }

  @override
  void dispose() {
    widget.callbacks.stopNarration();
    super.dispose();
  }

  void _narrateCurrent() {
    widget.callbacks.narrate(_question.prompt);
    widget.callbacks.setMascotMood(MascotMood.think);
  }

  void _selectOption(QuizOption option) {
    if (_currentAnsweredCorrectly) return;
    final isFirstAttempt = !_attemptedCurrent;
    _attemptedCurrent = true;
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    if (option.isCorrect) {
      if (isFirstAttempt) _firstTryCorrectCount++;
      widget.callbacks.setMascotMood(MascotMood.cheer);
      setState(() => _currentAnsweredCorrectly = true);
      _celebrateThenAdvance(option, langCode);
    } else {
      widget.callbacks.showFeedback(
        message: option.feedback?.resolve(langCode) ?? 'feedback_generic_wrong'.tr,
        isCorrect: false,
      );
      setState(() => _wrongOptionId = option.id);
      Future.delayed(AppDurations.normal, () {
        if (mounted) setState(() => _wrongOptionId = null);
      });
    }
  }

  /// Waits for the "well done" feedback to finish narrating — never a fixed
  /// guessed delay — before moving to the next question, so the child's
  /// narration is never cut off mid-sentence.
  Future<void> _celebrateThenAdvance(QuizOption option, String langCode) async {
    await widget.callbacks.showFeedback(
      message: option.feedback?.resolve(langCode) ?? 'feedback_generic_correct'.tr,
      isCorrect: true,
    );
    if (!mounted) return;
    await _advance();
  }

  Future<void> _advance() async {
    if (!mounted) return;
    widget.callbacks.clearFeedback();
    if (_questionIndex == widget.beat.questions.length - 1) {
      await widget.callbacks.recordQuizResult(
        quizId: widget.beat.id,
        correct: _firstTryCorrectCount,
        total: widget.beat.questions.length,
      );
      widget.callbacks.onBeatFinished();
    } else {
      setState(() {
        _questionIndex++;
        _attemptedCurrent = false;
        _currentAnsweredCorrectly = false;
      });
      _narrateCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final question = _question;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'quiz_progress'.trParams({
              'current': '${_questionIndex + 1}',
              'total': '${widget.beat.questions.length}',
            }),
            style: AppTextStyles.caption,
          ),
          SizedBox(height: AppSpacing.md),
          if (question.imageAsset != null) ...[
            PlaceholderArt(
              assetPath: question.imageAsset!,
              themeColor: widget.themeColor,
              fallbackIcon: Icons.quiz_rounded,
              size: 180.r,
              borderRadius: AppRadii.borderLg,
            ),
            SizedBox(height: AppSpacing.lg),
          ],
          Text(question.prompt.resolve(langCode), style: AppTextStyles.h2, textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final option in question.options)
                _OptionTile(
                  option: option,
                  themeColor: widget.themeColor,
                  isCorrectReveal: _currentAnsweredCorrectly && option.isCorrect,
                  isWrongReveal: _wrongOptionId == option.id,
                  onTap: () => _selectOption(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.themeColor,
    required this.isCorrectReveal,
    required this.isWrongReveal,
    required this.onTap,
  });

  final QuizOption option;
  final Color themeColor;
  final bool isCorrectReveal;
  final bool isWrongReveal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final label = option.label.resolve(langCode);
    final tint = isCorrectReveal
        ? AppColors.success
        : isWrongReveal
            ? AppColors.error
            : themeColor;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: BoxConstraints(minWidth: 120.r, minHeight: 120.r),
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: isCorrectReveal || isWrongReveal ? 0.18 : 0.08),
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: tint, width: isCorrectReveal || isWrongReveal ? 3 : 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.imageAsset != null)
                PlaceholderArt(
                  assetPath: option.imageAsset!,
                  themeColor: tint,
                  fallbackIcon: Icons.touch_app_rounded,
                  size: 64.r,
                  borderRadius: AppRadii.borderMd,
                ),
              SizedBox(height: AppSpacing.xs),
              Text(label, style: AppTextStyles.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
