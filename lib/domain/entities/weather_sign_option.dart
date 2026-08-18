import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// One tappable hazard-name choice for a [WeatherSign] — exactly one option
/// per sign is correct.
final class WeatherSignOption extends Equatable {
  const WeatherSignOption({
    required this.id,
    required this.label,
    required this.isCorrect,
  });

  final String id;
  final LocalizedText label;
  final bool isCorrect;

  @override
  List<Object?> get props => [id, label, isCorrect];
}
