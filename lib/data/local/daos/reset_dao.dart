import 'package:floor/floor.dart';

/// Deletes backing a parent-controlled progress reset. Every reset is one
/// `@transaction` method grouping several raw deletes, so it either fully
/// applies or leaves every table untouched — Floor wraps the method body in
/// a single native sqlite transaction, and sqlite guarantees the rollback
/// on any failure.
///
/// Each transaction prunes Tuku's Den *before* deleting the badges those
/// slots reference, via a `stickerId IN (SELECT badgeId FROM badges ...)`
/// subquery — this is how the "never display an unearned sticker"
/// integrity rule is enforced atomically, without a separate round-trip.
@dao
abstract class ResetDao {
  @Query('DELETE FROM progress')
  Future<void> deleteAllProgress();

  @Query('DELETE FROM progress WHERE moduleId = :moduleId')
  Future<void> deleteProgressForModule(String moduleId);

  @Query('DELETE FROM quiz_results')
  Future<void> deleteAllQuizResults();

  @Query('DELETE FROM quiz_results WHERE moduleId = :moduleId')
  Future<void> deleteQuizResultsForModule(String moduleId);

  @Query('DELETE FROM badges')
  Future<void> deleteAllBadges();

  @Query('DELETE FROM badges WHERE moduleId = :moduleId')
  Future<void> deleteBadgesForModule(String moduleId);

  @Query('DELETE FROM badges WHERE moduleId != :streakOwnerId')
  Future<void> deleteNonStreakBadges(String streakOwnerId);

  @Query('DELETE FROM activity_progress')
  Future<void> deleteAllActivityProgress();

  @Query('DELETE FROM daily_completions')
  Future<void> deleteAllDailyCompletions();

  @Query('DELETE FROM streak_state')
  Future<void> deleteStreakState();

  @Query('DELETE FROM den_slots')
  Future<void> deleteAllDenSlots();

  @Query('DELETE FROM den_theme')
  Future<void> deleteDenTheme();

  @Query('DELETE FROM den_slots WHERE stickerId IN (SELECT badgeId FROM badges WHERE moduleId = :moduleId)')
  Future<void> pruneDenSlotsForModuleBadges(String moduleId);

  @Query('DELETE FROM den_slots WHERE stickerId IN (SELECT badgeId FROM badges WHERE moduleId != :streakOwnerId)')
  Future<void> pruneDenSlotsForNonStreakBadges(String streakOwnerId);

  /// Clears every hazard module's beat progress, quiz results, and badge,
  /// plus every cross-cutting activity's progress and badge (the "learning"
  /// scope) — first pruning any of those badges' stickers out of Tuku's
  /// Den. Never touches daily-challenge history, streak state, or the
  /// Den's theme/streak stickers.
  @transaction
  Future<void> resetLearningProgress(String streakOwnerId) async {
    await pruneDenSlotsForNonStreakBadges(streakOwnerId);
    await deleteNonStreakBadges(streakOwnerId);
    await deleteAllProgress();
    await deleteAllQuizResults();
    await deleteAllActivityProgress();
  }

  /// Clears one hazard module's beat progress, quiz results, and badge —
  /// first pruning that badge's sticker out of Tuku's Den. Every other
  /// module, activity, the streak, and the rest of the Den are untouched.
  @transaction
  Future<void> resetSingleModule(String moduleId) async {
    await pruneDenSlotsForModuleBadges(moduleId);
    await deleteBadgesForModule(moduleId);
    await deleteProgressForModule(moduleId);
    await deleteQuizResultsForModule(moduleId);
  }

  /// Wipes every progress/engagement table back to a brand-new child's
  /// state: no progress, no badges, no quiz history, no daily-challenge
  /// history, an initial streak, and an empty, default-themed Den. Device
  /// preferences (language/sound/narration speed) are never touched here —
  /// those live in `UserPrefService`, not this database.
  @transaction
  Future<void> resetEverything() async {
    await deleteAllDenSlots();
    await deleteDenTheme();
    await deleteAllBadges();
    await deleteAllProgress();
    await deleteAllQuizResults();
    await deleteAllActivityProgress();
    await deleteAllDailyCompletions();
    await deleteStreakState();
  }
}
