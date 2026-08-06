import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/collectible_sticker.dart';
import '../../domain/entities/den_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/mascot_view.dart';
import '../widgets/streak_chip.dart';
import 'den_controller.dart';
import 'widgets/collection_tray.dart';
import 'widgets/den_room_painter.dart';
import 'widgets/den_room_palette.dart';
import 'widgets/den_shelf_slot.dart';

/// Tuku's Den — the child's cozy home screen: a vector-painted room where
/// Tuku lives, and where every earned sticker can be arranged on a shelf.
/// The emotional heart of the daily loop, but never a chore: there's always
/// a calm, natural stopping point, and Tuku never asks the child to stay.
class DenPage extends GetView<DenController> {
  const DenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      statusBarStyle: SystemUiOverlayStyle.dark,
      body: Obx(() {
        switch (controller.status.value) {
          case DenViewStatus.loading:
            return const AppLoader();
          case DenViewStatus.error:
            return AppErrorView(message: controller.errorMessage.value, onRetry: controller.load);
          case DenViewStatus.data:
            return _DenBody(controller: controller);
        }
      }),
    );
  }
}

class _DenBody extends StatefulWidget {
  const _DenBody({required this.controller});

  final DenController controller;

  @override
  State<_DenBody> createState() => _DenBodyState();
}

class _DenBodyState extends State<_DenBody> {
  bool _newStickerBannerDismissed = false;

  /// Whether the sticker tray is open *inline*, alongside the shelves —
  /// never as a modal sheet/dialog. A modal route sits in front of the
  /// whole page and blocks touches to anything behind it, which would make
  /// it physically impossible to drag a sticker from the tray onto a shelf
  /// slot on the page underneath. See [_ArrangingBody].
  bool _isTrayOpen = false;

  void _toggleTray() => setState(() => _isTrayOpen = !_isTrayOpen);

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Obx(() {
      final den = controller.denState.value!;
      final palette = DenRoomPalette.forTheme(den.themeId);
      final showBanner = !_isTrayOpen &&
          !_newStickerBannerDismissed &&
          controller.greetingContext.value == DenGreetingContext.newSticker;
      final byId = {for (final sticker in controller.collection) sticker.badge.id: sticker};

      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: DenRoomPainter(palette: palette))),
          ),
          Column(
            children: [
              _DenHeader(controller: controller),
              Expanded(
                child: _isTrayOpen
                    ? _ArrangingBody(controller: controller, den: den, palette: palette, byId: byId)
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                        child: Column(
                          children: [
                            if (showBanner) ...[
                              _NewStickerBanner(
                                onShowMe: () {
                                  setState(() => _newStickerBannerDismissed = true);
                                  _toggleTray();
                                },
                                onDismiss: () => setState(() => _newStickerBannerDismissed = true),
                              ),
                              SizedBox(height: AppSpacing.md),
                            ],
                            _TukuGreeting(controller: controller),
                            SizedBox(height: AppSpacing.lg),
                            _ShelvesArea(controller: controller, den: den, palette: palette, byId: byId),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: AppButton(
              label: _isTrayOpen ? 'done'.tr : 'den_open_tray_button'.tr,
              icon: _isTrayOpen ? Icons.check_rounded : Icons.style_rounded,
              color: palette.accent,
              onPressed: _toggleTray,
            ),
          ),
        ],
      );
    });
  }
}

/// The "arranging" layout: shelves stay pinned near the top of the screen
/// (always visible, always interactive) with the sticker tray scrollable
/// underneath — both on screen, both able to receive touches, at the same
/// time. That's what dragging a sticker onto a shelf actually requires.
/// Mirrors the Emergency Kit Builder's drop-target-above-item-pool layout.
class _ArrangingBody extends StatelessWidget {
  const _ArrangingBody({required this.controller, required this.den, required this.palette, required this.byId});

  final DenController controller;
  final DenState den;
  final DenRoomPalette palette;
  final Map<String, CollectibleSticker> byId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: _ShelvesArea(controller: controller, den: den, palette: palette, byId: byId),
        ),
        Expanded(child: CollectionTray(controller: controller)),
      ],
    );
  }
}

class _DenHeader extends StatelessWidget {
  const _DenHeader({required this.controller});

  final DenController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'tuku_den'.tr,
              style: AppTextStyles.h1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Obx(() {
            final streak = controller.streakState.value;
            if (streak == null) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.streakChain),
              child: StreakChip(streak: streak),
            );
          }),
        ],
      ),
    );
  }
}

class _TukuGreeting extends StatelessWidget {
  const _TukuGreeting({required this.controller});

  final DenController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => GestureDetector(
            onTap: controller.reactToTuku,
            child: MascotView(mood: controller.mascotMood.value, size: 150),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Obx(() => Text(_greetingText(controller), style: AppTextStyles.h2, textAlign: TextAlign.center)),
      ],
    );
  }

  String _greetingText(DenController controller) {
    final streak = controller.streakState.value;
    switch (controller.greetingContext.value) {
      case DenGreetingContext.newSticker:
        return 'den_greeting_new_sticker'.tr;
      case DenGreetingContext.milestone:
        return 'den_greeting_milestone'.trParams({'days': '${streak?.currentStreak ?? 0}'});
      case DenGreetingContext.returningToday:
        return 'den_greeting_returning'.tr;
      case DenGreetingContext.firstVisitToday:
        return 'den_greeting_first_visit'.tr;
    }
  }
}

class _ShelvesArea extends StatelessWidget {
  const _ShelvesArea({required this.controller, required this.den, required this.palette, required this.byId});

  final DenController controller;
  final DenState den;
  final DenRoomPalette palette;
  final Map<String, CollectibleSticker> byId;

  @override
  Widget build(BuildContext context) {
    final shelves = <List<int>>[];
    for (var i = 0; i < den.slots.length; i += 3) {
      shelves.add([for (var j = i; j < i + 3 && j < den.slots.length; j++) j]);
    }

    return Column(
      children: [
        for (final shelf in shelves)
          Container(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.rug.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16.r),
              border: Border(bottom: BorderSide(color: palette.accent.withValues(alpha: 0.35), width: 4.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final index in shelf)
                  DenShelfSlot(
                    key: ValueKey(den.slots[index].slotId),
                    slot: den.slots[index],
                    placedSticker: den.slots[index].placedStickerId != null
                        ? byId[den.slots[index].placedStickerId]
                        : null,
                    palette: palette,
                    onAccept: (sticker) => controller.placeStickerInSlot(
                      slotId: den.slots[index].slotId,
                      stickerId: sticker.badge.id,
                    ),
                    onRemove: () => controller.removeStickerFromSlot(den.slots[index].slotId),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NewStickerBanner extends StatelessWidget {
  const _NewStickerBanner({required this.onShowMe, required this.onDismiss});

  final VoidCallback onShowMe;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // A solid (not tinted-transparent) surface — this card sits directly
    // over the busy, hand-painted room background, so it needs to be
    // fully opaque or the room's decorations show through distractingly.
    final card = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 28.sp),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'den_new_sticker_banner_title'.tr,
                  style: AppTextStyles.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textGrey,
                onPressed: onDismiss,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: 'den_new_sticker_banner_cta'.tr, color: AppColors.accent, onPressed: onShowMe),
          ),
        ],
      ),
    );

    if (reduceMotion) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: card,
    );
  }
}
