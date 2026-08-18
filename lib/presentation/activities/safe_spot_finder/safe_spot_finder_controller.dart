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
import '../../../domain/entities/safe_spot_hotspot.dart';
import '../../../domain/entities/safe_spot_scene.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';
import '../../widgets/feedback_presenter_mixin.dart';

/// Load state for [SafeSpotFinderController], observed by the Safe Spot
/// Finder page.
enum SafeSpotFinderViewStatus { loading, data, error }

/// Whether a tapped hotspot was a safe spot, an already-found safe spot
/// (no-op), or an unsafe spot — the page uses this to react (mascot mood)
/// without re-deriving it itself.
enum SafeSpotTapOutcome { newlySafe, alreadyFound, unsafe }

/// Drives the Safe Spot Finder activity: tap every safe spot in each
/// illustrated scene. No fail state — tapping an unsafe spot just shows a
/// kind explanation; a scene completes once every safe spot in it has been
/// found, and the whole activity completes after its last scene, at which
/// point [CompleteActivity] persists it and awards the activity's badge
/// (once).
class SafeSpotFinderController extends GetxController with FeedbackPresenterMixin {
  SafeSpotFinderController({
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

  final Rx<SafeSpotFinderViewStatus> status = SafeSpotFinderViewStatus.loading.obs;
  final Rx<Activity?> activity = Rx<Activity?>(null);
  final RxInt sceneIndex = 0.obs;
  final RxSet<String> foundSafeIds = <String>{}.obs;
  final RxBool isComplete = false.obs;
  final RxBool badgeAwarded = false.obs;
  final RxString errorMessage = ''.obs;

  /// The most recently tapped unsafe spot, and a nonce that ticks on every
  /// unsafe tap (even repeats) so the UI can replay a brief reject flash.
  final Rx<String?> lastUnsafeSpotId = Rx<String?>(null);
  final RxInt unsafeNonce = 0.obs;

  RxBool get isSpeaking => _narrationService.isSpeaking;

  List<SafeSpotScene> get scenes => (activity.value?.content as SafeSpotContent?)?.scenes ?? const [];

  SafeSpotScene get currentScene => scenes[sceneIndex.value];

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
    status.value = SafeSpotFinderViewStatus.loading;
    final result = await _getActivity(activityId);
    switch (result) {
      case Success<Activity>(value: final loadedActivity):
        activity.value = loadedActivity;
        sceneIndex.value = 0;
        foundSafeIds.clear();
        isComplete.value = false;
        badgeAwarded.value = false;
        status.value = SafeSpotFinderViewStatus.data;
      case Failure<Activity>(failure: final failure):
        AppLogger.error('SafeSpotFinderController failed to load "$activityId": ${failure.message}');
        errorMessage.value = failure.message;
        status.value = SafeSpotFinderViewStatus.error;
    }
  }

  /// Speaks [text] in the current app locale.
  void narrate(LocalizedText text) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    _narrationService.speak(text.resolve(langCode), langCode: langCode);
  }

  void stopNarration() => _narrationService.stop();

  /// Handles tapping [spot]. A safe spot is marked found (narrated with its
  /// feedback) and the scene/activity advances once every safe spot in the
  /// current scene has been found; an unsafe spot just shows/narrates its
  /// kind explanation — no penalty, it can be tapped again.
  Future<SafeSpotTapOutcome> handleTap(SafeSpotHotspot spot) async {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    if (!spot.isSafe) {
      lastUnsafeSpotId.value = spot.id;
      unsafeNonce.value++;
      presentFeedback(message: spot.feedback.resolve(langCode), isCorrect: false);
      Future.delayed(AppDurations.normal, () {
        if (lastUnsafeSpotId.value == spot.id) lastUnsafeSpotId.value = null;
      });
      return SafeSpotTapOutcome.unsafe;
    }

    if (foundSafeIds.contains(spot.id)) return SafeSpotTapOutcome.alreadyFound;

    foundSafeIds.add(spot.id);
    // Awaited so the next scene (or the completion summary) never replaces
    // the screen before the child has heard this spot's feedback in full.
    await presentFeedback(message: spot.feedback.resolve(langCode), isCorrect: true);

    if (foundSafeIds.length == currentScene.safeSpotCount) {
      await _advanceScene();
    }
    return SafeSpotTapOutcome.newlySafe;
  }

  Future<void> _advanceScene() async {
    if (sceneIndex.value == scenes.length - 1) {
      await _complete();
      return;
    }
    sceneIndex.value++;
    foundSafeIds.clear();
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
        AppLogger.error('SafeSpotFinderController failed to persist completion: ${failure.message}');
        // Still shown as complete — never trap the child on a persistence
        // hiccup; the save can succeed next time they play.
    }
  }
}
