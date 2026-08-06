import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../entities/den_slot.dart';
import '../entities/den_state.dart';
import '../repositories/den_repository.dart';
import '../repositories/progress_repository.dart';
import '../services/den_layout.dart';

/// Places an earned sticker into a shelf slot in Tuku's Den, rejecting the
/// change (as a friendly [ValidationFailure], never a crash) if the slot
/// doesn't exist or the sticker was never earned — a child can never end up
/// with an invalid or cheated Den.
///
/// If [stickerId] is already displayed in a different slot, it's moved
/// rather than duplicated. If [slotId] is already occupied by a different
/// sticker, that sticker is simply returned to the collection tray (an
/// intentional, forgiving "swap" — dragging a new sticker onto a full spot
/// never fails).
final class PlaceSticker {
  const PlaceSticker({required DenRepository denRepository, required ProgressRepository progressRepository})
      : _denRepository = denRepository,
        _progressRepository = progressRepository;

  final DenRepository _denRepository;
  final ProgressRepository _progressRepository;

  Future<Result<DenState>> call({required String slotId, required String stickerId}) async {
    if (!DenLayout.allSlotIds.contains(slotId)) {
      return const Failure(ValidationFailure('That shelf spot doesn\'t exist.'));
    }

    final earnedResult = await _progressRepository.getAllEarnedBadgeIds();
    if (earnedResult case Failure<Set<String>>(failure: final failure)) {
      return Failure(failure);
    }
    final earnedIds = (earnedResult as Success<Set<String>>).value;
    if (!earnedIds.contains(stickerId)) {
      return const Failure(ValidationFailure('This sticker hasn\'t been earned yet.'));
    }

    final stateResult = await _denRepository.getDenState();
    if (stateResult case Failure<DenState>(failure: final failure)) {
      return Failure(failure);
    }
    final current = (stateResult as Success<DenState>).value;

    final newSlots = [
      for (final slot in current.slots)
        if (slot.slotId == slotId)
          DenSlot(slotId: slotId, placedStickerId: stickerId)
        else if (slot.placedStickerId == stickerId)
          DenSlot(slotId: slot.slotId)
        else
          slot,
    ];
    final newState = current.copyWith(slots: newSlots);

    final saveResult = await _denRepository.saveDenState(newState);
    if (saveResult case Failure<void>(failure: final failure)) {
      return Failure(failure);
    }
    return Success(newState);
  }
}
