import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/activity.dart';
import '../../../domain/entities/kit_item.dart';
import '../../../domain/entities/localized_text.dart';
import '../../../core/services/narration_service.dart';
import '../../../domain/usecases/complete_activity.dart';
import '../../../domain/usecases/get_activity.dart';

/// Load state for [KitBuilderController], observed by the Kit Builder page.
enum KitBuilderViewStatus { loading, data, error }

/// Drives the Emergency Kit Builder: a drag-correct-items-into-the-bag
/// activity, fully data-driven from an [Activity] manifest. No fail state —
/// a wrong drop is just rejected gently; completion is reached only by
/// placing every correct item, at which point [CompleteActivity] persists
/// it and awards the activity's badge (once).
class KitBuilderController extends GetxController {
  KitBuilderController({
    required GetActivity getActivity,
    required CompleteActivity completeActivity,
    required NarrationService narrationService,
    required this.activityId,
  })  : _getActivity = getActivity,
        _completeActivity = completeActivity,
        _narrationService = narrationService;

  final GetActivity _getActivity;
  final CompleteActivity _completeActivity;
  final NarrationService _narrationService;
  final String activityId;

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

  int get correctTotal => activity.value?.items.where((item) => item.isCorrect).length ?? 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
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
    if (!item.isCorrect) {
      lastWrongItemId.value = item.id;
      wrongNonce.value++;
      // Matches the practice-game reject-feedback duration elsewhere in the
      // app (SequenceTapGame/TapCorrectChoiceGame) for a consistent feel.
      Future.delayed(AppDurations.normal, () {
        if (lastWrongItemId.value == item.id) lastWrongItemId.value = null;
      });
      return;
    }

    if (packedItemIds.contains(item.id)) return;
    packedItemIds.add(item.id);
    final affirmation = item.affirmation;
    if (affirmation != null) narrate(affirmation);

    if (packedItemIds.length == correctTotal) {
      await _complete();
    }
  }

  Future<void> _complete() async {
    final badge = activity.value?.badge;
    final result = await _completeActivity(activityId: activityId, badge: badge);
    isComplete.value = true;
    switch (result) {
      case Success<bool>(value: final awarded):
        badgeAwarded.value = awarded;
      case Failure<bool>(failure: final failure):
        AppLogger.error('KitBuilderController failed to persist completion: ${failure.message}');
        // The kit is still shown as packed — never trap the child on a
        // persistence hiccup; the save can succeed next time they play.
    }
  }
}
