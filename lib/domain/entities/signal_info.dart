import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// One cyclone/warning signal inside the Signal Colours activity: a colour
/// (drawn as a swatch in code from [colorHex] — no image needed) paired with
/// its child-simple meaning and safe action.
///
/// NOTE TO CONTENT AUTHOR: the signals bundled in
/// `assets/content/activities/signal_colours.json` are a simplified,
/// age-appropriate approximation for teaching purposes — verify the exact
/// colours/meanings against the real Bangladesh Meteorological Department
/// (BMD) cyclone warning signal system before treating this as authoritative
/// safety guidance.
final class SignalInfo extends Equatable {
  const SignalInfo({
    required this.id,
    required this.colorHex,
    required this.meaning,
    required this.action,
    required this.actionIcon,
    this.affirmation,
    this.feedback,
  });

  final String id;

  /// Hex colour string, e.g. `"#2E9E5B"`. Never hard-code hex in widgets —
  /// parse this via `AppColors.fromHex`.
  final String colorHex;
  final LocalizedText meaning;
  final LocalizedText action;

  /// Placeholder-safe asset filename for a small action icon; see
  /// `PlaceholderArt`.
  final String actionIcon;

  /// Narrated when this signal's meaning is matched correctly.
  final LocalizedText? affirmation;

  /// Specific, kind explanation shown when a wrong meaning is tapped while
  /// this signal is being shown, tying this colour back to its real meaning
  /// and action. Falls back to a generic message when absent.
  final LocalizedText? feedback;

  @override
  List<Object?> get props => [id, colorHex, meaning, action, actionIcon, affirmation, feedback];
}
