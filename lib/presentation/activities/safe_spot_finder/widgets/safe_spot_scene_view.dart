import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../domain/entities/safe_spot_hotspot.dart';
import '../../../../domain/entities/safe_spot_scene.dart';
import '../../../widgets/placeholder_art.dart';
import 'safe_spot_hotspot_overlay.dart';

/// Renders one [SafeSpotScene]'s illustration at a fixed 4:3 aspect ratio,
/// scaled to the available width, with every hotspot positioned from its
/// normalized rect against that same rendered size — the single source of
/// truth for both the visible art and the tap targets, so hit-testing never
/// drifts from what's on screen regardless of device size.
class SafeSpotSceneView extends StatelessWidget {
  const SafeSpotSceneView({
    super.key,
    required this.scene,
    required this.themeColor,
    required this.foundSafeIds,
    required this.lastUnsafeSpotId,
    required this.onTapHotspot,
  });

  static const double _aspectRatio = 4 / 3;

  /// The smallest a hotspot's tappable area may be, regardless of how small
  /// its authored rect is — comfortably reachable by small hands.
  static const double _minTapTarget = 56;

  final SafeSpotScene scene;
  final Color themeColor;
  final Set<String> foundSafeIds;
  final String? lastUnsafeSpotId;
  final void Function(SafeSpotHotspot spot) onTapHotspot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / _aspectRatio;
        final minTap = _minTapTarget.r;

        return ClipRRect(
          borderRadius: AppRadii.borderLg,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PlaceholderArt(
                    assetPath: scene.sceneImage,
                    themeColor: themeColor,
                    fallbackIcon: Icons.image_rounded,
                    width: width,
                    height: height,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                for (final spot in scene.spots) _positionedHotspot(spot, width, height, minTap),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _positionedHotspot(SafeSpotHotspot spot, double sceneWidth, double sceneHeight, double minTap) {
    final tapRect = resolveHotspotRect(spot, Size(sceneWidth, sceneHeight), minTapTarget: minTap);

    return Positioned(
      left: tapRect.left,
      top: tapRect.top,
      width: tapRect.width,
      height: tapRect.height,
      child: SafeSpotHotspotOverlay(
        key: ValueKey(spot.id),
        spot: spot,
        isFound: foundSafeIds.contains(spot.id),
        isWrongFlash: lastUnsafeSpotId == spot.id,
        onTap: () => onTapHotspot(spot),
      ),
    );
  }
}

/// Maps a hotspot's normalized rect to its actual pixel rect at a given
/// rendered scene size, inflating it (around its own centre, so its visual
/// position never shifts) to at least [minTapTarget] on each side. Kept as a
/// pure function — the single source of truth [SafeSpotSceneView] uses to
/// position hotspots, and exercised directly by hit-testing tests without
/// needing to pump a full widget tree.
Rect resolveHotspotRect(SafeSpotHotspot spot, Size sceneSize, {double minTapTarget = SafeSpotSceneView._minTapTarget}) {
  final rect = spot.rect;
  final left = rect.x * sceneSize.width;
  final top = rect.y * sceneSize.height;
  final rawWidth = rect.width * sceneSize.width;
  final rawHeight = rect.height * sceneSize.height;

  final tapWidth = rawWidth < minTapTarget ? minTapTarget : rawWidth;
  final tapHeight = rawHeight < minTapTarget ? minTapTarget : rawHeight;
  final centerX = left + rawWidth / 2;
  final centerY = top + rawHeight / 2;

  return Rect.fromLTWH(centerX - tapWidth / 2, centerY - tapHeight / 2, tapWidth, tapHeight);
}
