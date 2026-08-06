import 'package:flutter/material.dart';

import '../../../domain/entities/practice_config.dart';
import '../lesson_runner_callbacks.dart';

/// Contract every registered practice mini-game implements.
///
/// `PracticeRunner` looks a game up by the manifest's `PracticeBeat.gameId`
/// via `PracticeGameRegistry` and calls [build] with the beat's generic
/// [PracticeConfig] — each implementation parses [config] into whatever
/// shape it needs (see `PracticeItem.isCorrect`/`sequenceOrder`). New games
/// are added purely by registering another [PracticeGame]; the runner never
/// changes.
abstract interface class PracticeGame {
  Widget build({
    required BuildContext context,
    required PracticeConfig config,
    required Color themeColor,
    required LessonRunnerCallbacks callbacks,
  });
}
