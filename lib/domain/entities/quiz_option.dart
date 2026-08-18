import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// One answer choice for a [QuizQuestion].
final class QuizOption extends Equatable {
  const QuizOption({
    required this.id,
    this.imageAsset,
    required this.label,
    required this.isCorrect,
    this.feedback,
  });

  final String id;

  /// Placeholder-safe asset filename; see `SafeAssetImage`. Optional because
  /// some options are text-only.
  final String? imageAsset;
  final LocalizedText label;
  final bool isCorrect;

  /// Specific, kind explanation shown when this option is tapped — e.g. why
  /// a wrong option isn't safe, tying it back to the right answer. Falls
  /// back to a generic message when absent.
  final LocalizedText? feedback;

  @override
  List<Object?> get props => [id, imageAsset, label, isCorrect, feedback];
}
