import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// One draggable card in the Emergency Kit Builder (or any future
/// item-sorting activity): a labelled, illustrated item that either belongs
/// in the kit ([isCorrect]) or is a distractor.
final class KitItem extends Equatable {
  const KitItem({
    required this.id,
    required this.label,
    required this.imageAsset,
    required this.isCorrect,
    this.affirmation,
  });

  final String id;
  final LocalizedText label;

  /// Placeholder-safe asset filename; see `PlaceholderArt`.
  final String imageAsset;
  final bool isCorrect;

  /// Narrated when this item is placed correctly, e.g. "Water keeps us
  /// safe." Only meaningful for correct items.
  final LocalizedText? affirmation;

  @override
  List<Object?> get props => [id, label, imageAsset, isCorrect, affirmation];
}
