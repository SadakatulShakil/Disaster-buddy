import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/repositories/reset_repository.dart';

/// In-memory [ResetRepository] test double. Records which reset was
/// requested; the optional callbacks let a test simulate the real effect
/// (e.g. clearing a paired `FakeProgressRepository`) without needing a
/// real database, so tests can verify a *caller's* reaction (refreshing
/// its own summary) to a successful reset.
class FakeResetRepository implements ResetRepository {
  FakeResetRepository({this.onResetLearningProgress, this.onResetSingleModule, this.onResetEverything});

  final void Function()? onResetLearningProgress;
  final void Function(String moduleId)? onResetSingleModule;
  final void Function()? onResetEverything;

  int resetLearningProgressCallCount = 0;
  final List<String> resetModuleCalls = [];
  int resetEverythingCallCount = 0;

  /// Set to a failure to make the next relevant call return it instead.
  Failure<void>? failureToReturn;

  @override
  Future<Result<void>> resetLearningProgress() async {
    resetLearningProgressCallCount++;
    if (failureToReturn != null) return failureToReturn!;
    onResetLearningProgress?.call();
    return const Success(null);
  }

  @override
  Future<Result<void>> resetSingleModule(String moduleId) async {
    resetModuleCalls.add(moduleId);
    if (failureToReturn != null) return failureToReturn!;
    onResetSingleModule?.call(moduleId);
    return const Success(null);
  }

  @override
  Future<Result<void>> resetEverything() async {
    resetEverythingCallCount++;
    if (failureToReturn != null) return failureToReturn!;
    onResetEverything?.call();
    return const Success(null);
  }
}
