import '../../core/error/result.dart';
import '../entities/den_state.dart';

/// Read/write access to a child's persisted Tuku's Den arrangement (Floor).
/// Deliberately just get/save-the-whole-state: the specific rules for what
/// makes a placement valid live in the use cases
/// ([PlaceSticker]/[RemoveSticker]/[SetDenTheme]), not here.
abstract interface class DenRepository {
  /// The Den as last saved, or [DenState.initial] if the child has never
  /// customised it.
  Future<Result<DenState>> getDenState();

  /// Persists the full [state] — every shelf slot and the chosen theme.
  Future<Result<void>> saveDenState(DenState state);
}
