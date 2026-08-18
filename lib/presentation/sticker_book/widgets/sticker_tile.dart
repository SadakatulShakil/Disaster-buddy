import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/collectible_sticker.dart';
import '../../widgets/app_card.dart';
import '../../widgets/placeholder_art.dart';

/// One earned badge in the sticker grid, with a staggered pop/scale-in
/// entrance. Tapping shows which module/activity/streak it came from.
class StickerTile extends StatefulWidget {
  const StickerTile({super.key, required this.sticker, required this.index, required this.onTap});

  final CollectibleSticker sticker;
  final int index;
  final VoidCallback onTap;

  @override
  State<StickerTile> createState() => _StickerTileState();
}

class _StickerTileState extends State<StickerTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppDurations.slow);
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
        return;
      }
      Future.delayed(AppDurations.staggerStep * widget.index, () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final badge = widget.sticker.badge;

    return ScaleTransition(
      scale: _scale,
      child: Semantics(
        button: true,
        label: badge.title.resolve(langCode),
        child: AppCard(
          onTap: widget.onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlaceholderArt(
                assetPath: badge.iconAsset,
                themeColor: AppColors.accent,
                fallbackIcon: Icons.emoji_events_rounded,
                size: 64.r,
                borderRadius: AppRadii.borderPill,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                badge.title.resolve(langCode),
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '🎉',
                style: AppTextStyles.sticker,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
