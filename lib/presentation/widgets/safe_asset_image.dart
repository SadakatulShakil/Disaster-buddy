import 'package:flutter/material.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/theme/app_colors.dart';

/// Renders an illustration from `assets/images/<assetName>`, falling back to
/// a colored placeholder box if the asset is missing. Content manifests
/// reference artwork that lands in later phases, so this must never crash
/// or show Flutter's broken-image error.
class SafeAssetImage extends StatelessWidget {
  const SafeAssetImage({
    super.key,
    required this.assetName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String assetName;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetPaths.image(assetName),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceTint,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: AppColors.textGrey),
      ),
    );
  }
}
