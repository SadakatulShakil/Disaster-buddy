import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/narration_service.dart';
import '../../core/services/sound_service.dart';

/// A resolved message ready to show in a [FeedbackBubble].
final class ActiveFeedback {
  const ActiveFeedback({required this.message, required this.isCorrect});

  final String message;
  final bool isCorrect;
}

/// Shared "kind feedback" behaviour reused by every controller that shows a
/// [FeedbackBubble] — [LessonController] and the three activity
/// controllers: narrates the message and plays the matching correct/wrong
/// sfx. [presentFeedback]'s returned future resolves only once narration
/// has actually finished (never a guessed fixed duration), so a caller that
/// awaits it before advancing never cuts the child's narration off
/// mid-sentence. One implementation instead of one copy per controller
/// keeps the behaviour identical everywhere.
mixin FeedbackPresenterMixin on GetxController {
  NarrationService get feedbackNarrationService;
  SoundService get feedbackSoundService;

  final Rx<ActiveFeedback?> activeFeedback = Rx<ActiveFeedback?>(null);

  /// Ticks on every call so a stale, already-finished [presentFeedback]
  /// call never clears feedback a newer call already replaced.
  int _feedbackGeneration = 0;

  /// Shows the already-locale-resolved [message] as feedback, plays the
  /// matching sfx, and narrates it — then clears itself once narration is
  /// done (or immediately if muted/unavailable). Replaces any feedback
  /// already showing. Await this before advancing to the next
  /// question/item/scene so the child always hears it in full first.
  Future<void> presentFeedback({required String message, required bool isCorrect}) async {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final generation = ++_feedbackGeneration;

    activeFeedback.value = ActiveFeedback(message: message, isCorrect: isCorrect);
    if (isCorrect) {
      feedbackSoundService.playCorrect();
    } else {
      feedbackSoundService.playWrong();
    }

    await feedbackNarrationService.speakAndWaitUntilDone(message, langCode: langCode);

    if (generation == _feedbackGeneration) {
      activeFeedback.value = null;
    }
  }

  /// Hides the current feedback immediately and stops narrating it — e.g.
  /// when the child taps the bubble to skip past it early. Safe to call
  /// even when nothing is showing.
  void dismissFeedback() {
    _feedbackGeneration++;
    activeFeedback.value = null;
    feedbackNarrationService.stop();
  }

  /// Invalidates any in-flight [presentFeedback] call. Call from
  /// `onClose()`.
  void disposeFeedbackPresenter() => _feedbackGeneration++;
}
