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

/// Tap every correct option in a simple scene (e.g. the higher rooftop, not
/// the flooded street). Tapping a wrong option just flashes red for a
/// moment — no penalty, no lockout, the child can keep tapping until every
/// correct option has been found.
final class TapCorrectChoiceGame implements PracticeGame {
  const TapCorrectChoiceGame();

  @override
  Widget build({
    required BuildContext context,
    required PracticeConfig config,
    required Color themeColor,
    required LessonRunnerCallbacks callbacks,
  }) {
    return _TapCorrectChoiceView(
      instructions: config.instructions,
      items: config.items,
      themeColor: themeColor,
      callbacks: callbacks,
    );
  }
}

class _TapCorrectChoiceView extends StatefulWidget {
  const _TapCorrectChoiceView({
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
  State<_TapCorrectChoiceView> createState() => _TapCorrectChoiceViewState();
}

class _TapCorrectChoiceViewState extends State<_TapCorrectChoiceView> {
  final Set<String> _tappedCorrectIds = {};
  String? _wrongItemId;
  bool _showHint = false;

  int get _correctTotal => widget.items.where((item) => item.isCorrect).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.callbacks.narrate(widget.instructions);
      widget.callbacks.setMascotMood(MascotMood.point);
    });
  }

  void _handleTap(PracticeItem item) {
    if (_tappedCorrectIds.contains(item.id)) return;

    if (item.isCorrect) {
      setState(() => _tappedCorrectIds.add(item.id));
      if (_tappedCorrectIds.length == _correctTotal) {
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
    final progress = _correctTotal == 0 ? 0.0 : _tappedCorrectIds.length / _correctTotal;

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
                for (final item in widget.items)
                  PracticeTile(
                    item: item,
                    themeColor: widget.themeColor,
                    state: _tappedCorrectIds.contains(item.id)
                        ? PracticeTileState.correct
                        : (_wrongItemId == item.id ? PracticeTileState.wrong : PracticeTileState.neutral),
                    onTap: _tappedCorrectIds.contains(item.id) ? null : () => _handleTap(item),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
