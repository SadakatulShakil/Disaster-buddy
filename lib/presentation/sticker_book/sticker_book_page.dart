import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/collectible_sticker.dart';
import '../widgets/app_button.dart';
import '../widgets/app_empty_view.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import 'sticker_book_controller.dart';
import 'widgets/sticker_tile.dart';

/// Shows every badge the child has earned so far, in a grid. Tapping a
/// badge shows which adventure it came from.
class StickerBookPage extends GetView<StickerBookController> {
  const StickerBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showSkyDecoration: true,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                AppButton(
                  variant: AppButtonVariant.icon,
                  icon: Icons.arrow_back_rounded,
                  color: AppColors.primary,
                  semanticsLabel: 'back'.tr,
                  onPressed: () => Get.back(),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  'sticker_book'.tr,
                  style: AppTextStyles.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              switch (controller.status.value) {
                case StickerBookViewStatus.loading:
                  return const AppLoader();
                case StickerBookViewStatus.error:
                  return AppErrorView(message: controller.errorMessage.value, onRetry: controller.load);
                case StickerBookViewStatus.data:
                  final stickers = controller.earnedStickers;
                  if (stickers.isEmpty) {
                    return AppEmptyView(
                      title: 'empty_stickers_title'.tr,
                      subtitle: 'empty_stickers_subtitle'.tr,
                      icon: Icons.emoji_events_outlined,
                    );
                  }
                  return GridView.builder(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: stickers.length,
                    itemBuilder: (context, index) => StickerTile(
                      sticker: stickers[index],
                      index: index,
                      onTap: () => _showSource(context, stickers[index]),
                    ),
                  );
              }
            }),
          ),
        ],
      ),
    );
  }

  void _showSource(BuildContext context, CollectibleSticker sticker) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;
    final sourceText = switch (sticker.sourceKind) {
      CollectibleSourceKind.streak =>
        'sticker_from_streak'.trParams({'days': '${sticker.streakLength}'}),
      CollectibleSourceKind.module ||
      CollectibleSourceKind.activity =>
        '${'sticker_from'.tr} ${sticker.sourceLabel.resolve(langCode)}',
    };

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sticker.badge.title.resolve(langCode), style: AppTextStyles.h2, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.sm),
              Text(sourceText, style: AppTextStyles.bodyGrey, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'done'.tr,
                color: AppColors.accent,
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
