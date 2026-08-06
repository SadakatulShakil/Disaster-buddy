// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ProgressDao? _progressDaoInstance;

  BadgeDao? _badgeDaoInstance;

  QuizResultDao? _quizResultDaoInstance;

  ActivityProgressDao? _activityProgressDaoInstance;

  DailyCompletionDao? _dailyCompletionDaoInstance;

  StreakStateDao? _streakStateDaoInstance;

  DenDao? _denDaoInstance;

  ResetDao? _resetDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 4,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `progress` (`moduleId` TEXT NOT NULL, `beatId` TEXT NOT NULL, `completedAt` INTEGER NOT NULL, PRIMARY KEY (`moduleId`, `beatId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `badges` (`badgeId` TEXT NOT NULL, `moduleId` TEXT NOT NULL, `earnedAt` INTEGER NOT NULL, PRIMARY KEY (`badgeId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `quiz_results` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `moduleId` TEXT NOT NULL, `quizId` TEXT NOT NULL, `correctCount` INTEGER NOT NULL, `totalCount` INTEGER NOT NULL, `attemptedAt` INTEGER NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `activity_progress` (`activityId` TEXT NOT NULL, `isCompleted` INTEGER NOT NULL, `bestScore` INTEGER, `updatedAt` INTEGER NOT NULL, PRIMARY KEY (`activityId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `daily_completions` (`dateKey` TEXT NOT NULL, `challengeId` TEXT NOT NULL, `wasCorrect` INTEGER NOT NULL, `completedAt` INTEGER NOT NULL, PRIMARY KEY (`dateKey`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `streak_state` (`id` INTEGER NOT NULL, `currentStreak` INTEGER NOT NULL, `bestStreak` INTEGER NOT NULL, `freezesAvailable` INTEGER NOT NULL, `lastCompletedDateKey` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `den_slots` (`slotId` TEXT NOT NULL, `stickerId` TEXT NOT NULL, PRIMARY KEY (`slotId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `den_theme` (`id` INTEGER NOT NULL, `themeId` TEXT NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ProgressDao get progressDao {
    return _progressDaoInstance ??= _$ProgressDao(database, changeListener);
  }

  @override
  BadgeDao get badgeDao {
    return _badgeDaoInstance ??= _$BadgeDao(database, changeListener);
  }

  @override
  QuizResultDao get quizResultDao {
    return _quizResultDaoInstance ??= _$QuizResultDao(database, changeListener);
  }

  @override
  ActivityProgressDao get activityProgressDao {
    return _activityProgressDaoInstance ??=
        _$ActivityProgressDao(database, changeListener);
  }

  @override
  DailyCompletionDao get dailyCompletionDao {
    return _dailyCompletionDaoInstance ??=
        _$DailyCompletionDao(database, changeListener);
  }

  @override
  StreakStateDao get streakStateDao {
    return _streakStateDaoInstance ??=
        _$StreakStateDao(database, changeListener);
  }

  @override
  DenDao get denDao {
    return _denDaoInstance ??= _$DenDao(database, changeListener);
  }

  @override
  ResetDao get resetDao {
    return _resetDaoInstance ??= _$ResetDao(database, changeListener);
  }
}

class _$ProgressDao extends ProgressDao {
  _$ProgressDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _progressEntityInsertionAdapter = InsertionAdapter(
            database,
            'progress',
            (ProgressEntity item) => <String, Object?>{
                  'moduleId': item.moduleId,
                  'beatId': item.beatId,
                  'completedAt': item.completedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ProgressEntity> _progressEntityInsertionAdapter;

  @override
  Future<List<ProgressEntity>> findByModule(String moduleId) async {
    return _queryAdapter.queryList('SELECT * FROM progress WHERE moduleId = ?1',
        mapper: (Map<String, Object?> row) => ProgressEntity(
            moduleId: row['moduleId'] as String,
            beatId: row['beatId'] as String,
            completedAt: row['completedAt'] as int),
        arguments: [moduleId]);
  }

  @override
  Future<void> insertProgress(ProgressEntity entity) async {
    await _progressEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }
}

class _$BadgeDao extends BadgeDao {
  _$BadgeDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _badgeEntityInsertionAdapter = InsertionAdapter(
            database,
            'badges',
            (BadgeEntity item) => <String, Object?>{
                  'badgeId': item.badgeId,
                  'moduleId': item.moduleId,
                  'earnedAt': item.earnedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<BadgeEntity> _badgeEntityInsertionAdapter;

  @override
  Future<List<BadgeEntity>> findByModule(String moduleId) async {
    return _queryAdapter.queryList('SELECT * FROM badges WHERE moduleId = ?1',
        mapper: (Map<String, Object?> row) => BadgeEntity(
            badgeId: row['badgeId'] as String,
            moduleId: row['moduleId'] as String,
            earnedAt: row['earnedAt'] as int),
        arguments: [moduleId]);
  }

  @override
  Future<List<BadgeEntity>> findAll() async {
    return _queryAdapter.queryList('SELECT * FROM badges',
        mapper: (Map<String, Object?> row) => BadgeEntity(
            badgeId: row['badgeId'] as String,
            moduleId: row['moduleId'] as String,
            earnedAt: row['earnedAt'] as int));
  }

  @override
  Future<void> insertBadge(BadgeEntity entity) async {
    await _badgeEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }
}

class _$QuizResultDao extends QuizResultDao {
  _$QuizResultDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _quizResultEntityInsertionAdapter = InsertionAdapter(
            database,
            'quiz_results',
            (QuizResultEntity item) => <String, Object?>{
                  'id': item.id,
                  'moduleId': item.moduleId,
                  'quizId': item.quizId,
                  'correctCount': item.correctCount,
                  'totalCount': item.totalCount,
                  'attemptedAt': item.attemptedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<QuizResultEntity> _quizResultEntityInsertionAdapter;

  @override
  Future<List<QuizResultEntity>> findByQuiz(
    String moduleId,
    String quizId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM quiz_results WHERE moduleId = ?1 AND quizId = ?2 ORDER BY attemptedAt DESC',
        mapper: (Map<String, Object?> row) => QuizResultEntity(id: row['id'] as int?, moduleId: row['moduleId'] as String, quizId: row['quizId'] as String, correctCount: row['correctCount'] as int, totalCount: row['totalCount'] as int, attemptedAt: row['attemptedAt'] as int),
        arguments: [moduleId, quizId]);
  }

  @override
  Future<void> insertResult(QuizResultEntity entity) async {
    await _quizResultEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.abort);
  }
}

class _$ActivityProgressDao extends ActivityProgressDao {
  _$ActivityProgressDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _activityProgressEntityInsertionAdapter = InsertionAdapter(
            database,
            'activity_progress',
            (ActivityProgressEntity item) => <String, Object?>{
                  'activityId': item.activityId,
                  'isCompleted': item.isCompleted ? 1 : 0,
                  'bestScore': item.bestScore,
                  'updatedAt': item.updatedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ActivityProgressEntity>
      _activityProgressEntityInsertionAdapter;

  @override
  Future<ActivityProgressEntity?> findByActivity(String activityId) async {
    return _queryAdapter.query(
        'SELECT * FROM activity_progress WHERE activityId = ?1',
        mapper: (Map<String, Object?> row) => ActivityProgressEntity(
            activityId: row['activityId'] as String,
            isCompleted: (row['isCompleted'] as int) != 0,
            bestScore: row['bestScore'] as int?,
            updatedAt: row['updatedAt'] as int),
        arguments: [activityId]);
  }

  @override
  Future<void> insertOrUpdate(ActivityProgressEntity entity) async {
    await _activityProgressEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }
}

class _$DailyCompletionDao extends DailyCompletionDao {
  _$DailyCompletionDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _dailyCompletionEntityInsertionAdapter = InsertionAdapter(
            database,
            'daily_completions',
            (DailyCompletionEntity item) => <String, Object?>{
                  'dateKey': item.dateKey,
                  'challengeId': item.challengeId,
                  'wasCorrect': item.wasCorrect ? 1 : 0,
                  'completedAt': item.completedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DailyCompletionEntity>
      _dailyCompletionEntityInsertionAdapter;

  @override
  Future<DailyCompletionEntity?> findByDate(String dateKey) async {
    return _queryAdapter.query(
        'SELECT * FROM daily_completions WHERE dateKey = ?1',
        mapper: (Map<String, Object?> row) => DailyCompletionEntity(
            dateKey: row['dateKey'] as String,
            challengeId: row['challengeId'] as String,
            wasCorrect: (row['wasCorrect'] as int) != 0,
            completedAt: row['completedAt'] as int),
        arguments: [dateKey]);
  }

  @override
  Future<List<DailyCompletionEntity>> findRecent(int limit) async {
    return _queryAdapter.queryList(
        'SELECT * FROM daily_completions ORDER BY dateKey DESC LIMIT ?1',
        mapper: (Map<String, Object?> row) => DailyCompletionEntity(
            dateKey: row['dateKey'] as String,
            challengeId: row['challengeId'] as String,
            wasCorrect: (row['wasCorrect'] as int) != 0,
            completedAt: row['completedAt'] as int),
        arguments: [limit]);
  }

  @override
  Future<void> insertOrUpdate(DailyCompletionEntity entity) async {
    await _dailyCompletionEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }
}

class _$StreakStateDao extends StreakStateDao {
  _$StreakStateDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _streakStateEntityInsertionAdapter = InsertionAdapter(
            database,
            'streak_state',
            (StreakStateEntity item) => <String, Object?>{
                  'id': item.id,
                  'currentStreak': item.currentStreak,
                  'bestStreak': item.bestStreak,
                  'freezesAvailable': item.freezesAvailable,
                  'lastCompletedDateKey': item.lastCompletedDateKey
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<StreakStateEntity> _streakStateEntityInsertionAdapter;

  @override
  Future<StreakStateEntity?> find() async {
    return _queryAdapter.query('SELECT * FROM streak_state WHERE id = 0',
        mapper: (Map<String, Object?> row) => StreakStateEntity(
            id: row['id'] as int,
            currentStreak: row['currentStreak'] as int,
            bestStreak: row['bestStreak'] as int,
            freezesAvailable: row['freezesAvailable'] as int,
            lastCompletedDateKey: row['lastCompletedDateKey'] as String?));
  }

  @override
  Future<void> save(StreakStateEntity entity) async {
    await _streakStateEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }
}

class _$DenDao extends DenDao {
  _$DenDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _denSlotEntityInsertionAdapter = InsertionAdapter(
            database,
            'den_slots',
            (DenSlotEntity item) => <String, Object?>{
                  'slotId': item.slotId,
                  'stickerId': item.stickerId
                }),
        _denThemeEntityInsertionAdapter = InsertionAdapter(
            database,
            'den_theme',
            (DenThemeEntity item) =>
                <String, Object?>{'id': item.id, 'themeId': item.themeId});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DenSlotEntity> _denSlotEntityInsertionAdapter;

  final InsertionAdapter<DenThemeEntity> _denThemeEntityInsertionAdapter;

  @override
  Future<List<DenSlotEntity>> findAllSlots() async {
    return _queryAdapter.queryList('SELECT * FROM den_slots',
        mapper: (Map<String, Object?> row) => DenSlotEntity(
            slotId: row['slotId'] as String,
            stickerId: row['stickerId'] as String));
  }

  @override
  Future<void> deleteSlot(String slotId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM den_slots WHERE slotId = ?1',
        arguments: [slotId]);
  }

  @override
  Future<DenThemeEntity?> findTheme() async {
    return _queryAdapter.query('SELECT * FROM den_theme WHERE id = 0',
        mapper: (Map<String, Object?> row) => DenThemeEntity(
            id: row['id'] as int, themeId: row['themeId'] as String));
  }

  @override
  Future<void> upsertSlot(DenSlotEntity entity) async {
    await _denSlotEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }

  @override
  Future<void> saveTheme(DenThemeEntity entity) async {
    await _denThemeEntityInsertionAdapter.insert(
        entity, OnConflictStrategy.replace);
  }
}

class _$ResetDao extends ResetDao {
  _$ResetDao(
    this.database,
    this.changeListener,
  ) : _queryAdapter = QueryAdapter(database);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  @override
  Future<void> deleteAllProgress() async {
    await _queryAdapter.queryNoReturn('DELETE FROM progress');
  }

  @override
  Future<void> deleteProgressForModule(String moduleId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM progress WHERE moduleId = ?1',
        arguments: [moduleId]);
  }

  @override
  Future<void> deleteAllQuizResults() async {
    await _queryAdapter.queryNoReturn('DELETE FROM quiz_results');
  }

  @override
  Future<void> deleteQuizResultsForModule(String moduleId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM quiz_results WHERE moduleId = ?1',
        arguments: [moduleId]);
  }

  @override
  Future<void> deleteAllBadges() async {
    await _queryAdapter.queryNoReturn('DELETE FROM badges');
  }

  @override
  Future<void> deleteBadgesForModule(String moduleId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM badges WHERE moduleId = ?1',
        arguments: [moduleId]);
  }

  @override
  Future<void> deleteNonStreakBadges(String streakOwnerId) async {
    await _queryAdapter.queryNoReturn('DELETE FROM badges WHERE moduleId != ?1',
        arguments: [streakOwnerId]);
  }

  @override
  Future<void> deleteAllActivityProgress() async {
    await _queryAdapter.queryNoReturn('DELETE FROM activity_progress');
  }

  @override
  Future<void> deleteAllDailyCompletions() async {
    await _queryAdapter.queryNoReturn('DELETE FROM daily_completions');
  }

  @override
  Future<void> deleteStreakState() async {
    await _queryAdapter.queryNoReturn('DELETE FROM streak_state');
  }

  @override
  Future<void> deleteAllDenSlots() async {
    await _queryAdapter.queryNoReturn('DELETE FROM den_slots');
  }

  @override
  Future<void> deleteDenTheme() async {
    await _queryAdapter.queryNoReturn('DELETE FROM den_theme');
  }

  @override
  Future<void> pruneDenSlotsForModuleBadges(String moduleId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM den_slots WHERE stickerId IN (SELECT badgeId FROM badges WHERE moduleId = ?1)',
        arguments: [moduleId]);
  }

  @override
  Future<void> pruneDenSlotsForNonStreakBadges(String streakOwnerId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM den_slots WHERE stickerId IN (SELECT badgeId FROM badges WHERE moduleId != ?1)',
        arguments: [streakOwnerId]);
  }

  @override
  Future<void> resetLearningProgress(String streakOwnerId) async {
    if (database is sqflite.Transaction) {
      await super.resetLearningProgress(streakOwnerId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.resetDao.resetLearningProgress(streakOwnerId);
      });
    }
  }

  @override
  Future<void> resetSingleModule(String moduleId) async {
    if (database is sqflite.Transaction) {
      await super.resetSingleModule(moduleId);
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.resetDao.resetSingleModule(moduleId);
      });
    }
  }

  @override
  Future<void> resetEverything() async {
    if (database is sqflite.Transaction) {
      await super.resetEverything();
    } else {
      await (database as sqflite.Database)
          .transaction<void>((transaction) async {
        final transactionDatabase = _$AppDatabase(changeListener)
          ..database = transaction;
        await transactionDatabase.resetDao.resetEverything();
      });
    }
  }
}
