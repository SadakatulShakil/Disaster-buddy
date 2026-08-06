import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/den_slot.dart';
import '../../domain/entities/den_state.dart';
import '../../domain/repositories/den_repository.dart';
import '../../domain/services/den_layout.dart';
import '../local/daos/den_dao.dart';
import '../local/entities/den_slot_entity.dart';
import '../local/entities/den_theme_entity.dart';

/// Persists Tuku's Den via Floor: one row per occupied shelf slot, plus a
/// single-row theme choice. Reading always returns exactly one [DenSlot]
/// per [DenLayout.allSlotIds] id, empty or not, so callers never have to
/// special-case a missing row.
final class DenRepositoryImpl implements DenRepository {
  const DenRepositoryImpl(this._denDao);

  final DenDao _denDao;

  @override
  Future<Result<DenState>> getDenState() async {
    try {
      final rows = await _denDao.findAllSlots();
      final stickerIdBySlot = {for (final row in rows) row.slotId: row.stickerId};
      final slots = [
        for (final slotId in DenLayout.allSlotIds) DenSlot(slotId: slotId, placedStickerId: stickerIdBySlot[slotId]),
      ];

      final themeRow = await _denDao.findTheme();
      return Success(DenState(slots: slots, themeId: themeRow?.themeId ?? DenLayout.defaultThemeId));
    } catch (e, st) {
      AppLogger.error('getDenState failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not load Tuku\'s Den.', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> saveDenState(DenState state) async {
    try {
      for (final slot in state.slots) {
        final stickerId = slot.placedStickerId;
        if (stickerId == null) {
          await _denDao.deleteSlot(slot.slotId);
        } else {
          await _denDao.upsertSlot(DenSlotEntity(slotId: slot.slotId, stickerId: stickerId));
        }
      }
      await _denDao.saveTheme(DenThemeEntity(themeId: state.themeId));
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('saveDenState failed', error: e, stackTrace: st);
      return Failure(DatabaseFailure('Could not save Tuku\'s Den.', cause: e, stackTrace: st));
    }
  }
}
