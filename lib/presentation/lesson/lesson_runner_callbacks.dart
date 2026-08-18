import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/entities/localized_text.dart';
import '../widgets/mascot_view.dart';

/// Everything a beat-runner widget (SlidePlayer, PracticeRunner, QuizRunner)
/// needs from the hosting lesson, bundled into one object so runners stay
/// decoupled from `LessonController`/GetX and are easy to test in isolation.
final class LessonRunnerCallbacks {
  const LessonRunnerCallbacks({
    required this.narrate,
    required this.stopNarration,
    required this.isSpeaking,
    required this.setMascotMood,
    required this.onBeatFinished,
    required this.recordQuizResult,
    required this.showFeedback,
    required this.clearFeedback,
  });

  /// Speaks [text] in the current locale. Silently no-ops if muted or TTS
  /// is unavailable.
  final void Function(LocalizedText text) narrate;

  /// Stops any narration in progress.
  final VoidCallback stopNarration;

  /// Whether narration is currently playing.
  final RxBool isSpeaking;

  /// Updates the mascot's mood shown in the lesson chrome.
  final void Function(MascotMood mood) setMascotMood;

  /// Call once the current beat is fully done. Advances the lesson (or, for
  /// a replay, returns to ModuleHome).
  final VoidCallback onBeatFinished;

  /// Quiz-only: persists the aggregate score before [onBeatFinished].
  final Future<void> Function({required String quizId, required int correct, required int total}) recordQuizResult;

  /// Shows the shared [FeedbackBubble] with an already-resolved [message],
  /// narrated and paired with the matching correct/wrong sfx. The returned
  /// future resolves only once narration actually finishes — await it
  /// before advancing so the child's narration is never cut off.
  final Future<void> Function({required String message, required bool isCorrect}) showFeedback;

  /// Hides the feedback bubble immediately, e.g. when moving to the next
  /// question/item so a stale bubble never lingers into it.
  final VoidCallback clearFeedback;
}
