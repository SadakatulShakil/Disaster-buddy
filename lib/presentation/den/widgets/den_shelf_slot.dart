import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../domain/entities/collectible_sticker.dart';
import '../../../domain/entities/den_slot.dart';
import '../../widgets/placeholder_art.dart';
import 'den_room_palette.dart';

/// One fixed shelf spot: a [DragTarget] that accepts an earned
/// [CollectibleSticker] dropped from the collection tray, and — when
/// occupied — is itself the (>=56dp) tap target to send that sticker back
/// to the tray. Dropping onto an already-occupied spot swaps it rather than
/// rejecting the drop, so a young child never hits a "no" while dragging.
class DenShelfSlot extends StatelessWidget {
  const DenShelfSlot({
    super.key,
    required this.slot,
    required this.placedSticker,
    required this.palette,
    required this.onAccept,
    required this.onRemove,
  });

  final DenSlot slot;

  /// The sticker currently shown here, resolved from [DenSlot.placedStickerId]
  /// — null when the slot is empty.
  final CollectibleSticker? placedSticker;
  final DenRoomPalette palette;
  final void Function(CollectibleSticker sticker) onAccept;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    return DragTarget<CollectibleSticker>(
      onWillAcceptWithDetails: (details) => details.data.earned,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final sticker = placedSticker;

        return Semantics(
          button: sticker != null,
          label: sticker != null
              ? 'den_slot_filled_semantics'.trParams({'sticker': sticker.badge.title.resolve(langCode)})
              : 'den_slot_empty_semantics'.tr,
          child: GestureDetector(
            onTap: sticker != null ? onRemove : null,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: sticker != null
                    ? AppColors.surface
                    : palette.accent.withValues(alpha: isHovering ? 0.24 : 0.08),
                borderRadius: AppRadii.borderMd,
                border: Border.all(
                  color: isHovering ? palette.accent : palette.accent.withValues(alpha: 0.4),
                  width: isHovering ? 3 : 2,
                ),
              ),
              alignment: Alignment.center,
              child: sticker != null
                  ? PlaceholderArt(
                      assetPath: sticker.badge.iconAsset,
                      themeColor: palette.accent,
                      fallbackIcon: Icons.auto_awesome_rounded,
                      size: 56.r,
                      borderRadius: AppRadii.borderMd,
                    )
                  : Icon(Icons.add_rounded, color: palette.accent.withValues(alpha: 0.5), size: 24.sp),
            ),
          ),
        );
      },
    );
  }
}
