// Phase E2: RemoveSticker must reject unknown slots, clear an occupied
// slot and persist it, and gracefully no-op (still a Success) on an
// already-empty slot.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/den_slot.dart';
import 'package:bipod_bondhu/domain/entities/den_state.dart';
import 'package:bipod_bondhu/domain/usecases/remove_sticker.dart';

import '../../fakes/fake_den_repository.dart';

void main() {
  late FakeDenRepository denRepository;
  late RemoveSticker removeSticker;

  setUp(() {
    denRepository = FakeDenRepository();
    removeSticker = RemoveSticker(denRepository);
  });

  test('rejects an unknown slot id, with no state change', () async {
    final before = denRepository.state;

    final result = await removeSticker('not_a_real_slot');

    expect(result, isA<Failure<DenState>>());
    expect((result as Failure<DenState>).failure, isA<ValidationFailure>());
    expect(denRepository.state, before);
  });

  test('clears an occupied slot and persists it', () async {
    denRepository.state = DenState(
      slots: [
        for (final id in denRepository.state.slots.map((s) => s.slotId))
          DenSlot(slotId: id, placedStickerId: id == 'shelf_1_slot_1' ? 'earthquake_badge' : null),
      ],
      themeId: denRepository.state.themeId,
    );

    final result = await removeSticker('shelf_1_slot_1');

    expect(result, isA<Success<DenState>>());
    expect(denRepository.saveCallCount, 1);
    final slot = denRepository.state.slots.firstWhere((s) => s.slotId == 'shelf_1_slot_1');
    expect(slot.placedStickerId, isNull);
  });

  test('removing from an already-empty slot is a harmless no-op', () async {
    final result = await removeSticker('shelf_1_slot_1');

    expect(result, isA<Success<DenState>>());
  });
}
