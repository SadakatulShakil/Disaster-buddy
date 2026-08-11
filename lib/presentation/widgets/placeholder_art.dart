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
    this.width,
    this.height,
    this.borderRadius,
  });

  /// Filename relative to `assets/images/` (e.g. a [HazardModule.iconAsset]).
  final String assetPath;
  final Color themeColor;
  final IconData fallbackIcon;

  /// Square side length. Ignored if [width] or [height] is set.
  final double? size;

  /// Overrides [size] for the horizontal dimension.
  final double? width;

  /// Overrides [size] for the vertical dimension.
  final double? height;
  final BorderRadius? borderRadius;

  double? get _width => width ?? size;
  double? get _height => height ?? size;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadii.borderLg;
    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        AssetPaths.image(assetPath),
        width: _width,
        height: _height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(radius),
      ),
    );
  }

  Widget _fallback(BorderRadius radius) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.15),
        borderRadius: radius,
        border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: themeColor, size: (_height ?? 48.0).clamp(24.0, 96.0) * 0.5),
    );
  }
}
