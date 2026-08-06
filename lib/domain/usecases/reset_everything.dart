import '../../core/error/result.dart';
import '../repositories/reset_repository.dart';

/// Wipes every progress/engagement table back to a brand-new child's
/// state — a fresh start. Never touches device preferences.
final class ResetEverything {
  const ResetEverything(this._resetRepository);

  final ResetRepository _resetRepository;

  Future<Result<void>> call() => _resetRepository.resetEverything();
}
