import 'package:equatable/equatable.dart';

import 'localized_text.dart';
import 'safe_spot_hotspot.dart';

/// One illustrated scene inside the Safe Spot Finder activity (e.g. "during
/// an earthquake at home"). Complete once every safe spot in [spots] has
/// been found.
final class SafeSpotScene extends Equatable {
  const SafeSpotScene({
    required this.id,
    required this.sceneImage,
    required this.prompt,
    required this.spots,
  });

  final String id;

  /// Placeholder-safe asset filename; see `PlaceholderArt`.
  final String sceneImage;
  final LocalizedText prompt;
  final List<SafeSpotHotspot> spots;

  int get safeSpotCount => spots.where((spot) => spot.isSafe).length;

  @override
  List<Object?> get props => [id, sceneImage, prompt, spots];
}
