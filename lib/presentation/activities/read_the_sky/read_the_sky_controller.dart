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
import '../../../domain/entities/weather_sign.dart';
import '../../../domain/entities/weather_sign_option.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';
import '../../widgets/feedback_presenter_mixin.dart';

/// Load state for [ReadTheSkyController], observed by the Read the Sky page.
enum ReadTheSkyViewStatus { loading, data, error }

/// Drives the Read the Sky activity: one natural early-warning sign at a
/// time, tap which hazard it warns about from its own 2–3 options. No fail
/// state — a wrong tap is just rejected gently; completion is reached only
/// after every sign has been matched, at which point [CompleteActivity]
/// persists it and awards the activity's badge (once).
class ReadTheSkyController extends GetxController with FeedbackPresenterMixin {
  ReadTheSkyController({
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

  final Rx<ReadTheSkyViewStatus> status = ReadTheSkyViewStatus.loading.obs;
  final Rx<Activity?> activity = Rx<Activity?>(null);
  final RxInt signIndex = 0.obs;
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

  List<WeatherSign> get signs => (activity.value?.content as ReadTheSkyContent?)?.signs ?? const [];

  WeatherSign get currentSign => signs[signIndex.value];

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
    status.value = ReadTheSkyViewStatus.loading;
    final result = await _getActivity(activityId);
    switch (result) {
      case Success<Activity>(value: final loadedActivity):
        activity.value = loadedActivity;
        signIndex.value = 0;
        currentAnsweredCorrectly.value = false;
        isComplete.value = false;
        badgeAwarded.value = false;
        status.value = ReadTheSkyViewStatus.data;
      case Failure<Activity>(failure: final failure):
        AppLogger.error('ReadTheSkyController failed to load "$activityId": ${failure.message}');
        errorMessage.value = failure.message;
        status.value = ReadTheSkyViewStatus.error;
    }
  }

  /// Speaks [text] in the current app locale.
  void narrate(LocalizedText text) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    _narrationService.speak(text.resolve(langCode), langCode: langCode);
  }

  void stopNarration() => _narrationService.stop();

  /// Handles tapping [option] as the hazard the current sign warns about. A
  /// correct tap celebrates (the sign's hazard confirmed, then the
  /// "tell a grown-up" action reinforced) and advances; a wrong tap is
  /// rejected gently — no penalty, the child can try again.
  Future<void> selectOption(WeatherSignOption option) async {
    if (currentAnsweredCorrectly.value) return;
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final sign = currentSign;

    if (option.isCorrect) {
      currentAnsweredCorrectly.value = true;
      // Awaited so the next sign (or the completion summary) never replaces
      // the screen before the child has heard the confirmation and safety
      // reinforcement in full.
      await presentFeedback(
        message: '${sign.correctHazard.resolve(langCode)} ${sign.action.resolve(langCode)}',
        isCorrect: true,
      );
      await _advance();
      return;
    }

    lastWrongOptionId.value = option.id;
    wrongNonce.value++;
    presentFeedback(message: sign.feedback.resolve(langCode), isCorrect: false);
    Future.delayed(AppDurations.normal, () {
      if (lastWrongOptionId.value == option.id) lastWrongOptionId.value = null;
    });
  }

  Future<void> _advance() async {
    if (signIndex.value == signs.length - 1) {
      await _complete();
      return;
    }
    signIndex.value++;
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
        AppLogger.error('ReadTheSkyController failed to persist completion: ${failure.message}');
      // Still shown as complete — never trap the child on a persistence
      // hiccup; the save can succeed next time they play.
    }
  }
}
