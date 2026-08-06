import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/result.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/narration_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/beat.dart';
import '../../domain/entities/hazard_module.dart';
import '../../domain/entities/localized_text.dart';
import '../../domain/entities/module_progress.dart';
import '../../domain/usecases/award_badge.dart';
import '../../domain/usecases/complete_beat.dart';
import '../../domain/usecases/get_module.dart';
import '../../domain/usecases/save_quiz_result.dart';
import '../reward/reward_args.dart';

/// Load state for [LessonController], observed by [BeatRunnerPage].
enum LessonViewStatus { loading, data, error }

/// Drives a guided walk through one module's beats, from the beat tapped in
/// ModuleHome onward. Two modes, chosen by [isReplay]:
///  - forward (false): walk every remaining beat, ending in the reward
///    celebration the first time the module becomes fully completed.
///  - replay (true): show just the tapped beat, then return — used when
///    reviewing a beat that's already completed.
///
/// Badge-award is guarded by [ModuleProgress.badgeEarned] so replaying the
/// final beat of an already-completed module never re-awards it.
class LessonController extends GetxController {
  LessonController({
    required GetModule getModule,
    required CompleteBeat completeBeat,
    required AwardBadge awardBadge,
    required SaveQuizResult saveQuizResult,
    required NarrationService narrationService,
    required this.moduleId,
    required this.startBeatId,
    required this.isReplay,
  })  : _getModule = getModule,
        _completeBeat = completeBeat,
        _awardBadge = awardBadge,
        _saveQuizResult = saveQuizResult,
        _narrationService = narrationService;

  final GetModule _getModule;
  final CompleteBeat _completeBeat;
  final AwardBadge _awardBadge;
  final SaveQuizResult _saveQuizResult;
  final NarrationService _narrationService;

  final String moduleId;
  final String startBeatId;
  final bool isReplay;

  final Rx<LessonViewStatus> status = LessonViewStatus.loading.obs;
  final Rx<HazardModule?> module = Rx<HazardModule?>(null);
  final RxInt currentBeatIndex = 0.obs;
  final RxString errorMessage = ''.obs;

  /// Guards against a beat being completed twice from one tap-driven call —
  /// e.g. a double-tap landing before the UI has swapped in the next beat's
  /// runner would otherwise silently complete two beats at once.
  bool _isCompletingBeat = false;

  RxBool get isSpeaking => _narrationService.isSpeaking;

  HazardModule get _loadedModule => module.value!;
  Beat get currentBeat => _loadedModule.beats[currentBeatIndex.value];
  int get beatCount => _loadedModule.beats.length;

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

  /// Loads the module and positions the lesson at [startBeatId]. Exposed
  /// publicly so the UI can retry after an error.
  Future<void> load() async {
    status.value = LessonViewStatus.loading;
    final result = await _getModule(moduleId);
    switch (result) {
      case Success<HazardModule>(value: final loadedModule):
        module.value = loadedModule;
        final startIndex = loadedModule.beats.indexWhere((beat) => beat.id == startBeatId);
        currentBeatIndex.value = startIndex == -1 ? 0 : startIndex;
        status.value = LessonViewStatus.data;
      case Failure<HazardModule>(failure: final failure):
        AppLogger.error('LessonController failed to load module "$moduleId": ${failure.message}');
        errorMessage.value = failure.message;
        status.value = LessonViewStatus.error;
    }
  }

  /// Speaks [text] in the current app locale. Fire-and-forget from the UI's
  /// perspective — narration failures degrade silently inside the service.
  void narrate(LocalizedText text) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    _narrationService.speak(text.resolve(langCode), langCode: langCode);
  }

  void stopNarration() => _narrationService.stop();

  Future<void> recordQuizResult({required String quizId, required int correct, required int total}) =>
      _saveQuizResult(moduleId: moduleId, quizId: quizId, correctCount: correct, totalCount: total);

  /// Called by the active runner once the current beat is finished.
  /// Persists completion, then either advances, replays back to
  /// ModuleHome, or — the first time the module becomes fully completed —
  /// awards the badge and shows the reward celebration.
  Future<void> completeCurrentBeat() async {
    if (_isCompletingBeat) return;
    _isCompletingBeat = true;
    try {
      final beatId = currentBeat.id;
      final result = await _completeBeat(moduleId: moduleId, beatId: beatId);

      if (result case Failure<ModuleProgress>(failure: final failure)) {
        AppLogger.error('LessonController failed to persist beat "$beatId": ${failure.message}');
        _exitAfterBeat(newlyCompleted: false);
        return;
      }

      final progress = (result as Success<ModuleProgress>).value;
      _exitAfterBeat(newlyCompleted: progress.isCompleted && !progress.badgeEarned);
    } finally {
      _isCompletingBeat = false;
    }
  }

  Future<void> _exitAfterBeat({required bool newlyCompleted}) async {
    if (isReplay) {
      Get.back();
      return;
    }

    final isLastBeat = currentBeatIndex.value == beatCount - 1;
    if (!isLastBeat) {
      currentBeatIndex.value++;
      return;
    }

    if (newlyCompleted) {
      final badge = _loadedModule.badge;
      await _awardBadge(moduleId: moduleId, badge: badge);
      Get.offNamed(
        AppRoutes.reward,
        arguments: RewardArgs(moduleId: moduleId, badge: badge, themeColorHex: _loadedModule.themeColorHex),
      );
    } else {
      Get.back();
    }
  }
}
