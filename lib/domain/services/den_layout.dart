/// The fixed, bounded layout of Tuku's Den: a known set of shelf spots and a
/// small pool of free room themes. Kept deliberately small and stable
/// (rather than a free-canvas layout) so placement is always easy for a
/// young child and so [DenSlot] ids stay valid across app updates.
class DenLayout {
  DenLayout._();

  static const int shelfCount = 3;
  static const int slotsPerShelf = 3;

  /// Every valid [DenSlot.slotId], ordered shelf-by-shelf, left to right.
  static const List<String> allSlotIds = [
    'shelf_1_slot_1',
    'shelf_1_slot_2',
    'shelf_1_slot_3',
    'shelf_2_slot_1',
    'shelf_2_slot_2',
    'shelf_2_slot_3',
    'shelf_3_slot_1',
    'shelf_3_slot_2',
    'shelf_3_slot_3',
  ];

  static const String defaultThemeId = 'meadow';

  /// Every free room theme a child can pick, no purchases or paywalls.
  static const List<String> themeIds = ['meadow', 'sky', 'sunset'];
}
