import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// One tappable target inside a [PracticeBeat]'s mini-game. A single shape
/// serves every registered game in the `PracticeGameRegistry`, so a new game
/// type never needs a new domain entity:
///  - choice-style games (e.g. tap the correct option) read [isCorrect].
///  - sequence-style games (e.g. tap these in order) read [sequenceOrder].
final class PracticeItem extends Equatable {
  const PracticeItem({
    required this.id,
    required this.label,
    this.imageAsset,
    this.isCorrect = false,
    this.sequenceOrder,
  });

  final String id;
  final LocalizedText label;

  /// Placeholder-safe asset filename; see `PlaceholderArt`. Optional because
  /// some items are label-only.
  final String? imageAsset;

  /// Whether tapping this item is a correct answer in a choice-style game.
  final bool isCorrect;

  /// 1-based position in the correct order for a sequence-style game; null
  /// if this item isn't part of an ordered sequence.
  final int? sequenceOrder;

  @override
  List<Object?> get props => [id, label, imageAsset, isCorrect, sequenceOrder];
}
