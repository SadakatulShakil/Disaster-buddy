import 'package:equatable/equatable.dart';

/// One fixed display spot on a shelf in Tuku's Den. [slotId] always matches
/// one of [DenLayout.allSlotIds] — the layout is a bounded, known set of
/// spots rather than a free-canvas position, so a young child never has to
/// place anything with fiddly precision.
final class DenSlot extends Equatable {
  const DenSlot({required this.slotId, this.placedStickerId});

  final String slotId;

  /// The earned badge/sticker id currently displayed here, or null if this
  /// shelf spot is empty.
  final String? placedStickerId;

  @override
  List<Object?> get props => [slotId, placedStickerId];
}
