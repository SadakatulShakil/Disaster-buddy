// Phase E2: upgrading the Floor database from v3 to v4 (adding `den_slots`
// and `den_theme` for Tuku's Den) must never lose a child's existing
// progress, badges, quiz history, activity progress, daily completions, or
// streak — it only adds two new tables.

import 'dart:io';

import 'package:floor/floor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bipod_bondhu/data/local/app_database.dart';
import 'package:bipod_bondhu/data/local/entities/den_slot_entity.dart';
import 'package:bipod_bondhu/data/local/entities/den_theme_entity.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  const dbName = 'migration_v4_test.db';
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

  test('migrating v3 -> v4 preserves existing data and adds den_slots/den_theme', () async {
    // Seed a v3 database directly, using the exact schema Floor generated
    // for v3 (progress/badges/quiz_results from v1, activity_progress from
    // v1->v2, daily_completions/streak_state from v2->v3).
    final seedDb = await sqfliteDatabaseFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: 3,
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
          await db.execute(
            'CREATE TABLE IF NOT EXISTS `daily_completions` '
            '(`dateKey` TEXT NOT NULL, `challengeId` TEXT NOT NULL, `wasCorrect` INTEGER NOT NULL, '
            '`completedAt` INTEGER NOT NULL, PRIMARY KEY (`dateKey`))',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS `streak_state` '
            '(`id` INTEGER NOT NULL, `currentStreak` INTEGER NOT NULL, `bestStreak` INTEGER NOT NULL, '
            '`freezesAvailable` INTEGER NOT NULL, `lastCompletedDateKey` TEXT, PRIMARY KEY (`id`))',
          );
        },
      ),
    );
    await seedDb.insert('progress', {'moduleId': 'earthquake', 'beatId': 'eq_story', 'completedAt': 1000});
    await seedDb.insert('badges', {'badgeId': 'earthquake_badge', 'moduleId': 'earthquake', 'earnedAt': 2000});
    await seedDb.insert('streak_state', {
      'id': 0,
      'currentStreak': 4,
      'bestStreak': 9,
      'freezesAvailable': 1,
      'lastCompletedDateKey': '2026-08-03',
    });
    await seedDb.close();

    // Reopen the SAME file through Floor at v4 — this must trigger
    // migrationV3ToV4 rather than a fresh onCreate.
    final db = await $FloorAppDatabase.databaseBuilder(dbName)
        .addMigrations([migrationV1ToV2, migrationV2ToV3, migrationV3ToV4])
        .build();

    final progressRows = await db.progressDao.findByModule('earthquake');
    expect(progressRows, hasLength(1));
    expect(progressRows.first.beatId, 'eq_story');

    final badgeRows = await db.badgeDao.findByModule('earthquake');
    expect(badgeRows, hasLength(1));

    final streakRow = await db.streakStateDao.find();
    expect(streakRow?.currentStreak, 4);
    expect(streakRow?.bestStreak, 9);

    // The two new tables exist and are fully usable post-migration.
    await db.denDao.upsertSlot(const DenSlotEntity(slotId: 'shelf_1_slot_1', stickerId: 'earthquake_badge'));
    final slotRows = await db.denDao.findAllSlots();
    expect(slotRows, hasLength(1));
    expect(slotRows.first.stickerId, 'earthquake_badge');

    await db.denDao.saveTheme(const DenThemeEntity(themeId: 'sky'));
    final themeRow = await db.denDao.findTheme();
    expect(themeRow?.themeId, 'sky');

    await db.close();
  });
}
