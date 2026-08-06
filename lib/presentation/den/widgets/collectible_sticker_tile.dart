import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/collectible_sticker.dart';
import '../../widgets/placeholder_art.dart';

/// One tile in the collection tray. Earned stickers are vivid and
/// draggable onto a shelf; unearned ones render as a calm, never-sad
/// greyscale silhouette with a hint of how to earn them — aspirational,
/// not a locked-out failure state.
///
/// Every tile is the exact same fixed size regardless of how much hint
/// text it holds, so the grid always lines up evenly — the label/hint
/// gets up to 3 lines to fit real content (a longer streak hint) rather
/// than a size that only fits the shortest case.
class CollectibleStickerTile extends StatelessWidget {
  const CollectibleStickerTile({super.key, required this.sticker, required this.isPlaced, required this.hint});

  static double get width => 108.r;
  static double get height => 136.r;

  final CollectibleSticker sticker;

  /// Whether this earned sticker is already displayed on a shelf — shown
  /// with a small "placed" mark, but still draggable to move it.
  final bool isPlaced;

  /// Precomposed "Complete X to earn this!" text, only shown when unearned.
  final String hint;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final label = sticker.badge.title.resolve(langCode);

    final card = Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: sticker.earned ? AppColors.accent : AppColors.divider, width: 2),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              sticker.earned
                  ? PlaceholderArt(
                      assetPath: sticker.badge.iconAsset,
                      themeColor: AppColors.accent,
                      fallbackIcon: Icons.auto_awesome_rounded,
                      size: 56.r,
                      borderRadius: AppRadii.borderMd,
                    )
                  // A plain `Opacity` fade, not `ColorFiltered` — with up
                  // to ~9 of these composited at once in the tray's grid,
                  // a saveLayer-heavy filter per tile risks GPU-backend
                  // rendering glitches on some devices; a faded (already
                  // grey-toned via `themeColor`) icon reads the same to a
                  // child without that risk.
                  : Opacity(
                      opacity: 0.35,
                      child: PlaceholderArt(
                        assetPath: sticker.badge.iconAsset,
                        themeColor: AppColors.textGrey,
                        fallbackIcon: Icons.auto_awesome_rounded,
                        size: 56.r,
                        borderRadius: AppRadii.borderMd,
                      ),
                    ),
              if (!sticker.earned) Icon(Icons.lock_rounded, color: AppColors.textGrey, size: 20.sp),
              if (isPlaced)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18.sp),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Text(
              sticker.earned ? label : hint,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final semanticsLabel = sticker.earned ? label : '$label. $hint';

    if (!sticker.earned) {
      return Semantics(label: semanticsLabel, child: card);
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Draggable<CollectibleSticker>(
        data: sticker,
        feedback: Opacity(opacity: 0.85, child: card),
        childWhenDragging: Opacity(opacity: 0.3, child: card),
        child: card,
      ),
    );
  }
}
