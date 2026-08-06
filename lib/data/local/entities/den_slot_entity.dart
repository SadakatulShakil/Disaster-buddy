import 'package:floor/floor.dart';

/// A row only exists for an *occupied* shelf slot — an empty slot simply
/// has no row, so [stickerId] is never null while a row exists.
@Entity(tableName: 'den_slots', primaryKeys: ['slotId'])
class DenSlotEntity {
  const DenSlotEntity({required this.slotId, required this.stickerId});

  final String slotId;
  final String stickerId;
}
