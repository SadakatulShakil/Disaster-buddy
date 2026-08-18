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
    this.feedback,
  });

  final String id;
  final LocalizedText label;

  /// Placeholder-safe asset filename; see `PlaceholderArt`.
  final String imageAsset;
  final bool isCorrect;

  /// Narrated when this item is placed correctly, e.g. "Water keeps us
  /// safe." Only meaningful for correct items.
  final LocalizedText? affirmation;

  /// Specific, kind explanation shown when this distractor is dropped, e.g.
  /// "A toy is fun, but it won't keep us safe in an emergency." Only
  /// meaningful for incorrect items; falls back to a generic message when
  /// absent.
  final LocalizedText? feedback;

  @override
  List<Object?> get props => [id, label, imageAsset, isCorrect, affirmation, feedback];
}
