import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Themed scaffold used by every screen: safe-area body, brand background,
/// and an optional decorative sky backdrop painted behind the content (no
/// image assets involved, so it never breaks while art is missing).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.showSkyDecoration = false,
    this.backgroundColor,
    this.floatingActionButton,
    this.statusBarStyle,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;

  /// Paints the shared joyful backdrop (gradient sky, faint sparkles,
  /// clouds, and rolling ground) behind [body]. This is the one place that
  /// visual identity lives, so every screen that opts in looks consistent.
  final bool showSkyDecoration;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  /// Overrides the status-bar icon style for this screen. Only needed when
  /// there's no [appBar] to carry it via `AppTheme`'s `AppBarTheme` — e.g. a
  /// light-background screen wants [SystemUiOverlayStyle.dark] (dark
  /// icons), since the app-wide default assumes a teal AppBar.
  final SystemUiOverlayStyle? statusBarStyle;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          if (showSkyDecoration)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _JoyfulSkyPainter()),
              ),
            ),
          SafeArea(child: body),
        ],
      ),
    );

    if (statusBarStyle == null) return scaffold;
    return AnnotatedRegion<SystemUiOverlayStyle>(value: statusBarStyle!, child: scaffold);
  }
}

/// The app's shared decorative backdrop: a soft vertical sky gradient,
/// faint sparkles, a couple of gentle clouds, and layered rolling ground —
/// all vector-drawn (no raster assets) and kept deliberately low-contrast
/// so foreground text/cards stay highly legible. Static and cheap: it never
/// repaints after the first frame.
class _JoyfulSkyPainter extends CustomPainter {
  const _JoyfulSkyPainter();

  /// Fractional (dx, dy) positions for the faint sky sparkles, hand-picked
  /// to sit in the upper, emptier part of the canvas without ever crowding
  /// one spot.
  static const List<Offset> _sparklePositions = [
    Offset(0.12, 0.06),
    Offset(0.85, 0.05),
    Offset(0.55, 0.14),
    Offset(0.30, 0.20),
    Offset(0.70, 0.28),
    Offset(0.15, 0.34),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Soft vertical sky gradient — a touch more tinted at the top,
    // fading toward the near-white horizon.
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.surfaceTint, AppColors.background],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // 2. Faint sparkles, scattered in the upper sky.
    final sparklePaint = Paint()..color = AppColors.accent.withValues(alpha: 0.16);
    for (final fraction in _sparklePositions) {
      _drawSparkle(canvas, sparklePaint, Offset(fraction.dx * size.width, fraction.dy * size.height));
    }

    // 3. Gentle clouds.
    final cloudPaint = Paint()..color = AppColors.surface.withValues(alpha: 0.6);
    _drawCloud(canvas, cloudPaint, Offset(size.width * 0.18, size.height * 0.12), 18);
    _drawCloud(canvas, cloudPaint, Offset(size.width * 0.75, size.height * 0.2), 24);

    // 4. Layered rolling ground — a paler back layer, a slightly deeper
    // front layer, for gentle depth without adding visual noise.
    final backGroundPaint = Paint()..color = AppColors.surfaceTint.withValues(alpha: 0.7);
    canvas.drawPath(_groundPath(size, topFraction: 0.82, dip: 0.05), backGroundPaint);

    final frontGroundPaint = Paint()..color = AppColors.surfaceTint;
    canvas.drawPath(_groundPath(size, topFraction: 0.88, dip: 0.06), frontGroundPaint);
  }

  Path _groundPath(Size size, {required double topFraction, required double dip}) {
    final baseY = size.height * topFraction;
    final dipY = size.height * dip;
    return Path()
      ..moveTo(0, baseY)
      ..quadraticBezierTo(size.width * 0.25, baseY - dipY, size.width * 0.5, baseY)
      ..quadraticBezierTo(size.width * 0.75, baseY + dipY, size.width, baseY - dipY * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset center, double r) {
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center.translate(r * 0.9, r * 0.2), r * 0.7, paint);
    canvas.drawCircle(center.translate(-r * 0.9, r * 0.3), r * 0.6, paint);
  }

  /// A tiny four-pointed sparkle (two crossed teardrops), distinct from the
  /// round clouds so it reads as a twinkle rather than another cloud.
  void _drawSparkle(Canvas canvas, Paint paint, Offset center) {
    const armLength = 7.0;
    const armWidth = 2.2;
    final horizontal = Path()
      ..moveTo(center.dx - armLength, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - armWidth, center.dx + armLength, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + armWidth, center.dx - armLength, center.dy)
      ..close();
    final vertical = Path()
      ..moveTo(center.dx, center.dy - armLength)
      ..quadraticBezierTo(center.dx + armWidth, center.dy, center.dx, center.dy + armLength)
      ..quadraticBezierTo(center.dx - armWidth, center.dy, center.dx, center.dy - armLength)
      ..close();
    canvas.drawPath(horizontal, paint);
    canvas.drawPath(vertical, paint);
  }

  @override
  bool shouldRepaint(covariant _JoyfulSkyPainter oldDelegate) => false;
}
