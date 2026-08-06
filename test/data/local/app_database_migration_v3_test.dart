// Phase E1: upgrading the Floor database from v2 to v3 (adding
// `daily_completions` and `streak_state`) must never lose a child's
// existing progress, badges, quiz history, or activity progress — it only
// adds two new tables.

import 'dart:io';

import 'package:floor/floor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bipod_bondhu/data/local/app_database.dart';
import 'package:bipod_bondhu/data/local/entities/daily_completion_entity.dart';
import 'package:bipod_bondhu/data/local/entities/streak_state_entity.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  const dbName = 'migration_v3_test.db';
  late String resolvedPath;

  setUp(() async {
    resolvedPath = await sqfliteDatabaseFactory.getDatabasePath(dbName);
    final file = File(resolvedPath);
    if (file.existsSync()) file.deleteSync();
  });

  tearDown(() async {
    final file = File(resolvedPath);
    if (file.existsSync()) file.deleteSync();
  });

  test('migrating v2 -> v3 preserves existing data and adds daily/streak tables', () async {
    // Seed a v2 database directly, using the exact schema Floor generated
    // for v2 (progress/badges/quiz_results from v1, plus activity_progress
    // added in v1->v2).
    final seedDb = await sqfliteDatabaseFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS `progress` '
            '(`moduleId` TEXT NOT NULL, `beatId` TEXT NOT NULL, `completedAt` INTEGER NOT NULL, '
            'PRIMARY KEY (`moduleId`, `beatId`))',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS `badges` '
            '(`badgeId` TEXT NOT NULL, `moduleId` TEXT NOT NULL, `earnedAt` INTEGER NOT NULL, '
            'PRIMARY KEY (`badgeId`))',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS `quiz_results` '
            '(`id` INTEGER PRIMARY KEY AUTOINCREMENT, `moduleId` TEXT NOT NULL, `quizId` TEXT NOT NULL, '
            '`correctCount` INTEGER NOT NULL, `totalCount` INTEGER NOT NULL, `attemptedAt` INTEGER NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS `activity_progress` '
            '(`activityId` TEXT NOT NULL, `isCompleted` INTEGER NOT NULL, `bestScore` INTEGER, '
            '`updatedAt` INTEGER NOT NULL, PRIMARY KEY (`activityId`))',
          );
        },
      ),
    );
    await seedDb.insert('progress', {'moduleId': 'earthquake', 'beatId': 'eq_story', 'completedAt': 1000});
    await seedDb.insert('badges', {'badgeId': 'earthquake_badge', 'moduleId': 'earthquake', 'earnedAt': 2000});
    await seedDb.insert('activity_progress', {
      'activityId': 'emergency_kit',
      'isCompleted': 1,
      'bestScore': null,
      'updatedAt': 3000,
    });
    await seedDb.close();

    // Reopen the SAME file through Floor — the compiled-in @Database
    // version has since moved to v4 (Phase E2), so every migration must be
    // supplied for Floor to chain v2 -> v3 -> v4 rather than fail with "no
    // migration supplied".
    final db = await $FloorAppDatabase.databaseBuilder(dbName)
        .addMigrations([migrationV1ToV2, migrationV2ToV3, migrationV3ToV4])
        .build();

    final progressRows = await db.progressDao.findByModule('earthquake');
    expect(progressRows, hasLength(1));
    expect(progressRows.first.beatId, 'eq_story');

    final badgeRows = await db.badgeDao.findByModule('earthquake');
    expect(badgeRows, hasLength(1));

    final activityRow = await db.activityProgressDao.findByActivity('emergency_kit');
    expect(activityRow?.isCompleted, isTrue);

    // The two new tables exist and are fully usable post-migration.
    await db.dailyCompletionDao.insertOrUpdate(
      const DailyCompletionEntity(dateKey: '2026-08-03', challengeId: 'dc_1', wasCorrect: true, completedAt: 4000),
    );
    final completionRow = await db.dailyCompletionDao.findByDate('2026-08-03');
    expect(completionRow?.challengeId, 'dc_1');

    await db.streakStateDao.save(
      const StreakStateEntity(currentStreak: 3, bestStreak: 5, freezesAvailable: 1, lastCompletedDateKey: '2026-08-03'),
    );
    final streakRow = await db.streakStateDao.find();
    expect(streakRow?.currentStreak, 3);
    expect(streakRow?.bestStreak, 5);

    await db.close();
  });
}
