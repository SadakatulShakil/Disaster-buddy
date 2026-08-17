import 'package:equatable/equatable.dart';

import 'kit_item.dart';
import 'safe_spot_scene.dart';
import 'signal_info.dart';

/// The type-specific payload of an [Activity]. Every [ActivityType] has
/// exactly one matching subtype here, mirroring how [Beat] dispatches to
/// [StoryBeat]/[StepsBeat]/[PracticeBeat]/[QuizBeat].
sealed class ActivityContent extends Equatable {
  const ActivityContent();
}

/// Content for the Emergency Kit Builder: drag every correct item into the
/// go-bag.
final class KitBuilderContent extends ActivityContent {
  const KitBuilderContent({required this.items});

  final List<KitItem> items;

  @override
  List<Object?> get props => [items];
}

/// Content for Signal Colours: match each cyclone-warning colour to its
/// meaning and safe action.
final class SignalColoursContent extends ActivityContent {
  const SignalColoursContent({required this.signals});

  final List<SignalInfo> signals;

  @override
  List<Object?> get props => [signals];
}

/// Content for Safe Spot Finder: tap the safe spots in each illustrated
/// scene.
final class SafeSpotContent extends ActivityContent {
  const SafeSpotContent({required this.scenes});

  final List<SafeSpotScene> scenes;

  @override
  List<Object?> get props => [scenes];
}
