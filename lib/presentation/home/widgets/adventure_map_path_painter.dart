import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// How far each stop swings from the horizontal center, as an [Alignment] x
/// fraction. Used to position the stop widgets — the connecting path no
/// longer synthesises its own points from this; it's measured instead (see
/// [StopAnchor]), so the two can never drift apart.
const double _kMapStopSwing = 0.56;

/// The horizontal position of the stop at [index] within its layout segment,
/// alternating left/right down the map.
Alignment alignmentForStop(int index) => Alignment(index.isEven ? -_kMapStopSwing : _kMapStopSwing, 0);

/// A module stop's real, measured circle — its center (in the painting
/// [Stack]'s local coordinate space) and outer radius. [AdventureMapPathPainter]
/// draws only between these, so the dashed path always touches exactly
/// where each circle actually is, regardless of text length, font scale, or
/// screen size.
@immutable
class StopAnchor {
  const StopAnchor({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  bool operator ==(Object other) =>
      other is StopAnchor && other.center == center && other.radius == radius;

  @override
  int get hashCode => Object.hash(center, radius);
}

/// Draws a dashed, winding path connecting the module stops on the Adventure
/// Map, using the real measured circle centers/radii in [anchors] — never
/// synthesised positions — so every segment starts and ends exactly at a
/// circle's edge (plus a small gap) and never crosses into any circle.
class AdventureMapPathPainter extends CustomPainter {
  const AdventureMapPathPainter({required this.anchors, required this.color});

  final List<StopAnchor> anchors;
  final Color color;

  /// Small breathing room between the end of a dash and the circle's edge,
  /// so the line visually "touches" the ring instead of butting into it.
  static double get _edgeGap => AppSpacing.xs;

  static const double _strokeWidth = 6;
  static const double _dashLength = 14;
  static const double _dashSpace = 10;

  @override
  void paint(Canvas canvas, Size size) {
    if (anchors.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < anchors.length - 1; i++) {
      final segment = _trimmedSegment(anchors[i], anchors[i + 1]);
      if (segment != null) _drawDashed(canvas, segment, paint);
    }
  }

  /// Builds the full cubic curve between [a]'s and [b]'s centers (matching
  /// the original winding shape), then trims both ends by arc length so the
  /// visible line starts/ends exactly at each circle's edge (+ gap) rather
  /// than at its center.
  Path? _trimmedSegment(StopAnchor a, StopAnchor b) {
    final full = Path()..moveTo(a.center.dx, a.center.dy);
    final midY = (a.center.dy + b.center.dy) / 2;
    full.cubicTo(a.center.dx, midY, b.center.dx, midY, b.center.dx, b.center.dy);

    final metrics = full.computeMetrics().toList();
    if (metrics.isEmpty) return null;
    final metric = metrics.first;
    final length = metric.length;

    final startTrim = (a.radius + _edgeGap).clamp(0.0, length / 2);
    final endTrim = (b.radius + _edgeGap).clamp(0.0, length / 2);
    final start = startTrim;
    final end = (length - endTrim).clamp(start, length);
    if (end <= start) return null;
    return metric.extractPath(start, end);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashLength;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AdventureMapPathPainter oldDelegate) =>
      oldDelegate.anchors != anchors || oldDelegate.color != color;
}
