import 'dart:math' as math;
import 'package:flutter/material.dart';

class DoodleSkyPainter extends CustomPainter {
  const DoodleSkyPainter({this.opacity = 0.3, this.seed = 5});

  final double opacity;
  final int seed;

  /// Pastel band palette, top -> bottom, echoing the reference wallpaper.
  /// Swap these for AppColors.* if you want the backdrop to follow the theme.
  static const List<Color> _bands = [
    Color(0xFFF9C9D6), // soft pink
    Color(0xFFEFF3D4), // mint cream
    Color(0xFFFBE9B8), // pale butter
    Color(0xFFF6C4D8), // rose
    Color(0xFFCBD3F0), // periwinkle
  ];

  /// Warm sepia used for every doodle outline.
  static const Color _ink = Color(0xFF8A6A5B);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Soft rainbow bands as a blended vertical gradient.
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [for (final c in _bands) c.withValues(alpha: 0.8)],
      ).createShader(rect);
    canvas.drawRect(rect, bandPaint);

    // 2. Faint polka-dot field over the whole canvas.
    _drawPolkaDots(canvas, size);

    // 3. Scattered outline doodles on an even grid-jitter layout, so nothing
    // clusters and no single spot gets crowded.
    _drawDoodles(canvas, size);
  }

  void _drawPolkaDots(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.35 * 0.8);
    const spacing = 34.0;
    const radius = 2.6;
    for (double y = spacing; y < size.height; y += spacing) {
      // Offset every other row for a hand-scattered feel.
      final rowOffset = (y / spacing).round().isEven ? 0.0 : spacing / 2;
      for (double x = rowOffset; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }
  }

  void _drawDoodles(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final stroke = Paint()
      ..color = _ink.withValues(alpha: 0.55 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    const cols = 4;
    final cellW = size.width / cols;
    final rows = (size.height / cellW).round().clamp(4, 14);
    final cellH = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Jitter within the cell, keeping a margin so shapes don't clip edges.
        final cx = cellW * (c + 0.2 + rng.nextDouble() * 0.6);
        final cy = cellH * (r + 0.2 + rng.nextDouble() * 0.6);
        final s = 10.0 + rng.nextDouble() * 8.0; // motif size
        final angle = (rng.nextDouble() - 0.5) * 0.6; // slight tilt

        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(angle);

        switch (rng.nextInt(5)) {
          case 0:
            _star(canvas, stroke, s);
          case 1:
            _heart(canvas, stroke, s);
          case 2:
            _flower(canvas, stroke, s);
          case 3:
            _swirl(canvas, stroke, s);
          default:
            _dotCluster(canvas, stroke, s);
        }
        canvas.restore();
      }
    }
  }

  void _star(Canvas canvas, Paint p, double s) {
    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? s : s * 0.42; // outer / inner
      final a = -math.pi / 2 + i * math.pi / points;
      final o = Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  void _heart(Canvas canvas, Paint p, double s) {
    final path = Path()
      ..moveTo(0, s * 0.35)
      ..cubicTo(-s, -s * 0.40, -s * 0.5, -s, 0, -s * 0.3)
      ..cubicTo(s * 0.5, -s, s, -s * 0.40, 0, s * 0.35)
      ..close();
    canvas.drawPath(path, p);
  }

  void _flower(Canvas canvas, Paint p, double s) {
    const petals = 5;
    final petalR = s * 0.5;
    for (int i = 0; i < petals; i++) {
      final a = i * 2 * math.pi / petals;
      final center = Offset(math.cos(a) * s * 0.5, math.sin(a) * s * 0.5);
      canvas.drawCircle(center, petalR, p);
    }
    canvas.drawCircle(Offset.zero, s * 0.25, p); // flower centre
  }

  void _swirl(Canvas canvas, Paint p, double s) {
    final path = Path()..moveTo(0, 0);
    const turns = 2.4;
    const steps = 40;
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      final a = t * turns * 2 * math.pi;
      final radius = t * s;
      path.lineTo(math.cos(a) * radius, math.sin(a) * radius);
    }
    canvas.drawPath(path, p);
  }

  void _dotCluster(Canvas canvas, Paint p, double s) {
    final fill = Paint()
      ..color = p.color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-s * 0.4, 0), s * 0.14, fill);
    canvas.drawCircle(Offset(0, -s * 0.2), s * 0.14, fill);
    canvas.drawCircle(Offset(s * 0.4, 0), s * 0.14, fill);
  }

  @override
  bool shouldRepaint(covariant DoodleSkyPainter old) =>
      old.opacity != opacity || old.seed != seed;
}