import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/result.dart';
import '../../core/services/sound_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/services/narration_service.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/entities/localized_text.dart';
import '../../domain/entities/streak_state.dart';
import '../../domain/services/streak_calculator.dart';
import '../../domain/usecases/get_todays_challenge.dart';
import '../../domain/usecases/mark_challenge_complete.dart';
import '../widgets/feedback_presenter_mixin.dart';

/// Load/interaction state for [DailyChallengeController], observed by
/// [DailyChallengePage].
enum DailyChallengeViewStatus {
  loading,

  /// Today's challenge is loaded and not yet completed — render it via the
  /// matching runner.
  playing,

  /// Just finished today's challenge — show the cheer + updated streak,
  /// then a calm "come back tomorrow".
  celebrating,

  /// Today was already completed before this screen opened — show an
  /// encouraging recap, not the challenge again.
  alreadyDoneToday,

  error,
}

/// Drives the daily-challenge entry point: loads "today's" challenge and
/// streak status, renders the challenge through the existing quiz/practice
/// runners (the page switches on payload type — no interaction logic
/// lives here), and records completion.
class DailyChallengeController extends GetxController with FeedbackPresenterMixin {
  DailyChallengeController({
    required GetTodaysChallenge getTodaysChallenge,
    required MarkChallengeComplete markChallengeComplete,
    required NarrationService narrationService,
    required SoundService soundService,
  })  : _getTodaysChallenge = getTodaysChallenge,
        _markChallengeComplete = markChallengeComplete,
        _narrationService = narrationService,
        _soundService = soundService;

  final GetTodaysChallenge _getTodaysChallenge;
  final MarkChallengeComplete _markChallengeComplete;
  final NarrationService _narrationService;
  final SoundService _soundService;

  @override
  NarrationService get feedbackNarrationService => _narrationService;
  @override
  SoundService get feedbackSoundService => _soundService;

  final Rx<DailyChallengeViewStatus> status = DailyChallengeViewStatus.loading.obs;
  final Rx<DailyChallenge?> challenge = Rx<DailyChallenge?>(null);
  final Rx<StreakState?> streakState = Rx<StreakState?>(null);
  final Rx<int?> newMilestone = Rx<int?>(null);
  final RxString errorMessage = ''.obs;

  RxBool get isSpeaking => _narrationService.isSpeaking;

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

  /// Loads today's challenge and status. Exposed publicly so the UI can
  /// retry after an error.
  Future<void> load() async {
    status.value = DailyChallengeViewStatus.loading;
    final result = await _getTodaysChallenge();
    switch (result) {
      case Success<TodaysChallengeResult>(value: final data):
        challenge.value = data.challenge;
        streakState.value = data.streakState;
        status.value =
            data.alreadyCompletedToday ? DailyChallengeViewStatus.alreadyDoneToday : DailyChallengeViewStatus.playing;
      case Failure<TodaysChallengeResult>(failure: final failure):
        AppLogger.error('DailyChallengeController failed to load: ${failure.message}');
        errorMessage.value = failure.message;
        status.value = DailyChallengeViewStatus.error;
    }
  }

  /// Speaks [text] in the current app locale. Fire-and-forget — narration
  /// failures degrade silently inside the service.
  void narrate(LocalizedText text) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    _narrationService.speak(text.resolve(langCode), langCode: langCode);
  }

  void stopNarration() => _narrationService.stop();

  /// Called by the active runner once the challenge is finished. Records
  /// the completion, advances the streak, and surfaces any newly-reached
  /// milestone for the celebration view.
  Future<void> completeChallenge({required bool wasCorrect}) async {
    final currentChallenge = challenge.value;
    if (currentChallenge == null) return;

    final result = await _markChallengeComplete(challengeId: currentChallenge.id, wasCorrect: wasCorrect);
    switch (result) {
      case Success<StreakUpdate>(value: final update):
        streakState.value = update.state;
        newMilestone.value = update.newMilestone;
        _soundService.playComplete();
        if (update.newMilestone != null) _soundService.playSticker();
        status.value = DailyChallengeViewStatus.celebrating;
      case Failure<StreakUpdate>(failure: final failure):
        AppLogger.error('DailyChallengeController failed to record completion: ${failure.message}');
        errorMessage.value = failure.message;
        status.value = DailyChallengeViewStatus.error;
    }
  }
}
