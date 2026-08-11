import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'doodle_sky_painter.dart';

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
                child: CustomPaint(painter: DoodleSkyPainter()),
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
