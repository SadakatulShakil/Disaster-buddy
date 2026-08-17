import 'package:equatable/equatable.dart';

import 'localized_text.dart';
import 'normalized_rect.dart';

/// One tappable spot inside a [SafeSpotScene] — either a safe place to be
/// (isSafe) or an unsafe one the child learns to avoid, with a kind
/// explanation either way.
final class SafeSpotHotspot extends Equatable {
  const SafeSpotHotspot({
    required this.id,
    required this.rect,
    required this.isSafe,
    required this.label,
    required this.feedback,
  });

  final String id;
  final NormalizedRect rect;
  final bool isSafe;
  final LocalizedText label;

  /// Narrated and shown when this spot is tapped — a cheer for a safe spot,
  /// or a gentle, kind explanation for an unsafe one. Never a penalty.
  final LocalizedText feedback;

  @override
  List<Object?> get props => [id, rect, isSafe, label, feedback];
}
