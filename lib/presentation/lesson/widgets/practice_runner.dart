import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/beat.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_view.dart';
import '../practice/practice_game_registry.dart';
import '../lesson_runner_callbacks.dart';

/// Hosts a [PracticeBeat]'s mini-game, looked up by its `gameId` in
/// [PracticeGameRegistry]. An unknown id never crashes — it logs once and
/// shows a friendly fallback that still lets the child continue.
class PracticeRunner extends StatelessWidget {
  const PracticeRunner({
    super.key,
    required this.beat,
    required this.themeColor,
    required this.callbacks,
  });

  final PracticeBeat beat;
  final Color themeColor;
  final LessonRunnerCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final game = PracticeGameRegistry.find(beat.gameId);
    if (game == null) {
      AppLogger.error('Unknown practice game id "${beat.gameId}" for beat "${beat.id}"');
      return _UnknownGameFallback(onContinue: callbacks.onBeatFinished);
    }
    return game.build(context: context, config: beat.config, themeColor: themeColor, callbacks: callbacks);
  }
}

class _UnknownGameFallback extends StatelessWidget {
  const _UnknownGameFallback({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AppEmptyView(
              title: 'coming_soon_title'.tr,
              subtitle: 'coming_soon_body'.tr,
              icon: Icons.extension_rounded,
            ),
          ),
          AppButton(label: 'next'.tr, icon: Icons.arrow_forward_rounded, onPressed: onContinue),
        ],
      ),
    );
  }
}
