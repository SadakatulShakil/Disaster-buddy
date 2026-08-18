import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../widgets/placeholder_art.dart';

/// The current sign's illustration — purely decorative; the page's own
/// narrated description carries the accessible content.
class SkySignImage extends StatelessWidget {
  const SkySignImage({super.key, required this.imageAsset, required this.themeColor, this.size = 180});

  final String imageAsset;
  final Color themeColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.borderLg,
          boxShadow: AppShadows.soft,
        ),
        child: PlaceholderArt(
          assetPath: imageAsset,
          themeColor: themeColor,
          fallbackIcon: Icons.cloud_rounded,
          size: size.r,
          borderRadius: AppRadii.borderLg,
        ),
      ),
    );
  }
}
