import '../../core/error/result.dart';
import '../repositories/reset_repository.dart';

/// Clears all module/activity progress, quiz results, and their badges —
/// keeping the streak, daily-challenge history, and Den intact (aside from
/// pruning any sticker that's no longer earned).
final class ResetLearningProgress {
  const ResetLearningProgress(this._resetRepository);

  final ResetRepository _resetRepository;

  Future<Result<void>> call() => _resetRepository.resetLearningProgress();
}
