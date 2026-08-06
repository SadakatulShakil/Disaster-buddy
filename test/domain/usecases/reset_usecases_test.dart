// Parent-controlled progress reset: proves the scope of each reset kind
// (what's cleared vs preserved), the Den/collection integrity rule (no
// sticker ever displayed after its badge is gone), and that resets never
// crash on edge cases (nothing completed yet, double resets, an already-
// incomplete module).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';
import 'package:bipod_bondhu/data/local/app_database.dart';
import 'package:bipod_bondhu/data/local/entities/activity_progress_entity.dart';
import 'package:bipod_bondhu/data/local/entities/badge_entity.dart';
import 'package:bipod_bondhu/data/local/entities/daily_completion_entity.dart';
import 'package:bipod_bondhu/data/local/entities/den_slot_entity.dart';
import 'package:bipod_bondhu/data/local/entities/den_theme_entity.dart';
import 'package:bipod_bondhu/data/local/entities/progress_entity.dart';
import 'package:bipod_bondhu/data/local/entities/quiz_result_entity.dart';
import 'package:bipod_bondhu/data/local/entities/streak_state_entity.dart';
import 'package:bipod_bondhu/data/repositories/activity_progress_repository_impl.dart';
import 'package:bipod_bondhu/data/repositories/den_repository_impl.dart';
import 'package:bipod_bondhu/data/repositories/progress_repository_impl.dart';
import 'package:bipod_bondhu/data/repositories/reset_repository_impl.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/collectible_sticker.dart';
import 'package:bipod_bondhu/domain/entities/den_state.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_den_state.dart';
import 'package:bipod_bondhu/domain/usecases/get_earned_collection.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';
import 'package:bipod_bondhu/domain/usecases/reset_everything.dart';
import 'package:bipod_bondhu/domain/usecases/reset_learning_progress.dart';
import 'package:bipod_bondhu/domain/usecases/reset_single_module.dart';

import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_content_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

HazardModule _module(String id) => HazardModule(
      id: id,
      order: 1,
      title: _text,
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: _text,
      badge: BadgeInfo(id: '${id}_badge', title: _text, iconAsset: 'badge.png'),
      beats: [StoryBeat(id: '${id}_story', order: 1, slides: const [])],
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppDatabase db;
  late ResetRepositoryImpl repository;
  late ResetLearningProgress resetLearningProgress;
  late ResetSingleModule resetSingleModule;
  late ResetEverything resetEverything;

  Future<void> seedRealisticData() async {
    await db.progressDao.insertProgress(const ProgressEntity(moduleId: 'earthquake', beatId: 'eq_story', completedAt: 1));
    await db.progressDao.insertProgress(const ProgressEntity(moduleId: 'flood', beatId: 'fl_story', completedAt: 2));
    await db.quizResultDao.insertResult(
      const QuizResultEntity(moduleId: 'earthquake', quizId: 'eq_quiz', correctCount: 3, totalCount: 3, attemptedAt: 3),
    );
    await db.quizResultDao.insertResult(
      const QuizResultEntity(moduleId: 'flood', quizId: 'fl_quiz', correctCount: 2, totalCount: 3, attemptedAt: 4),
    );
    await db.badgeDao.insertBadge(const BadgeEntity(badgeId: 'earthquake_badge', moduleId: 'earthquake', earnedAt: 5));
    await db.badgeDao.insertBadge(const BadgeEntity(badgeId: 'flood_badge', moduleId: 'flood', earnedAt: 6));
    await db.badgeDao.insertBadge(const BadgeEntity(badgeId: 'streak_7_badge', moduleId: 'daily_streak', earnedAt: 7));
    await db.activityProgressDao.insertOrUpdate(
      const ActivityProgressEntity(activityId: 'emergency_kit', isCompleted: true, updatedAt: 8),
    );
    await db.dailyCompletionDao.insertOrUpdate(
      const DailyCompletionEntity(dateKey: '2026-08-03', challengeId: 'dc_1', wasCorrect: true, completedAt: 9),
    );
    await db.streakStateDao.save(
      const StreakStateEntity(currentStreak: 5, bestStreak: 9, freezesAvailable: 1, lastCompletedDateKey: '2026-08-03'),
    );
    await db.denDao.upsertSlot(const DenSlotEntity(slotId: 'shelf_1_slot_1', stickerId: 'earthquake_badge'));
    await db.denDao.upsertSlot(const DenSlotEntity(slotId: 'shelf_1_slot_2', stickerId: 'streak_7_badge'));
    await db.denDao.upsertSlot(const DenSlotEntity(slotId: 'shelf_1_slot_3', stickerId: 'flood_badge'));
    await db.denDao.saveTheme(const DenThemeEntity(themeId: 'sky'));
  }

  setUp(() async {
    db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
    repository = ResetRepositoryImpl(db.resetDao);
    resetLearningProgress = ResetLearningProgress(repository);
    resetSingleModule = ResetSingleModule(repository);
    resetEverything = ResetEverything(repository);
  });

  tearDown(() => db.close());

  group('ResetLearningProgress', () {
    test('clears all module progress/quiz results/non-streak badges but preserves streak, daily history, and Den theme',
        () async {
      await seedRealisticData();

      final result = await resetLearningProgress();
      expect(result, isA<Success<void>>());

      expect(await db.progressDao.findByModule('earthquake'), isEmpty);
      expect(await db.progressDao.findByModule('flood'), isEmpty);
      final remainingBadges = await db.badgeDao.findAll();
      expect(remainingBadges, hasLength(1));
      expect(remainingBadges.single.badgeId, 'streak_7_badge');
      expect(await db.activityProgressDao.findByActivity('emergency_kit'), isNull);

      // Preserved: streak, daily-challenge history, Den theme.
      final streak = await db.streakStateDao.find();
      expect(streak?.currentStreak, 5);
      expect(await db.dailyCompletionDao.findByDate('2026-08-03'), isNotNull);
      expect((await db.denDao.findTheme())?.themeId, 'sky');

      // Integrity rule: the now-unearned hazard stickers are pruned from
      // the Den, but the still-earned streak sticker stays exactly where
      // it was placed.
      final slots = await db.denDao.findAllSlots();
      expect(slots.map((s) => s.slotId), ['shelf_1_slot_2']);
      expect(slots.single.stickerId, 'streak_7_badge');
    });

    test('is a harmless no-op when nothing has been completed yet', () async {
      final result = await resetLearningProgress();
      expect(result, isA<Success<void>>());
    });
  });

  group('ResetSingleModule', () {
    test('clears only the target module, leaving other modules, the streak, and the Den slot for other stickers', () async {
      await seedRealisticData();

      final result = await resetSingleModule('earthquake');
      expect(result, isA<Success<void>>());

      expect(await db.progressDao.findByModule('earthquake'), isEmpty);
      expect(await db.progressDao.findByModule('flood'), hasLength(1));
      expect(await db.badgeDao.findByModule('earthquake'), isEmpty);
      expect(await db.badgeDao.findByModule('flood'), hasLength(1));
      expect(await db.badgeDao.findByModule('daily_streak'), hasLength(1));
      expect(await db.activityProgressDao.findByActivity('emergency_kit'), isNotNull);

      final slots = await db.denDao.findAllSlots();
      final slotIds = slots.map((s) => s.slotId).toSet();
      expect(slotIds, {'shelf_1_slot_2', 'shelf_1_slot_3'});
      expect(slots.any((s) => s.stickerId == 'earthquake_badge'), isFalse);
    });

    test('resetting an already-incomplete module is a harmless no-op', () async {
      await seedRealisticData();

      final result = await resetSingleModule('lightning');
      expect(result, isA<Success<void>>());

      // Untouched modules stay exactly as seeded.
      expect(await db.progressDao.findByModule('earthquake'), hasLength(1));
      expect(await db.badgeDao.findAll(), hasLength(3));
    });
  });

  group('ResetEverything', () {
    test('wipes every progress/engagement table to first-time-user state', () async {
      await seedRealisticData();

      final result = await resetEverything();
      expect(result, isA<Success<void>>());

      expect(await db.progressDao.findByModule('earthquake'), isEmpty);
      expect(await db.progressDao.findByModule('flood'), isEmpty);
      expect(await db.badgeDao.findAll(), isEmpty);
      expect(await db.activityProgressDao.findByActivity('emergency_kit'), isNull);
      expect(await db.dailyCompletionDao.findByDate('2026-08-03'), isNull);
      expect(await db.streakStateDao.find(), isNull);
      expect(await db.denDao.findAllSlots(), isEmpty);
      expect(await db.denDao.findTheme(), isNull);
    });

    test('running it twice in a row is harmless', () async {
      await seedRealisticData();

      expect(await resetEverything(), isA<Success<void>>());
      expect(await resetEverything(), isA<Success<void>>());

      expect(await db.badgeDao.findAll(), isEmpty);
    });
  });

  group('post-reset reads (what the child screens actually load)', () {
    late ProgressRepositoryImpl progressRepository;
    late DenRepositoryImpl denRepository;
    late ActivityProgressRepositoryImpl activityProgressRepository;
    late FakeContentRepository contentRepository;
    late FakeActivityRepository activityRepository;
    late GetModules getModules;
    late GetModuleProgress getModuleProgress;
    late GetEarnedCollection getEarnedCollection;
    late GetDenState getDenState;

    setUp(() {
      progressRepository = ProgressRepositoryImpl(
        progressDao: db.progressDao,
        badgeDao: db.badgeDao,
        quizResultDao: db.quizResultDao,
      );
      denRepository = DenRepositoryImpl(db.denDao);
      activityProgressRepository = ActivityProgressRepositoryImpl(db.activityProgressDao);
      contentRepository = FakeContentRepository([_module('earthquake'), _module('flood')]);
      activityRepository = FakeActivityRepository(const []);
      getModules = GetModules(contentRepository);
      getModuleProgress = GetModuleProgress(contentRepository: contentRepository, progressRepository: progressRepository);
      getEarnedCollection = GetEarnedCollection(
        getModules: getModules,
        getActivities: GetActivities(activityRepository),
        progressRepository: progressRepository,
      );
      getDenState = GetDenState(denRepository);
    });

    test('GetModuleProgress/GetEarnedCollection/GetDenState never crash and reflect the reset, with no dangling stickers',
        () async {
      await seedRealisticData();
      await resetLearningProgress();

      final eqProgress = (await getModuleProgress('earthquake') as Success<ModuleProgress>).value;
      expect(eqProgress.isCompleted, isFalse);
      expect(eqProgress.badgeEarned, isFalse);

      final collection = (await getEarnedCollection() as Success<List<CollectibleSticker>>).value;
      final earthquakeSticker = collection.firstWhere((s) => s.badge.id == 'earthquake_badge');
      expect(earthquakeSticker.earned, isFalse);
      final streakSticker = collection.firstWhere((s) => s.badge.id == 'streak_7_badge');
      expect(streakSticker.earned, isTrue);

      final earnedIds = collection.where((s) => s.earned).map((s) => s.badge.id).toSet();
      final den = (await getDenState() as Success<DenState>).value;
      for (final slot in den.slots) {
        if (slot.placedStickerId != null) {
          expect(earnedIds.contains(slot.placedStickerId), isTrue, reason: 'no slot may reference an unearned sticker');
        }
      }

      // ActivityProgressRepository must also produce a sane result — no
      // dangling reference to a badge that no longer exists.
      final activityProgressResult = await activityProgressRepository.isActivityCompleted('emergency_kit');
      expect(activityProgressResult, isA<Success<bool>>());
      expect((activityProgressResult as Success<bool>).value, isFalse);
    });

    test('everything reset leaves an empty-but-valid Adventure Map and Den to load', () async {
      await seedRealisticData();
      await resetEverything();

      final modulesResult = await getModules();
      expect(modulesResult, isA<Success<List<HazardModule>>>());
      for (final module in (modulesResult as Success<List<HazardModule>>).value) {
        final progress = (await getModuleProgress(module.id) as Success<ModuleProgress>).value;
        expect(progress.isCompleted, isFalse);
      }

      final den = (await getDenState() as Success<DenState>).value;
      expect(den.slots.every((slot) => slot.placedStickerId == null), isTrue);
    });
  });

  group('device preferences are out of scope for every reset', () {
    test('resetEverything never touches language/sound/narration-speed preferences', () async {
      SharedPreferences.setMockInitialValues({});
      await UserPrefService.instance.init();
      await UserPrefService.instance.setLanguageCode('en');
      await UserPrefService.instance.setSoundEnabled(false);
      await UserPrefService.instance.setNarrationSpeed(0.9);

      await seedRealisticData();
      await resetEverything();

      expect(UserPrefService.instance.languageCode, 'en');
      expect(UserPrefService.instance.soundEnabled, isFalse);
      expect(UserPrefService.instance.narrationSpeed, 0.9);
    });
  });
}
