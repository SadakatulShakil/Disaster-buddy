import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/result.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/activity_content.dart';
import '../../../domain/entities/kit_item.dart';
import '../../../domain/entities/localized_text.dart';
import '../../../core/services/narration_service.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';
import '../../widgets/feedback_presenter_mixin.dart';

/// Load state for [KitBuilderController], observed by the Kit Builder page.
enum KitBuilderViewStatus { loading, data, error }

/// Drives the Emergency Kit Builder: a drag-correct-items-into-the-bag
/// activity, fully data-driven from an [Activity] manifest. No fail state —
/// a wrong drop is just rejected gently; completion is reached only by
/// placing every correct item, at which point [CompleteActivity] persists
/// it and awards the activity's badge (once).
class KitBuilderController extends GetxController with FeedbackPresenterMixin {
  KitBuilderController({
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

  final Rx<KitBuilderViewStatus> status = KitBuilderViewStatus.loading.obs;
  final Rx<Activity?> activity = Rx<Activity?>(null);
  final RxSet<String> packedItemIds = <String>{}.obs;
  final RxBool isComplete = false.obs;
  final RxBool badgeAwarded = false.obs;
  final RxString errorMessage = ''.obs;

  /// The id of the most recently wrong-dropped item, and a nonce that ticks
  /// on every wrong drop (even repeats of the same item) so the UI can
  /// replay its reject animation each time. Cleared automatically shortly
  /// after, matching the practice-game reject feedback elsewhere in the app.
  final Rx<String?> lastWrongItemId = Rx<String?>(null);
  final RxInt wrongNonce = 0.obs;

  RxBool get isSpeaking => _narrationService.isSpeaking;

  List<KitItem> get items => (activity.value?.content as KitBuilderContent?)?.items ?? const [];

  int get correctTotal => items.where((item) => item.isCorrect).length;

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
    status.value = KitBuilderViewStatus.loading;
    final result = await _getActivity(activityId);
    switch (result) {
      case Success<Activity>(value: final loadedActivity):
        activity.value = loadedActivity;
        packedItemIds.clear();
        isComplete.value = false;
        badgeAwarded.value = false;
        status.value = KitBuilderViewStatus.data;
      case Failure<Activity>(failure: final failure):
        AppLogger.error('KitBuilderController failed to load "$activityId": ${failure.message}');
        errorMessage.value = failure.message;
        status.value = KitBuilderViewStatus.error;
    }
  }

  /// Speaks [text] in the current app locale.
  void narrate(LocalizedText text) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    _narrationService.speak(text.resolve(langCode), langCode: langCode);
  }

  void stopNarration() => _narrationService.stop();

  /// Handles dropping [item] into the go-bag. A correct item snaps in
  /// (narrated with its affirmation) and is removed from the pool; a wrong
  /// item is rejected gently — no penalty, it stays in the pool to try
  /// again. Returns a future so tests can await the persistence/badge work
  /// that follows the final correct item; the UI drop callback fires this
  /// and forgets it.
  Future<void> handleDrop(KitItem item) async {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    if (!item.isCorrect) {
      lastWrongItemId.value = item.id;
      wrongNonce.value++;
      presentFeedback(
        message: item.feedback?.resolve(langCode) ?? 'feedback_generic_wrong'.tr,
        isCorrect: false,
      );
      // Matches the practice-game reject-feedback duration elsewhere in the
      // app (SequenceTapGame/TapCorrectChoiceGame) for a consistent feel.
      Future.delayed(AppDurations.normal, () {
        if (lastWrongItemId.value == item.id) lastWrongItemId.value = null;
      });
      return;
    }

    if (packedItemIds.contains(item.id)) return;
    packedItemIds.add(item.id);
    // Awaited so the completion summary never replaces the screen before
    // the child has heard this item's affirmation in full.
    await presentFeedback(
      message: item.affirmation?.resolve(langCode) ?? 'feedback_generic_correct'.tr,
      isCorrect: true,
    );

    if (packedItemIds.length == correctTotal) {
      await _complete();
    }
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
        AppLogger.error('KitBuilderController failed to persist completion: ${failure.message}');
        // The kit is still shown as packed — never trap the child on a
        // persistence hiccup; the save can succeed next time they play.
    }
  }
}
