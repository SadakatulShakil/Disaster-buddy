import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Reusable soft-shadow presets for `BoxDecoration.boxShadow`. Kept gentle
/// and diffuse to match the calm, playful visual identity.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.textDark.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get raised => [
        BoxShadow(
          color: AppColors.textDark.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  /// Barely-there lift, used for pressed/idle button states.
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: AppColors.textDark.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}
