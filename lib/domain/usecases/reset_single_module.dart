import '../../core/error/result.dart';
import '../repositories/reset_repository.dart';

/// Clears one hazard module's progress, quiz results, and badge. The
/// Adventure Map's unlock chain is never separately updated — it's always
/// derived live from progress, so any module that depended on this one
/// being completed re-locks automatically on the next load.
final class ResetSingleModule {
  const ResetSingleModule(this._resetRepository);

  final ResetRepository _resetRepository;

  Future<Result<void>> call(String moduleId) => _resetRepository.resetSingleModule(moduleId);
}
