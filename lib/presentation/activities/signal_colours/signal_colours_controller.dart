import 'dart:math';

import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/result.dart';
import '../../../core/services/narration_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/activity_content.dart';
import '../../../domain/entities/localized_text.dart';
import '../../../domain/entities/signal_info.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';
import '../../widgets/feedback_presenter_mixin.dart';

/// Load state for [SignalColoursController], observed by the Signal
/// Colours page.
enum SignalColoursViewStatus { loading, data, error }

/// Drives the Signal Colours activity: one colour signal at a time, tap the
/// matching meaning from a small set of options. No fail state — a wrong
/// tap is just rejected gently; completion is reached only after every
/// signal has been matched, at which point [CompleteActivity] persists it
/// and awards the activity's badge (once).
class SignalColoursController extends GetxController with FeedbackPresenterMixin {
  SignalColoursController({
    required GetActivity getActivity,
    required CompleteActivity completeActivity,
    required NarrationService narrationService,
    required SoundService soundService,
    required this.activityId,
  })  : _getActivity = getActivity,
        _completeActivity = completeActivity,
        _narrationService = narrationService,
        _soundService = soundService;

  final GetActivity _getActivity;
  final CompleteActivity _completeActivity;
  final NarrationService _narrationService;
  final SoundService _soundService;
  final String activityId;

  @override
  NarrationService get feedbackNarrationService => _narrationService;
  @override
  SoundService get feedbackSoundService => _soundService;

  final Rx<SignalColoursViewStatus> status = SignalColoursViewStatus.loading.obs;
  final Rx<Activity?> activity = Rx<Activity?>(null);
  final RxInt signalIndex = 0.obs;
  final RxBool currentAnsweredCorrectly = false.obs;
  final RxBool isComplete = false.obs;
  final RxBool badgeAwarded = false.obs;
  final RxString errorMessage = ''.obs;

  /// The id of the most recently wrong-tapped option, and a nonce that ticks
  /// on every wrong tap (even repeats of the same option) so the UI can
  /// replay its reject animation each time.
  final Rx<String?> lastWrongOptionId = Rx<String?>(null);
  final RxInt wrongNonce = 0.obs;

  RxBool get isSpeaking => _narrationService.isSpeaking;

  List<SignalInfo> get signals => (activity.value?.content as SignalColoursContent?)?.signals ?? const [];

  SignalInfo get currentSignal => signals[signalIndex.value];

  /// 2–3 meaning options for the signal at [index]: the correct signal plus
  /// distractors drawn from the rest of the pool, in a deterministic order
  /// (seeded by [index]) so the correct answer isn't always in the same
  /// spot without making the game flaky to test.
  List<SignalInfo> optionsFor(int index) {
    final all = signals;
    if (all.length <= 3) {
      return List<SignalInfo>.from(all)..shuffle(Random(index));
    }
    final correct = all[index];
    final distractorPool = [for (var i = 0; i < all.length; i++) if (i != index) all[i]];
    final options = [
      correct,
      distractorPool[index % distractorPool.length],
      distractorPool[(index + 1) % distractorPool.length],
    ];
    return options..shuffle(Random(index));
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    disposeFeedbackPresenter();
    _narrationService.stop();
    super.onClose();
  }

  /// Loads the activity. Exposed publicly so the UI can retry after an
  /// error.
  Future<void> load() async {
    status.value = SignalColoursViewStatus.loading;
    final result = await _getActivity(activityId);
    switch (result) {
      case Success<Activity>(value: final loadedActivity):
        activity.value = loadedActivity;
        signalIndex.value = 0;
        currentAnsweredCorrectly.value = false;
        isComplete.value = false;
        badgeAwarded.value = false;
        status.value = SignalColoursViewStatus.data;
      case Failure<Activity>(failure: final failure):
        AppLogger.error('SignalColoursController failed to load "$activityId": ${failure.message}');
        errorMessage.value = failure.message;
        status.value = SignalColoursViewStatus.error;
    }
  }

  /// Speaks [text] in the current app locale.
  void narrate(LocalizedText text) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    _narrationService.speak(text.resolve(langCode), langCode: langCode);
  }

  void stopNarration() => _narrationService.stop();

  /// Handles tapping [option] as the meaning for the current signal. A
  /// correct tap celebrates (narrated with its affirmation) and advances;
  /// a wrong tap is rejected gently — no penalty, the child can try again.
  Future<void> selectOption(SignalInfo option) async {
    if (currentAnsweredCorrectly.value) return;
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    if (option.id == currentSignal.id) {
      currentAnsweredCorrectly.value = true;
      // Awaited so the next signal (or the completion summary) never
      // replaces the screen before the child has heard the affirmation in
      // full.
      await presentFeedback(
        message: currentSignal.affirmation?.resolve(langCode) ?? 'feedback_generic_correct'.tr,
        isCorrect: true,
      );
      await _advance();
      return;
    }

    lastWrongOptionId.value = option.id;
    wrongNonce.value++;
    presentFeedback(
      message: currentSignal.feedback?.resolve(langCode) ?? 'feedback_generic_wrong'.tr,
      isCorrect: false,
    );
    Future.delayed(AppDurations.normal, () {
      if (lastWrongOptionId.value == option.id) lastWrongOptionId.value = null;
    });
  }

  Future<void> _advance() async {
    if (signalIndex.value == signals.length - 1) {
      await _complete();
      return;
    }
    signalIndex.value++;
    currentAnsweredCorrectly.value = false;
    dismissFeedback();
  }

  Future<void> _complete() async {
    final badge = activity.value?.badge;
    final result = await _completeActivity(activityId: activityId, badge: badge);
    isComplete.value = true;
    _soundService.playComplete();
    switch (result) {
      case Success<bool>(value: final awarded):
        badgeAwarded.value = awarded;
        if (awarded) _soundService.playSticker();
      case Failure<bool>(failure: final failure):
        AppLogger.error('SignalColoursController failed to persist completion: ${failure.message}');
        // Still shown as complete — never trap the child on a persistence
        // hiccup; the save can succeed next time they play.
    }
  }
}
