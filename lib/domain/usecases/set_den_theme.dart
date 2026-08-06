import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../entities/den_state.dart';
import '../repositories/den_repository.dart';
import '../services/den_layout.dart';

/// Switches Tuku's Den to a different free room theme. Rejects (as a
/// friendly [ValidationFailure]) any [themeId] outside [DenLayout.themeIds]
/// — every offered theme is free, so there's no paywall state to guard
/// against, only a stale/unknown id.
final class SetDenTheme {
  const SetDenTheme(this._denRepository);

  final DenRepository _denRepository;

  Future<Result<DenState>> call(String themeId) async {
    if (!DenLayout.themeIds.contains(themeId)) {
      return const Failure(ValidationFailure('That room theme isn\'t available.'));
    }

    final stateResult = await _denRepository.getDenState();
    if (stateResult case Failure<DenState>(failure: final failure)) {
      return Failure(failure);
    }
    final current = (stateResult as Success<DenState>).value;
    final newState = current.copyWith(themeId: themeId);

    final saveResult = await _denRepository.saveDenState(newState);
    if (saveResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }
    return Success(newState);
  }
}
