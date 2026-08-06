import 'package:equatable/equatable.dart';

import '../services/den_layout.dart';
import 'den_slot.dart';

/// A child's persisted arrangement of Tuku's Den: which earned sticker (if
/// any) sits in each fixed shelf spot, plus the chosen free room theme.
final class DenState extends Equatable {
  const DenState({required this.slots, required this.themeId});

  /// A brand-new child's Den: every shelf spot empty, default theme.
  factory DenState.initial() => DenState(
        slots: [for (final slotId in DenLayout.allSlotIds) DenSlot(slotId: slotId)],
        themeId: DenLayout.defaultThemeId,
      );

  /// Always exactly one entry per [DenLayout.allSlotIds] id.
  final List<DenSlot> slots;
  final String themeId;

  DenState copyWith({List<DenSlot>? slots, String? themeId}) =>
      DenState(slots: slots ?? this.slots, themeId: themeId ?? this.themeId);

  @override
  List<Object?> get props => [slots, themeId];
}
