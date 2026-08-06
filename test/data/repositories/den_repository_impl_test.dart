// Phase E2: DenRepositoryImpl must round-trip a full DenState through the
// real Floor/sqlite database — every slot's occupant, empty slots read
// back as null (not a missing row crashing the read), and the theme.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/data/local/app_database.dart';
import 'package:bipod_bondhu/data/repositories/den_repository_impl.dart';
import 'package:bipod_bondhu/domain/entities/den_slot.dart';
import 'package:bipod_bondhu/domain/entities/den_state.dart';
import 'package:bipod_bondhu/domain/services/den_layout.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppDatabase database;
  late DenRepositoryImpl repository;

  test('getDenState returns DenState.initial for a brand-new database', () async {
    database = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
    repository = DenRepositoryImpl(database.denDao);
    addTearDown(database.close);

    final result = await repository.getDenState();

    expect(result, isA<Success<DenState>>());
    final state = (result as Success<DenState>).value;
    expect(state.themeId, DenLayout.defaultThemeId);
    expect(state.slots, hasLength(DenLayout.allSlotIds.length));
    expect(state.slots.every((slot) => slot.placedStickerId == null), isTrue);
  });

  test('saveDenState then getDenState round-trips occupied slots and theme', () async {
    database = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
    repository = DenRepositoryImpl(database.denDao);
    addTearDown(database.close);

    final toSave = DenState(
      slots: [
        for (final slotId in DenLayout.allSlotIds)
          DenSlot(
            slotId: slotId,
            placedStickerId: slotId == 'shelf_1_slot_1' ? 'earthquake_badge' : null,
          ),
      ],
      themeId: 'sunset',
    );

    final saveResult = await repository.saveDenState(toSave);
    expect(saveResult, isA<Success<void>>());

    final readResult = await repository.getDenState();
    expect(readResult, isA<Success<DenState>>());
    final readState = (readResult as Success<DenState>).value;

    expect(readState.themeId, 'sunset');
    final occupied = readState.slots.where((slot) => slot.placedStickerId != null).toList();
    expect(occupied, hasLength(1));
    expect(occupied.first.slotId, 'shelf_1_slot_1');
    expect(occupied.first.placedStickerId, 'earthquake_badge');
  });

  test('removing a sticker (saving null) clears its slot on the next read', () async {
    database = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
    repository = DenRepositoryImpl(database.denDao);
    addTearDown(database.close);

    final withSticker = DenState(
      slots: [
        for (final slotId in DenLayout.allSlotIds)
          DenSlot(slotId: slotId, placedStickerId: slotId == 'shelf_2_slot_2' ? 'flood_badge' : null),
      ],
      themeId: DenLayout.defaultThemeId,
    );
    await repository.saveDenState(withSticker);

    final cleared = DenState(
      slots: [for (final slotId in DenLayout.allSlotIds) DenSlot(slotId: slotId)],
      themeId: DenLayout.defaultThemeId,
    );
    await repository.saveDenState(cleared);

    final readResult = await repository.getDenState();
    final readState = (readResult as Success<DenState>).value;
    expect(readState.slots.every((slot) => slot.placedStickerId == null), isTrue);
  });
}
