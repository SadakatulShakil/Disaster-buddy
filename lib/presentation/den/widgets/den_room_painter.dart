import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'den_room_palette.dart';

/// Tuku's cozy room, entirely vector-drawn: soft walls, a window onto the
/// same playful sky as the Adventure Map, and a rug on the floor. No raster
/// assets involved, so the room always renders crisply while any real
/// decorative art is still being made. Static and cheap — never repaints
/// after the first frame.
class DenRoomPainter extends CustomPainter {
  const DenRoomPainter({required this.palette});

  final DenRoomPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Wall — a soft vertical gradient, themed per room.
    final wallPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.wallTop, palette.wallBottom],
      ).createShader(rect);
    canvas.drawRect(rect, wallPaint);

    // 2. Floor — a warm band along the bottom.
    final floorTop = size.height * 0.78;
    canvas.drawRect(Rect.fromLTRB(0, floorTop, size.width, size.height), Paint()..color = palette.floor);

    // 3. Window — a rounded rect with its own tiny sky + a cloud, centered
    // in the upper wall. Kept below ~0.20 of the height so it always
    // clears the header row painted on top of it (the header has no
    // opaque background of its own) — the "new sticker" banner card,
    // which can also sit in this band, is fully opaque so it never lets
    // this show through either.
    final windowWidth = size.width * 0.38;
    final windowHeight = size.height * 0.14;
    final windowRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.22),
      width: windowWidth,
      height: windowHeight,
    );
    final windowRRect = RRect.fromRectAndRadius(windowRect, Radius.circular(windowHeight * 0.3));
    canvas.drawRRect(
      windowRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceTint, AppColors.surface],
        ).createShader(windowRect),
    );
    _drawCloud(canvas, Paint()..color = palette.accent.withValues(alpha: 0.35), windowRect.center, windowHeight * 0.22);
    canvas.drawRRect(
      windowRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = palette.accent.withValues(alpha: 0.5),
    );

    // 4. Rug — a soft oval on the floor.
    final rugRect = Rect.fromCenter(
      center: Offset(size.width / 2, floorTop + (size.height - floorTop) * 0.55),
      width: size.width * 0.55,
      height: (size.height - floorTop) * 0.5,
    );
    canvas.drawOval(rugRect, Paint()..color = palette.rug.withValues(alpha: 0.28));
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset center, double r) {
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center.translate(r * 0.9, r * 0.15), r * 0.65, paint);
    canvas.drawCircle(center.translate(-r * 0.9, r * 0.2), r * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant DenRoomPainter oldDelegate) => oldDelegate.palette != palette;
}
