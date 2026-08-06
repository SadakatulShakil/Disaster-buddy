import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../entities/den_slot.dart';
import '../entities/den_state.dart';
import '../repositories/den_repository.dart';
import '../services/den_layout.dart';

/// Removes whatever sticker is displayed in [slotId], returning it to the
/// collection tray. A no-op (still a [Success]) if the slot was already
/// empty — there's nothing destructive here for a child to worry about.
final class RemoveSticker {
  const RemoveSticker(this._denRepository);

  final DenRepository _denRepository;

  Future<Result<DenState>> call(String slotId) async {
    if (!DenLayout.allSlotIds.contains(slotId)) {
      return const Failure(ValidationFailure('That shelf spot doesn\'t exist.'));
    }

    final stateResult = await _denRepository.getDenState();
    if (stateResult case Failure<DenState>(failure: final failure)) {
      return Failure(failure);
    }
    final current = (stateResult as Success<DenState>).value;

    final newSlots = [
      for (final slot in current.slots) if (slot.slotId == slotId) DenSlot(slotId: slotId) else slot,
    ];
    final newState = current.copyWith(slots: newSlots);

    final saveResult = await _denRepository.saveDenState(newState);
    if (saveResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }
    return Success(newState);
  }
}
