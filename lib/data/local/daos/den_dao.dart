import 'package:floor/floor.dart';

import '../entities/den_slot_entity.dart';
import '../entities/den_theme_entity.dart';

@dao
abstract class DenDao {
  @Query('SELECT * FROM den_slots')
  Future<List<DenSlotEntity>> findAllSlots();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> upsertSlot(DenSlotEntity entity);

  @Query('DELETE FROM den_slots WHERE slotId = :slotId')
  Future<void> deleteSlot(String slotId);

  @Query('SELECT * FROM den_theme WHERE id = 0')
  Future<DenThemeEntity?> findTheme();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> saveTheme(DenThemeEntity entity);
}
