import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/den_state.dart';
import 'package:bipod_bondhu/domain/repositories/den_repository.dart';

/// In-memory [DenRepository] test double.
class FakeDenRepository implements DenRepository {
  DenState state = DenState.initial();

  /// Number of times [saveDenState] was actually invoked.
  int saveCallCount = 0;

  @override
  Future<Result<DenState>> getDenState() async => Success(state);

  @override
  Future<Result<void>> saveDenState(DenState newState) async {
    saveCallCount++;
    state = newState;
    return const Success(null);
  }
}
