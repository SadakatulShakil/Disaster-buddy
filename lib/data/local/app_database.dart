import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../../core/constants/app_constants.dart';
import 'daos/activity_progress_dao.dart';
import 'daos/badge_dao.dart';
import 'daos/daily_completion_dao.dart';
import 'daos/den_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/quiz_result_dao.dart';
import 'daos/reset_dao.dart';
import 'daos/streak_state_dao.dart';
import 'entities/activity_progress_entity.dart';
import 'entities/badge_entity.dart';
import 'entities/daily_completion_entity.dart';
import 'entities/den_slot_entity.dart';
import 'entities/den_theme_entity.dart';
import 'entities/progress_entity.dart';
import 'entities/quiz_result_entity.dart';
import 'entities/streak_state_entity.dart';

part 'app_database.g.dart';

/// The app's local database. Stores only user state (progress, badges, quiz
/// results) — static hazard content always comes from the JSON manifests.
@Database(
  version: 4,
  entities: [
    ProgressEntity,
    BadgeEntity,
    QuizResultEntity,
    ActivityProgressEntity,
    DailyCompletionEntity,
    StreakStateEntity,
    DenSlotEntity,
    DenThemeEntity,
  ],
)
abstract class AppDatabase extends FloorDatabase {
  ProgressDao get progressDao;
  BadgeDao get badgeDao;
  QuizResultDao get quizResultDao;
  ActivityProgressDao get activityProgressDao;
  DailyCompletionDao get dailyCompletionDao;
  StreakStateDao get streakStateDao;
  DenDao get denDao;
  ResetDao get resetDao;
}

/// v1 -> v2: adds the `activity_progress` table for cross-cutting activities
/// (e.g. the Emergency Kit Builder). Existing `progress`/`badges`/
/// `quiz_results` tables and their rows are untouched — this only adds a
/// new table, so upgrading never loses a child's existing progress.
final Migration migrationV1ToV2 = Migration(1, 2, (database) async {
  await database.execute(
    'CREATE TABLE IF NOT EXISTS `activity_progress` '
    '(`activityId` TEXT NOT NULL, `isCompleted` INTEGER NOT NULL, `bestScore` INTEGER, `updatedAt` INTEGER NOT NULL, '
    'PRIMARY KEY (`activityId`))',
  );
});

/// v2 -> v3: adds `daily_completions` and `streak_state` for the daily
/// challenge + "chain with grace" streak (Phase E1). Existing tables and
/// rows are untouched — this only adds two new tables, so upgrading never
/// loses a child's existing progress, badges, or quiz history.
final Migration migrationV2ToV3 = Migration(2, 3, (database) async {
  await database.execute(
    'CREATE TABLE IF NOT EXISTS `daily_completions` '
    '(`dateKey` TEXT NOT NULL, `challengeId` TEXT NOT NULL, `wasCorrect` INTEGER NOT NULL, `completedAt` INTEGER NOT NULL, '
    'PRIMARY KEY (`dateKey`))',
  );
  await database.execute(
    'CREATE TABLE IF NOT EXISTS `streak_state` '
    '(`id` INTEGER NOT NULL, `currentStreak` INTEGER NOT NULL, `bestStreak` INTEGER NOT NULL, '
    '`freezesAvailable` INTEGER NOT NULL, `lastCompletedDateKey` TEXT, PRIMARY KEY (`id`))',
  );
});

/// v3 -> v4: adds `den_slots` and `den_theme` for Tuku's Den (Phase E2).
/// Existing tables and rows are untouched — this only adds two new tables,
/// so upgrading never loses a child's existing progress, badges, quiz
/// history, or streak.
final Migration migrationV3ToV4 = Migration(3, 4, (database) async {
  await database.execute(
    'CREATE TABLE IF NOT EXISTS `den_slots` '
    '(`slotId` TEXT NOT NULL, `stickerId` TEXT NOT NULL, PRIMARY KEY (`slotId`))',
  );
  await database.execute(
    'CREATE TABLE IF NOT EXISTS `den_theme` '
    '(`id` INTEGER NOT NULL, `themeId` TEXT NOT NULL, PRIMARY KEY (`id`))',
  );
});

/// Opens (creating if needed) the app's Floor database using
/// [AppConstants.dbName]. Call once, in `main()`.
Future<AppDatabase> openAppDatabase() {
  return $FloorAppDatabase.databaseBuilder(AppConstants.dbName)
      .addMigrations([migrationV1ToV2, migrationV2ToV3, migrationV3ToV4])
      .build();
}
