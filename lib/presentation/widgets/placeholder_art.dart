import 'package:flutter/material.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/theme/app_radii.dart';

/// Renders artwork for a hazard/beat/badge, themed to that entity's colour.
///
/// Every piece of art in the app should be wrapped in this widget instead of
/// `Image.asset` directly: it tries to load `assetPath` from
/// `assets/images/`, and if the file isn't bundled yet it falls back to a
/// rounded, themed tile with [fallbackIcon] — never a broken-image glyph.
/// Real artwork drops in later under the same filenames with zero screen
/// changes.
class PlaceholderArt extends StatelessWidget {
  const PlaceholderArt({
    super.key,
    required this.assetPath,
    required this.themeColor,
    required this.fallbackIcon,
    this.size,
    this.borderRadius,
  });

  /// Filename relative to `assets/images/` (e.g. a [HazardModule.iconAsset]).
  final String assetPath;
  final Color themeColor;
  final IconData fallbackIcon;
  final double? size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadii.borderLg;
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        AssetPaths.image(assetPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(radius),
      ),
    );
  }

  Widget _fallback(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.15),
        borderRadius: radius,
        border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: themeColor, size: (size ?? 48.0).clamp(24.0, 96.0) * 0.5),
    );
  }
}
