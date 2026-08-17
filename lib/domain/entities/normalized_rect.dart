import 'package:equatable/equatable.dart';

/// A rectangle expressed as fractions (0..1) of a scene image's rendered
/// width/height, so a hotspot's position/size is independent of screen size
/// — the presentation layer is the single place that multiplies these back
/// out against an actual rendered image size.
final class NormalizedRect extends Equatable {
  const NormalizedRect({required this.x, required this.y, required this.width, required this.height});

  final double x;
  final double y;
  final double width;
  final double height;

  @override
  List<Object?> get props => [x, y, width, height];
}
