import 'package:equatable/equatable.dart';

import 'localized_text.dart';
import 'weather_sign_option.dart';

/// One natural early-warning sign inside the Read the Sky activity — a
/// sky/weather cue that comes BEFORE a hazard, paired with 2–3 candidate
/// hazards to tap the right one from.
///
/// NOTE TO CONTENT AUTHOR: the signs bundled in
/// `assets/content/activities/read_the_sky.json` are a simplified,
/// age-appropriate approximation for teaching purposes — verify the exact
/// wording against real Bangladesh Meteorological Department (BMD) guidance
/// before treating this as authoritative safety guidance. Deliberately
/// excludes any "earthquake warning sign" — earthquakes have no reliable
/// pre-warning signs, so inventing one would be inaccurate.
final class WeatherSign extends Equatable {
  const WeatherSign({
    required this.id,
    required this.image,
    required this.description,
    required this.correctHazard,
    required this.options,
    required this.feedback,
    required this.action,
  });

  final String id;

  /// Placeholder-safe asset filename; see `PlaceholderArt`.
  final String image;

  /// Narrated when this sign is first shown, e.g. "Look — the sky is
  /// getting dark and cloudy...".
  final LocalizedText description;

  /// What this sign actually warns about, e.g. "A storm is coming" — shown
  /// alongside [action] once the child taps the matching option correctly.
  final LocalizedText correctHazard;

  final List<WeatherSignOption> options;

  /// Specific, kind explanation shown on any wrong tap while this sign is
  /// being shown, tying it back to what the sign really means.
  final LocalizedText feedback;

  /// The universal safety reinforcement for every sign — "tell a grown-up
  /// right away" — narrated/shown once the correct hazard is matched.
  final LocalizedText action;

  @override
  List<Object?> get props => [id, image, description, correctHazard, options, feedback, action];
}
