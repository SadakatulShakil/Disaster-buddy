import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/services/den_layout.dart';

/// The colours one free room theme paints Tuku's Den with. Every colour is
/// derived from the shared [AppColors] palette (never a new hex value) so
/// each theme still reads as unmistakably "Bipod Bondhu".
class DenRoomPalette {
  const DenRoomPalette({
    required this.wallTop,
    required this.wallBottom,
    required this.floor,
    required this.rug,
    required this.accent,
  });

  final Color wallTop;
  final Color wallBottom;
  final Color floor;
  final Color rug;
  final Color accent;

  factory DenRoomPalette.forTheme(String themeId) => switch (themeId) {
        'sky' => DenRoomPalette(
            wallTop: AppColors.primary.withValues(alpha: 0.14),
            wallBottom: AppColors.surfaceTint,
            floor: AppColors.primary.withValues(alpha: 0.18),
            rug: AppColors.primary,
            accent: AppColors.primary,
          ),
        'sunset' => DenRoomPalette(
            wallTop: AppColors.accent.withValues(alpha: 0.20),
            wallBottom: AppColors.surfaceTint,
            floor: AppColors.accent.withValues(alpha: 0.24),
            rug: AppColors.accent,
            accent: AppColors.accent,
          ),
        // 'meadow' (DenLayout.defaultThemeId) and any unrecognised id.
        _ => DenRoomPalette(
            wallTop: AppColors.success.withValues(alpha: 0.14),
            wallBottom: AppColors.surfaceTint,
            floor: AppColors.success.withValues(alpha: 0.18),
            rug: AppColors.success,
            accent: AppColors.success,
          ),
      };

  /// Every theme, in [DenLayout.themeIds] order — used to render the theme
  /// picker's swatches.
  static List<(String, DenRoomPalette)> get all => [
        for (final id in DenLayout.themeIds) (id, DenRoomPalette.forTheme(id)),
      ];
}
