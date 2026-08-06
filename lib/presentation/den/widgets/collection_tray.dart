import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/collectible_sticker.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_view.dart';
import '../den_controller.dart';
import 'collectible_sticker_tile.dart';
import 'den_room_palette.dart';

/// The drawer of every sticker a child can display: earned ones can be
/// dragged out onto a shelf; unearned ones show as a calm locked
/// placeholder with a hint of how to earn them.
///
/// Embedded directly in [DenPage]'s own layout (see its "arrange mode"),
/// *not* shown as a modal sheet or dialog — a modal route sits in front of
/// the whole page and blocks touches to anything behind it, which would
/// make it physically impossible to drag a sticker from here onto a shelf
/// slot on the page underneath.
class CollectionTray extends StatelessWidget {
  const CollectionTray({super.key, required this.controller});

  final DenController controller;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    return Obx(() {
      final collection = controller.collection;
      final earnedCount = collection.where((sticker) => sticker.earned).length;
      final placedIds =
          controller.denState.value?.slots.map((slot) => slot.placedStickerId).whereType<String>().toSet() ??
              const <String>{};

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('den_collection_tray_title'.tr, style: AppTextStyles.h2, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.md),
            if (earnedCount == 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppEmptyView(
                      title: 'empty_stickers_title'.tr,
                      subtitle: 'empty_stickers_subtitle'.tr,
                      icon: Icons.emoji_events_outlined,
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'back_to_map'.tr,
                      icon: Icons.map_rounded,
                      color: AppColors.accent,
                      onPressed: () => Get.offNamed(AppRoutes.home),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final sticker in collection)
                    CollectibleStickerTile(
                      key: ValueKey(sticker.badge.id),
                      sticker: sticker,
                      isPlaced: placedIds.contains(sticker.badge.id),
                      hint: _hintFor(sticker, langCode),
                    ),
                ],
              ),
            SizedBox(height: AppSpacing.lg),
            Text('den_theme_title'.tr, style: AppTextStyles.title, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (themeId, palette) in DenRoomPalette.all)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: _ThemeSwatch(
                      themeId: themeId,
                      palette: palette,
                      selected: controller.denState.value?.themeId == themeId,
                      onTap: () => controller.changeTheme(themeId),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  String _hintFor(CollectibleSticker sticker, String langCode) => switch (sticker.sourceKind) {
        CollectibleSourceKind.streak => 'den_locked_hint_streak'.trParams({'days': '${sticker.streakLength}'}),
        CollectibleSourceKind.module ||
        CollectibleSourceKind.activity =>
          'den_locked_hint'.trParams({'source': sticker.sourceLabel.resolve(langCode)}),
      };
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.themeId, required this.palette, required this.selected, required this.onTap});

  final String themeId;
  final DenRoomPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'den_theme_$themeId'.tr,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.wallTop, palette.floor],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: selected ? palette.accent : AppColors.divider, width: selected ? 3 : 1.5),
          ),
          alignment: Alignment.center,
          child: selected ? Icon(Icons.check_rounded, color: palette.accent, size: 20.sp) : null,
        ),
      ),
    );
  }
}
