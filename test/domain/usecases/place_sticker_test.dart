// Phase E2: PlaceSticker must reject unearned stickers and unknown slots
// (as a Failure, with no state change), accept valid placements and
// persist them, move a sticker rather than duplicate it if it's already
// displayed elsewhere, and swap (not reject) when the target slot is
// already occupied by a different sticker.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/den_state.dart';
import 'package:bipod_bondhu/domain/usecases/place_sticker.dart';

import '../../fakes/fake_den_repository.dart';
import '../../fakes/fake_progress_repository.dart';

void main() {
  late FakeDenRepository denRepository;
  late FakeProgressRepository progressRepository;
  late PlaceSticker placeSticker;

  setUp(() {
    denRepository = FakeDenRepository();
    progressRepository = FakeProgressRepository()..earnedBadgeIds.addAll(['earthquake_badge', 'flood_badge']);
    placeSticker = PlaceSticker(denRepository: denRepository, progressRepository: progressRepository);
  });

  test('rejects a sticker that was never earned, with no state change', () async {
    final before = denRepository.state;

    final result = await placeSticker(slotId: 'shelf_1_slot_1', stickerId: 'lightning_badge');

    expect(result, isA<Failure<DenState>>());
    expect((result as Failure<DenState>).failure, isA<ValidationFailure>());
    expect(denRepository.state, before);
    expect(denRepository.saveCallCount, 0);
  });

  test('rejects an unknown slot id, with no state change', () async {
    final before = denRepository.state;

    final result = await placeSticker(slotId: 'not_a_real_slot', stickerId: 'earthquake_badge');

    expect(result, isA<Failure<DenState>>());
    expect((result as Failure<DenState>).failure, isA<ValidationFailure>());
    expect(denRepository.state, before);
    expect(denRepository.saveCallCount, 0);
  });

  test('accepts a valid placement and persists it', () async {
    final result = await placeSticker(slotId: 'shelf_1_slot_1', stickerId: 'earthquake_badge');

    expect(result, isA<Success<DenState>>());
    expect(denRepository.saveCallCount, 1);
    final slot = denRepository.state.slots.firstWhere((s) => s.slotId == 'shelf_1_slot_1');
    expect(slot.placedStickerId, 'earthquake_badge');
  });

  test('moves a sticker rather than duplicating it across two slots', () async {
    await placeSticker(slotId: 'shelf_1_slot_1', stickerId: 'earthquake_badge');
    await placeSticker(slotId: 'shelf_2_slot_2', stickerId: 'earthquake_badge');

    final placedSlots =
        denRepository.state.slots.where((s) => s.placedStickerId == 'earthquake_badge').map((s) => s.slotId);
    expect(placedSlots, ['shelf_2_slot_2']);
  });

  test('dropping onto an occupied slot swaps rather than rejecting', () async {
    await placeSticker(slotId: 'shelf_1_slot_1', stickerId: 'earthquake_badge');
    final result = await placeSticker(slotId: 'shelf_1_slot_1', stickerId: 'flood_badge');

    expect(result, isA<Success<DenState>>());
    final slot = denRepository.state.slots.firstWhere((s) => s.slotId == 'shelf_1_slot_1');
    expect(slot.placedStickerId, 'flood_badge');
    // The displaced sticker is simply unplaced, not lost or duplicated.
    expect(denRepository.state.slots.where((s) => s.placedStickerId == 'earthquake_badge'), isEmpty);
  });
}
