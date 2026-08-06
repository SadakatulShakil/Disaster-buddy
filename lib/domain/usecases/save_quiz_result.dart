import '../../core/error/result.dart';
import '../repositories/progress_repository.dart';

/// Records the outcome of one quiz attempt.
final class SaveQuizResult {
  const SaveQuizResult(this._progressRepository);

  final ProgressRepository _progressRepository;

  Future<Result<void>> call({
    required String moduleId,
    required String quizId,
    required int correctCount,
    required int totalCount,
  }) => _progressRepository.saveQuizResult(
        moduleId: moduleId,
        quizId: quizId,
        correctCount: correctCount,
        totalCount: totalCount,
      );
}
