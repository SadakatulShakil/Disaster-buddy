import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_shadows.dart';

/// The current signal's colour, drawn as a plain rounded swatch from its hex
/// value — no image asset needed for the colour itself. Purely decorative;
/// the page's own prompt text carries the accessible description.
class SignalSwatch extends StatelessWidget {
  const SignalSwatch({super.key, required this.colorHex, this.size = 140});

  final String colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(colorHex);
    return ExcludeSemantics(
      child: Container(
        width: size.r,
        height: size.r,
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadii.borderLg,
          border: Border.all(color: AppColors.surface, width: 4),
          boxShadow: AppShadows.soft,
        ),
      ),
    );
  }
}
