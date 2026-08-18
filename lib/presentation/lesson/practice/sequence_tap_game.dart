import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/localized_text.dart';
import '../../../domain/entities/practice_config.dart';
import '../../../domain/entities/practice_item.dart';
import '../../widgets/mascot_view.dart';
import '../../widgets/progress_bar.dart';
import '../lesson_runner_callbacks.dart';
import 'practice_game.dart';
import 'practice_tile.dart';

/// Tap targets in the correct order (e.g. Drop → Cover → Hold On). A wrong
/// or early tap just flashes red for a moment — no fail state, no reset,
/// no penalty, the child simply keeps trying.
final class SequenceTapGame implements PracticeGame {
  const SequenceTapGame();

  @override
  Widget build({
    required BuildContext context,
    required PracticeConfig config,
    required Color themeColor,
    required LessonRunnerCallbacks callbacks,
  }) {
    final ordered = [...config.items]..sort((a, b) => (a.sequenceOrder ?? 0).compareTo(b.sequenceOrder ?? 0));
    return _SequenceTapView(
      instructions: config.instructions,
      items: ordered,
      themeColor: themeColor,
      callbacks: callbacks,
    );
  }
}

class _SequenceTapView extends StatefulWidget {
  const _SequenceTapView({
    required this.instructions,
    required this.items,
    required this.themeColor,
    required this.callbacks,
  });

  final LocalizedText instructions;
  final List<PracticeItem> items;
  final Color themeColor;
  final LessonRunnerCallbacks callbacks;

  @override
  State<_SequenceTapView> createState() => _SequenceTapViewState();
}

class _SequenceTapViewState extends State<_SequenceTapView> {
  late final List<PracticeItem> _shuffled = [...widget.items]..shuffle();

  /// 1-based position the child needs to tap next.
  int _nextExpected = 1;
  String? _wrongItemId;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.callbacks.narrate(widget.instructions);
      widget.callbacks.setMascotMood(MascotMood.point);
    });
  }

  void _handleTap(PracticeItem item) {
    if (item.sequenceOrder == _nextExpected) {
      setState(() => _nextExpected++);
      if (_nextExpected > widget.items.length) {
        widget.callbacks.setMascotMood(MascotMood.cheer);
        _celebrateThenFinish();
      }
    } else {
      final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
      widget.callbacks.showFeedback(
        message: item.feedback?.resolve(langCode) ?? 'feedback_generic_wrong'.tr,
        isCorrect: false,
      );
      setState(() {
        _wrongItemId = item.id;
        _showHint = true;
      });
      Future.delayed(AppDurations.normal, () {
        if (mounted) setState(() => _wrongItemId = null);
      });
    }
  }

  /// Waits for the "well done" feedback to finish narrating — never a fixed
  /// guessed delay — before finishing the beat, so the child's narration is
  /// never cut off mid-sentence.
  Future<void> _celebrateThenFinish() async {
    await widget.callbacks.showFeedback(message: 'feedback_generic_correct'.tr, isCorrect: true);
    if (mounted) widget.callbacks.onBeatFinished();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final progress = (_nextExpected - 1) / widget.items.length;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(widget.instructions.resolve(langCode), style: AppTextStyles.h2, textAlign: TextAlign.center),
          SizedBox(height: AppSpacing.md),
          ProgressBar(progress: progress, color: widget.themeColor),
          SizedBox(height: AppSpacing.sm),
          AnimatedOpacity(
            duration: AppDurations.fast,
            opacity: _showHint ? 1 : 0,
            child: Text('retry'.tr, style: AppTextStyles.body.copyWith(color: widget.themeColor)),
          ),
          SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final item in _shuffled)
                  PracticeTile(
                    item: item,
                    themeColor: widget.themeColor,
                    state: (item.sequenceOrder ?? 0) < _nextExpected
                        ? PracticeTileState.correct
                        : (_wrongItemId == item.id ? PracticeTileState.wrong : PracticeTileState.neutral),
                    onTap: (item.sequenceOrder ?? 0) < _nextExpected ? null : () => _handleTap(item),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
