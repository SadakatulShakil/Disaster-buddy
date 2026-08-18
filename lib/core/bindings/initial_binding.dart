import 'package:get/get.dart';

import '../../data/datasources/activity_asset_source.dart';
import '../../data/datasources/content_asset_source.dart';
import '../../data/datasources/daily_challenge_asset_source.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/activity_progress_repository_impl.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../data/repositories/daily_challenge_repository_impl.dart';
import '../../data/repositories/daily_progress_repository_impl.dart';
import '../../data/repositories/den_repository_impl.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/repositories/reset_repository_impl.dart';
import '../../domain/repositories/activity_progress_repository.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/repositories/daily_challenge_repository.dart';
import '../../domain/repositories/daily_progress_repository.dart';
import '../../domain/repositories/den_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/reset_repository.dart';
import '../../domain/usecases/award_badge.dart';
import '../../domain/usecases/complete_activity.dart';
import '../../domain/usecases/complete_beat.dart';
import '../../domain/usecases/get_activities.dart';
import '../../domain/usecases/get_activity.dart';
import '../../domain/usecases/get_activity_progress.dart';
import '../../domain/usecases/get_den_state.dart';
import '../../domain/usecases/get_earned_collection.dart';
import '../../domain/usecases/get_module.dart';
import '../../domain/usecases/get_module_progress.dart';
import '../../domain/usecases/get_modules.dart';
import '../../domain/usecases/get_streak_overview.dart';
import '../../domain/usecases/get_todays_challenge.dart';
import '../../domain/usecases/mark_challenge_complete.dart';
import '../../domain/usecases/place_sticker.dart';
import '../../domain/usecases/remove_sticker.dart';
import '../../domain/usecases/reset_everything.dart';
import '../../domain/usecases/reset_learning_progress.dart';
import '../../domain/usecases/reset_single_module.dart';
import '../../domain/usecases/save_quiz_result.dart';
import '../../domain/usecases/set_den_theme.dart';
import '../services/narration_service.dart';
import '../services/sound_service.dart';

/// App-wide dependencies that live for the whole session.
/// UserPrefService is a plain singleton initialised in main(), so it isn't
/// registered here. `AppDatabase` is already Get.put in main() before this
/// binding runs — everything else is wired on top of it.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<NarrationService>(NarrationService(), permanent: true);
    final soundService = SoundService();
    Get.put<SoundService>(soundService, permanent: true);
    soundService.preload();

    final db = Get.find<AppDatabase>();

    final contentRepository = ContentRepositoryImpl(ContentAssetSourceImpl());
    final progressRepository = ProgressRepositoryImpl(
      progressDao: db.progressDao,
      badgeDao: db.badgeDao,
      quizResultDao: db.quizResultDao,
    );
    Get.put<ContentRepository>(contentRepository, permanent: true);
    Get.put<ProgressRepository>(progressRepository, permanent: true);

    final getModules = GetModules(contentRepository);
    final getModule = GetModule(contentRepository);
    final getModuleProgress = GetModuleProgress(
      contentRepository: contentRepository,
      progressRepository: progressRepository,
    );
    Get.put<GetModules>(getModules, permanent: true);
    Get.put<GetModule>(getModule, permanent: true);
    Get.put<GetModuleProgress>(getModuleProgress, permanent: true);
    Get.put<CompleteBeat>(
      CompleteBeat(progressRepository: progressRepository, getModuleProgress: getModuleProgress),
      permanent: true,
    );
    Get.put<AwardBadge>(AwardBadge(progressRepository), permanent: true);
    Get.put<SaveQuizResult>(SaveQuizResult(progressRepository), permanent: true);

    final activityRepository = ActivityRepositoryImpl(ActivityAssetSourceImpl());
    final activityProgressRepository = ActivityProgressRepositoryImpl(db.activityProgressDao);
    Get.put<ActivityRepository>(activityRepository, permanent: true);
    Get.put<ActivityProgressRepository>(activityProgressRepository, permanent: true);

    final getActivities = GetActivities(activityRepository);
    Get.put<GetActivities>(getActivities, permanent: true);
    Get.put<GetActivity>(GetActivity(activityRepository), permanent: true);
    Get.put<GetActivityProgress>(
      GetActivityProgress(
        activityRepository: activityRepository,
        activityProgressRepository: activityProgressRepository,
        progressRepository: progressRepository,
      ),
      permanent: true,
    );
    Get.put<CompleteActivity>(
      CompleteActivity(
        activityProgressRepository: activityProgressRepository,
        progressRepository: progressRepository,
      ),
      permanent: true,
    );

    final dailyChallengeRepository = DailyChallengeRepositoryImpl(DailyChallengeAssetSourceImpl());
    final dailyProgressRepository = DailyProgressRepositoryImpl(
      dailyCompletionDao: db.dailyCompletionDao,
      streakStateDao: db.streakStateDao,
    );
    Get.put<DailyChallengeRepository>(dailyChallengeRepository, permanent: true);
    Get.put<DailyProgressRepository>(dailyProgressRepository, permanent: true);

    Get.put<GetTodaysChallenge>(
      GetTodaysChallenge(
        dailyChallengeRepository: dailyChallengeRepository,
        dailyProgressRepository: dailyProgressRepository,
        getModules: getModules,
        getModuleProgress: getModuleProgress,
      ),
      permanent: true,
    );
    Get.put<MarkChallengeComplete>(
      MarkChallengeComplete(
        dailyProgressRepository: dailyProgressRepository,
        progressRepository: progressRepository,
        awardBadge: Get.find<AwardBadge>(),
      ),
      permanent: true,
    );
    Get.put<GetStreakOverview>(
      GetStreakOverview(dailyProgressRepository: dailyProgressRepository),
      permanent: true,
    );

    final denRepository = DenRepositoryImpl(db.denDao);
    Get.put<DenRepository>(denRepository, permanent: true);

    final getEarnedCollection = GetEarnedCollection(
      getModules: getModules,
      getActivities: getActivities,
      progressRepository: progressRepository,
    );
    Get.put<GetDenState>(GetDenState(denRepository), permanent: true);
    Get.put<GetEarnedCollection>(getEarnedCollection, permanent: true);
    Get.put<PlaceSticker>(
      PlaceSticker(denRepository: denRepository, progressRepository: progressRepository),
      permanent: true,
    );
    Get.put<RemoveSticker>(RemoveSticker(denRepository), permanent: true);
    Get.put<SetDenTheme>(SetDenTheme(denRepository), permanent: true);

    final resetRepository = ResetRepositoryImpl(db.resetDao);
    Get.put<ResetRepository>(resetRepository, permanent: true);
    Get.put<ResetLearningProgress>(ResetLearningProgress(resetRepository), permanent: true);
    Get.put<ResetSingleModule>(ResetSingleModule(resetRepository), permanent: true);
    Get.put<ResetEverything>(ResetEverything(resetRepository), permanent: true);
  }
}
