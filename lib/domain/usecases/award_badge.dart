import '../../core/error/result.dart';
import '../entities/badge_info.dart';
import '../repositories/progress_repository.dart';

/// Records that a badge was earned for a module.
final class AwardBadge {
  const AwardBadge(this._progressRepository);

  final ProgressRepository _progressRepository;

  Future<Result<void>> call({
    required String moduleId,
    required BadgeInfo badge,
  }) => _progressRepository.awardBadge(moduleId, badge);
}
