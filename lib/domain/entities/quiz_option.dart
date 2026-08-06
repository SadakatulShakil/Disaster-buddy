import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// One answer choice for a [QuizQuestion].
final class QuizOption extends Equatable {
  const QuizOption({
    required this.id,
    this.imageAsset,
    required this.label,
    required this.isCorrect,
  });

  final String id;

  /// Placeholder-safe asset filename; see `SafeAssetImage`. Optional because
  /// some options are text-only.
  final String? imageAsset;
  final LocalizedText label;
  final bool isCorrect;

  @override
  List<Object?> get props => [id, imageAsset, label, isCorrect];
}
