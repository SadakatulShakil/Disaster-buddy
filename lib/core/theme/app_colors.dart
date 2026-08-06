import 'package:flutter/material.dart';

/// Central palette for Bipod Bondhu.
/// Keep every colour here — never hard-code hex values in widgets.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0E7C86); // deep teal
  static const Color primaryDark = Color(0xFF0A5A61);
  static const Color accent = Color(0xFFF2A65A); // warm sand

  // Hazard accents (used by module cards / themes)
  static const Color flood = Color(0xFF2E86C1);
  static const Color lightning = Color(0xFFF4C430);
  static const Color earthquake = Color(0xFFA0522D);

  // Surfaces
  static const Color background = Color(0xFFF3FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFE8F2F3);

  // Text
  static const Color textDark = Color(0xFF1F2A30);
  static const Color textGrey = Color(0xFF5A6B72);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2E9E5B);
  static const Color error = Color(0xFFD9534F);

  // Lines
  static const Color divider = Color(0xFFCBD9DB);

  /// Parses a manifest `themeColor` hex string (e.g. `"#A0522D"`) into a
  /// [Color]. Content manifests carry per-hazard colours as hex — this is
  /// the one place that string gets turned into a real [Color].
  static Color fromHex(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final withAlpha = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.parse(withAlpha, radix: 16));
  }
}
