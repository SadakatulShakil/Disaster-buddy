import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// A single frame within a [StoryBeat] or [StepsBeat]: an illustration plus
/// narration text that flutter_tts speaks aloud.
final class Slide extends Equatable {
  const Slide({required this.imageAsset, required this.text});

  /// Placeholder-safe asset filename; see `SafeAssetImage`.
  final String imageAsset;
  final LocalizedText text;

  @override
  List<Object?> get props => [imageAsset, text];
}
