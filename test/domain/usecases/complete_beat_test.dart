import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/module_progress.dart';
import 'package:bipod_bondhu/domain/repositories/progress_repository.dart';
import 'package:bipod_bondhu/domain/usecases/complete_beat.dart';
import 'package:bipod_bondhu/domain/usecases/get_module_progress.dart';

import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_progress_repository.dart';

const _localized = LocalizedText(bn: 'ক', en: 'a');

HazardModule _twoBeatModule() => const HazardModule(
      id: 'earthquake',
      order: 1,
      title: _localized,
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: _localized,
      badge: BadgeInfo(id: 'earthquake_badge', title: _localized, iconAsset: 'badge.png'),
      beats: [
        StoryBeat(id: 'beat_1', order: 1, slides: []),
        StepsBeat(id: 'beat_2', order: 2, slides: []),
      ],
    );

void main() {
  group('CompleteBeat', () {
    late FakeContentRepository contentRepository;
    late FakeProgressRepository progressRepository;
    late CompleteBeat completeBeat;

    setUp(() {
      contentRepository = FakeContentRepository([_twoBeatModule()]);
      progressRepository = FakeProgressRepository();
      completeBeat = CompleteBeat(
        progressRepository: progressRepository,
        getModuleProgress: GetModuleProgress(
          contentRepository: contentRepository,
          progressRepository: progressRepository,
        ),
      );
    });

    test('is not completed after only the first of two beats is done', () async {
      final result = await completeBeat(moduleId: 'earthquake', beatId: 'beat_1');

      expect(result, isA<Success<ModuleProgress>>());
      final progress = (result as Success<ModuleProgress>).value;
      expect(progress.isCompleted, isFalse);
      expect(progress.completedBeatIds, {'beat_1'});
    });

    test('marks the module completed once the last beat is done', () async {
      await completeBeat(moduleId: 'earthquake', beatId: 'beat_1');
      final result = await completeBeat(moduleId: 'earthquake', beatId: 'beat_2');

      expect(result, isA<Success<ModuleProgress>>());
      final progress = (result as Success<ModuleProgress>).value;
      expect(progress.isCompleted, isTrue);
      expect(progress.completedBeatIds, {'beat_1', 'beat_2'});
    });

    test('propagates a failure from the progress repository', () async {
      final failingRepo = _AlwaysFailingProgressRepository();
      final useCase = CompleteBeat(
        progressRepository: failingRepo,
        getModuleProgress: GetModuleProgress(
          contentRepository: contentRepository,
          progressRepository: failingRepo,
        ),
      );

      final result = await useCase(moduleId: 'earthquake', beatId: 'beat_1');

      expect(result, isA<Failure<ModuleProgress>>());
      expect((result as Failure<ModuleProgress>).failure, isA<DatabaseFailure>());
    });
  });
}

class _AlwaysFailingProgressRepository implements ProgressRepository {
  @override
  Future<Result<Set<String>>> getCompletedBeatIds(String moduleId) async => const Success({});

  @override
  Future<Result<void>> markBeatCompleted(String moduleId, String beatId) async =>
      const Failure(DatabaseFailure('boom'));

  @override
  Future<Result<bool>> hasBadge(String moduleId, String badgeId) async => const Success(false);

  @override
  Future<Result<void>> awardBadge(String moduleId, BadgeInfo badge) async => const Success(null);

  @override
  Future<Result<Set<String>>> getAllEarnedBadgeIds() async => const Success({});

  @override
  Future<Result<void>> saveQuizResult({
    required String moduleId,
    required String quizId,
    required int correctCount,
    required int totalCount,
  }) async =>
      const Success(null);
}
