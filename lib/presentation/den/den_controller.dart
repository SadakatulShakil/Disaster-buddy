import 'dart:async';

import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/result.dart';
import '../../core/services/narration_service.dart';
import '../../core/theme/app_durations.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/collectible_sticker.dart';
import '../../domain/entities/den_slot.dart';
import '../../domain/entities/den_state.dart';
import '../../domain/entities/streak_state.dart';
import '../../domain/services/streak_milestones.dart';
import '../../domain/usecases/get_den_state.dart';
import '../../domain/usecases/get_earned_collection.dart';
import '../../domain/usecases/get_streak_overview.dart';
import '../../domain/usecases/get_todays_challenge.dart';
import '../../domain/usecases/place_sticker.dart';
import '../../domain/usecases/remove_sticker.dart';
import '../../domain/usecases/set_den_theme.dart';
import '../widgets/mascot_view.dart';

/// Load state for [DenController], observed by the Den page.
enum DenViewStatus { loading, data, error }

/// Why Tuku is greeting the child the way it is right now — always a warm
/// context, never a guilt-trip. Ordered by how delightful the moment is:
/// a fresh sticker to place beats a streak milestone, which beats simply
/// noticing the child is back.
enum DenGreetingContext { newSticker, milestone, returningToday, firstVisitToday }

/// Drives Tuku's Den: loads the saved arrangement, the child's full sticker
/// collection, and today's streak/daily status, then derives Tuku's mood
/// and greeting from that context. Sticker placement/removal/theme changes
/// are applied optimistically to [denState] and rolled back on failure, so
/// dragging always feels instant.
class DenController extends GetxController {
  DenController({
    required GetDenState getDenState,
    required GetEarnedCollection getEarnedCollection,
    required GetStreakOverview getStreakOverview,
    required GetTodaysChallenge getTodaysChallenge,
    required PlaceSticker placeSticker,
    required RemoveSticker removeSticker,
    required SetDenTheme setDenTheme,
    required NarrationService narrationService,
  })  : _getDenState = getDenState,
        _getEarnedCollection = getEarnedCollection,
        _getStreakOverview = getStreakOverview,
        _getTodaysChallenge = getTodaysChallenge,
        _placeSticker = placeSticker,
        _removeSticker = removeSticker,
        _setDenTheme = setDenTheme,
        _narrationService = narrationService;

  final GetDenState _getDenState;
  final GetEarnedCollection _getEarnedCollection;
  final GetStreakOverview _getStreakOverview;
  final GetTodaysChallenge _getTodaysChallenge;
  final PlaceSticker _placeSticker;
  final RemoveSticker _removeSticker;
  final SetDenTheme _setDenTheme;
  final NarrationService _narrationService;

  final Rx<DenViewStatus> status = DenViewStatus.loading.obs;
  final Rx<DenState?> denState = Rx<DenState?>(null);
  final RxList<CollectibleSticker> collection = <CollectibleSticker>[].obs;
  final Rx<StreakState?> streakState = Rx<StreakState?>(null);
  final RxString errorMessage = ''.obs;
  final Rx<MascotMood> mascotMood = MascotMood.idle.obs;
  final Rx<DenGreetingContext> greetingContext = DenGreetingContext.firstVisitToday.obs;

  Timer? _reactionTimer;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _reactionTimer?.cancel();
    _narrationService.stop();
    super.onClose();
  }

  /// Loads the Den + collection (required for the interactive core) plus
  /// streak/daily status (nice-to-have context for Tuku's greeting — a
  /// failure there degrades to a calm default greeting rather than
  /// blocking the whole screen). Exposed publicly so the UI can retry.
  Future<void> load() async {
    status.value = DenViewStatus.loading;

    final denResult = await _getDenState();
    if (denResult case Failure<DenState>(failure: final failure)) {
      AppLogger.error('DenController failed to load Den state: ${failure.message}');
      errorMessage.value = failure.message;
      status.value = DenViewStatus.error;
      return;
    }

    final collectionResult = await _getEarnedCollection();
    if (collectionResult case Failure<List<CollectibleSticker>>(failure: final failure)) {
      AppLogger.error('DenController failed to load collection: ${failure.message}');
      errorMessage.value = failure.message;
      status.value = DenViewStatus.error;
      return;
    }

    denState.value = (denResult as Success<DenState>).value;
    collection.value = (collectionResult as Success<List<CollectibleSticker>>).value;

    final streakOverviewResult = await _getStreakOverview();
    streakState.value =
        streakOverviewResult is Success<StreakOverview> ? streakOverviewResult.value.state : null;

    final dailyResult = await _getTodaysChallenge();
    final alreadyCompletedToday =
        dailyResult is Success<TodaysChallengeResult> ? dailyResult.value.alreadyCompletedToday : false;

    final hasNewUnplacedSticker = _hasNewUnplacedSticker(collection, denState.value!);
    final milestoneReachedToday = alreadyCompletedToday &&
        streakState.value != null &&
        StreakMilestones.lengths.contains(streakState.value!.currentStreak);

    greetingContext.value = computeGreetingContext(
      hasNewUnplacedSticker: hasNewUnplacedSticker,
      alreadyCompletedToday: alreadyCompletedToday,
      milestoneReachedToday: milestoneReachedToday,
    );
    mascotMood.value = moodForGreeting(greetingContext.value);

    status.value = DenViewStatus.data;
  }

  bool _hasNewUnplacedSticker(List<CollectibleSticker> collection, DenState den) {
    final placedIds = den.slots.map((slot) => slot.placedStickerId).whereType<String>().toSet();
    return collection.any((sticker) => sticker.earned && !placedIds.contains(sticker.badge.id));
  }

  /// Pure so it can be tested without any GetX/controller wiring.
  static DenGreetingContext computeGreetingContext({
    required bool hasNewUnplacedSticker,
    required bool alreadyCompletedToday,
    required bool milestoneReachedToday,
  }) {
    if (hasNewUnplacedSticker) return DenGreetingContext.newSticker;
    if (milestoneReachedToday) return DenGreetingContext.milestone;
    if (alreadyCompletedToday) return DenGreetingContext.returningToday;
    return DenGreetingContext.firstVisitToday;
  }

  /// Every context maps to an upbeat mood — Tuku never looks sad, bored, or
  /// impatient waiting for a visit.
  static MascotMood moodForGreeting(DenGreetingContext context) => switch (context) {
        DenGreetingContext.newSticker => MascotMood.cheer,
        DenGreetingContext.milestone => MascotMood.cheer,
        DenGreetingContext.returningToday => MascotMood.happy,
        DenGreetingContext.firstVisitToday => MascotMood.point,
      };

  /// A short, warm reaction to being tapped — never clingy, just delighted.
  /// Mood settles back to the contextual greeting mood after a moment.
  void reactToTuku() {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    mascotMood.value = MascotMood.cheer;
    _narrationService.speak('den_tap_reaction'.tr, langCode: langCode);

    _reactionTimer?.cancel();
    _reactionTimer = Timer(AppDurations.breathing, () {
      if (isClosed) return;
      mascotMood.value = moodForGreeting(greetingContext.value);
    });
  }

  /// Places [stickerId] into [slotId]. Updates [denState] immediately with
  /// the same swap rule the use case applies (so the drag snaps instantly),
  /// then reconciles with the persisted result — or rolls back to
  /// [previous] if the change was rejected/failed.
  Future<void> placeStickerInSlot({required String slotId, required String stickerId}) async {
    final previous = denState.value;
    if (previous == null) return;

    denState.value = previous.copyWith(
      slots: [
        for (final slot in previous.slots)
          if (slot.slotId == slotId)
            DenSlot(slotId: slotId, placedStickerId: stickerId)
          else if (slot.placedStickerId == stickerId)
            DenSlot(slotId: slot.slotId)
          else
            slot,
      ],
    );
    mascotMood.value = MascotMood.cheer;

    final result = await _placeSticker(slotId: slotId, stickerId: stickerId);
    switch (result) {
      case Success<DenState>(value: final newState):
        denState.value = newState;
      case Failure<DenState>(failure: final failure):
        AppLogger.error('placeStickerInSlot failed: ${failure.message}');
        denState.value = previous;
    }
  }

  /// Removes whatever sticker sits in [slotId], returning it to the tray.
  Future<void> removeStickerFromSlot(String slotId) async {
    final previous = denState.value;
    if (previous == null) return;

    denState.value = previous.copyWith(
      slots: [
        for (final slot in previous.slots) if (slot.slotId == slotId) DenSlot(slotId: slotId) else slot,
      ],
    );

    final result = await _removeSticker(slotId);
    switch (result) {
      case Success<DenState>(value: final newState):
        denState.value = newState;
      case Failure<DenState>(failure: final failure):
        AppLogger.error('removeStickerFromSlot failed: ${failure.message}');
        denState.value = previous;
    }
  }

  /// Switches the room to a different free theme.
  Future<void> changeTheme(String themeId) async {
    final previous = denState.value;
    if (previous == null) return;

    denState.value = previous.copyWith(themeId: themeId);

    final result = await _setDenTheme(themeId);
    switch (result) {
      case Success<DenState>(value: final newState):
        denState.value = newState;
      case Failure<DenState>(failure: final failure):
        AppLogger.error('changeTheme failed: ${failure.message}');
        denState.value = previous;
    }
  }
}
