import '../../core/error/result.dart';
import '../entities/den_state.dart';
import '../repositories/den_repository.dart';

/// Loads the child's current Tuku's Den arrangement.
final class GetDenState {
  const GetDenState(this._denRepository);

  final DenRepository _denRepository;

  Future<Result<DenState>> call() => _denRepository.getDenState();
}
