import 'package:equatable/equatable.dart';

import 'localized_text.dart';
import 'quiz_option.dart';

/// A single picture question inside a [QuizBeat].
final class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    this.imageAsset,
    required this.options,
  });

  final String id;
  final LocalizedText prompt;

  /// Placeholder-safe asset filename; see `SafeAssetImage`. Optional because
  /// some questions are text-only.
  final String? imageAsset;
  final List<QuizOption> options;

  @override
  List<Object?> get props => [id, prompt, imageAsset, options];
}
