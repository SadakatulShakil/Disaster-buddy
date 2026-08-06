// Phase 4: upgrading the Floor database from v1 to v2 (adding
// `activity_progress`) must never lose a child's existing progress or
// badges — it only adds a new table.

import 'dart:io';

import 'package:floor/floor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bipod_bondhu/data/local/app_database.dart';
import 'package:bipod_bondhu/data/local/entities/activity_progress_entity.dart';

void main() {
  setUpAll(() {
    // `sqfliteDatabaseFactory` (used by Floor's generated code) already
    // does this on desktop platforms, but calling it explicitly here keeps
    // this test self-contained.
    sqfliteFfiInit();
  });

  const dbName = 'migration_test.db';
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

  test('migrating v1 -> v2 preserves existing progress/badges and adds activity_progress', () async {
    // Seed a v1 database directly, using the exact schema Floor generated
    // for v1 (see app_database.g.dart's onCreate for v1).
    final seedDb = await sqfliteDatabaseFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: 1,
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
        },
      ),
    );
    await seedDb.insert('progress', {'moduleId': 'earthquake', 'beatId': 'eq_story', 'completedAt': 1000});
    await seedDb.insert('badges', {'badgeId': 'earthquake_badge', 'moduleId': 'earthquake', 'earnedAt': 2000});
    await seedDb.close();

    // Reopen the SAME file through Floor — the compiled-in @Database
    // version has since moved to v4 (Phase E2), so every migration must be
    // supplied for Floor to chain v1 -> v2 -> v3 -> v4 rather than fail
    // with "no migration supplied".
    final db = await $FloorAppDatabase.databaseBuilder(dbName)
        .addMigrations([migrationV1ToV2, migrationV2ToV3, migrationV3ToV4])
        .build();

    final progressRows = await db.progressDao.findByModule('earthquake');
    expect(progressRows, hasLength(1));
    expect(progressRows.first.beatId, 'eq_story');
    expect(progressRows.first.completedAt, 1000);

    final badgeRows = await db.badgeDao.findByModule('earthquake');
    expect(badgeRows, hasLength(1));
    expect(badgeRows.first.badgeId, 'earthquake_badge');

    // The new table exists and is fully usable post-migration.
    await db.activityProgressDao.insertOrUpdate(
      const ActivityProgressEntity(activityId: 'emergency_kit', isCompleted: true, updatedAt: 3000),
    );
    final activityRow = await db.activityProgressDao.findByActivity('emergency_kit');
    expect(activityRow?.isCompleted, isTrue);

    await db.close();
  });
}
