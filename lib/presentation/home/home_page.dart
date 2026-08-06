import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/usecases/get_todays_challenge.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/staggered_entrance.dart';
import '../widgets/streak_chip.dart';
import 'home_controller.dart';
import 'widgets/adventure_map_path_painter.dart';
import 'widgets/module_stop.dart';

/// The Adventure Map — the app's home screen. Shows the 3 hazard modules as
/// stops along a winding path, reflecting each module's real
/// available/completed/locked state, plus quick access to the sticker book,
/// settings, and the parent-gated zone.
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showSkyDecoration: true,
      // No AppBar here, and the background is light — dark status-bar icons
      // for contrast (screens with a teal AppBar get light icons instead,
      // via AppTheme's AppBarTheme).
      statusBarStyle: SystemUiOverlayStyle.dark,
      body: Column(
        children: [
          const _HomeTopBar(),
          Expanded(
            child: Obx(() {
              switch (controller.status.value) {
                case HomeViewStatus.loading:
                  return const AppLoader();
                case HomeViewStatus.error:
                  return AppErrorView(
                    message: controller.errorMessage.value,
                    onRetry: controller.loadModules,
                  );
                case HomeViewStatus.data:
                  return _AdventureMapBody(controller: controller);
              }
            }),
          ),
        ],
      ),
    );
  }
}

/// The Adventure Map header: a title + friendly greeting on their own
/// lines (so they never crowd the actions), followed by a single row of 4
/// equally-sized action buttons. Each button is a labelled icon so the row
/// reads clearly to a child, and `Expanded` guarantees the row can never
/// overflow, however narrow the screen.
class _HomeTopBar extends GetView<HomeController> {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('home_title'.tr, style: AppTextStyles.h1),
          SizedBox(height: AppSpacing.xs),
          Text('home_greeting'.tr, style: AppTextStyles.bodyGrey),
          SizedBox(height: AppSpacing.md),
          Obx(() {
            final summary = controller.dailyChallengeSummary.value;
            if (summary == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: _DailyChallengeCard(summary: summary),
            );
          }),
          Row(
            children: [
              Expanded(
                child: _TopBarAction(
                  icon: Icons.backpack_rounded,
                  color: AppColors.primary,
                  labelKey: 'activities',
                  onPressed: () => Get.toNamed(AppRoutes.activities),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TopBarAction(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.accent,
                  labelKey: 'sticker_book',
                  onPressed: () => Get.toNamed(AppRoutes.stickerBook),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Obx(
                  () => _TopBarAction(
                    icon: Icons.cottage_rounded,
                    color: AppColors.success,
                    labelKey: 'tuku_den',
                    showIndicator: controller.hasUnplacedSticker.value,
                    onPressed: () => Get.toNamed(AppRoutes.den),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TopBarAction(
                  icon: Icons.settings_rounded,
                  color: AppColors.primary,
                  labelKey: 'settings',
                  onPressed: () => Get.toNamed(AppRoutes.settings),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TopBarAction(
                  icon: Icons.shield_rounded,
                  color: AppColors.textGrey,
                  labelKey: 'parent_zone',
                  onPressed: () => Get.toNamed(AppRoutes.parentGate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One header action: a consistent, ≥56dp circular [AppButton] (which
/// already provides the shadow + press micro-interaction and its own
/// Semantics) with a short caption underneath for a child who may not
/// recognise the icon alone. The caption is excluded from the semantics
/// tree so screen readers don't announce the label twice.
class _TopBarAction extends StatelessWidget {
  const _TopBarAction({
    required this.icon,
    required this.color,
    required this.labelKey,
    required this.onPressed,
    this.showIndicator = false,
  });

  final IconData icon;
  final Color color;
  final String labelKey;
  final VoidCallback onPressed;

  /// Shows a small dot marking something new waiting behind this action
  /// (e.g. an unplaced sticker in Tuku's Den) — an invitation, never a
  /// countdown or a "you're missing out" nag.
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AppButton(
              variant: AppButtonVariant.icon,
              icon: icon,
              color: color,
              semanticsLabel:
                  showIndicator ? 'den_new_sticker_indicator_semantics'.trParams({'label': labelKey.tr}) : labelKey.tr,
              onPressed: onPressed,
            ),
            if (showIndicator)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 14.r,
                  height: 14.r,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.xs),
        ExcludeSemantics(
          child: Text(
            labelKey.tr,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A prominent, tappable card advertising Tuku's Daily Challenge: shows the
/// current streak plus whether today's challenge is still fresh ("New!")
/// or already done for the day. A single, content-driven row — never a
/// fixed height — so a longer Bangla caption never clips or overflows.
class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.summary});

  final TodaysChallengeResult summary;

  @override
  Widget build(BuildContext context) {
    final done = summary.alreadyCompletedToday;
    return Semantics(
      button: true,
      label: done ? 'daily_challenge_done_semantics'.tr : 'daily_challenge_new_semantics'.tr,
      child: AppCard(
        onTap: () => Get.toNamed(AppRoutes.dailyChallenge),
        child: Row(
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                done ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 28.sp,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'daily_challenge_title'.tr,
                    style: AppTextStyles.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    done ? 'daily_challenge_done_caption'.tr : 'daily_challenge_new_caption'.tr,
                    style: AppTextStyles.bodyGrey,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            StreakChip(streak: summary.streakState),
          ],
        ),
      ),
    );
  }
}

/// The scrollable map body: the stops, plus the dashed connecting path
/// drawn between their *real, measured* bubble edges.
///
/// The path can't be synthesised from layout constants — each stop's
/// widget (icon + title + badge) is a variable, content-driven height, so
/// only an actual post-layout measurement of each bubble's center/radius
/// (see [StopAnchor]) agrees exactly with where the circles are drawn. This
/// widget measures every bubble via [GlobalKey]s for a few frames after
/// each layout (covering the stops' entrance animation settling), then
/// feeds those real anchors to [AdventureMapPathPainter].
class _AdventureMapBody extends StatefulWidget {
  const _AdventureMapBody({required this.controller});

  final HomeController controller;

  @override
  State<_AdventureMapBody> createState() => _AdventureMapBodyState();
}

class _AdventureMapBodyState extends State<_AdventureMapBody> {
  static double get _segmentHeight => 220.r;

  /// How many post-frame measurements to take after a layout — enough to
  /// span the stops' staggered entrance animation settling, so the path
  /// snaps to the exact final positions rather than a mid-animation frame.
  static const int _measurementAttempts = 24;

  final GlobalKey _stackKey = GlobalKey();
  final List<GlobalKey> _bubbleKeys = [];
  List<StopAnchor> _anchors = const [];
  int _measurementsRemaining = 0;
  int? _lastMeasuredModuleCount;

  void _ensureKeys(int count) {
    while (_bubbleKeys.length < count) {
      _bubbleKeys.add(GlobalKey());
    }
    if (_bubbleKeys.length > count) {
      _bubbleKeys.removeRange(count, _bubbleKeys.length);
    }
  }

  void _startMeasuring() {
    _measurementsRemaining = _measurementAttempts;
    _scheduleMeasurement();
  }

  void _scheduleMeasurement() {
    if (_measurementsRemaining <= 0) return;
    _measurementsRemaining--;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      _scheduleMeasurement();
    });
  }

  void _measure() {
    final stackBox = _stackKey.currentContext?.findRenderObject();
    if (stackBox is! RenderBox || !stackBox.attached) return;

    final measured = <StopAnchor>[];
    for (final key in _bubbleKeys) {
      final bubbleBox = key.currentContext?.findRenderObject();
      if (bubbleBox is! RenderBox || !bubbleBox.attached) return;
      final centerGlobal = bubbleBox.localToGlobal(bubbleBox.size.center(Offset.zero));
      measured.add(
        StopAnchor(center: stackBox.globalToLocal(centerGlobal), radius: bubbleBox.size.shortestSide / 2),
      );
    }

    if (!listEquals(measured, _anchors)) {
      setState(() => _anchors = measured);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.controller.modules;
    _ensureKeys(modules.length);
    // Only (re)start the bounded measuring loop when the stop count
    // actually changes (e.g. first load, or a retry with different
    // content) — not on every unrelated rebuild.
    if (_lastMeasuredModuleCount != modules.length) {
      _lastMeasuredModuleCount = modules.length;
      _anchors = const [];
      _startMeasuring();
    }

    final segmentHeight = _segmentHeight;
    final totalHeight = segmentHeight * modules.length;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          key: _stackKey,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AdventureMapPathPainter(
                  anchors: _anchors,
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
            ),
            for (var i = 0; i < modules.length; i++)
              Positioned(
                // No explicit height: the stop sizes to its natural content
                // height instead of being force-fit into segmentHeight, so
                // it never overflows regardless of screen aspect ratio.
                top: segmentHeight * i,
                left: 0,
                right: 0,
                child: Align(
                  alignment: alignmentForStop(i),
                  child: StaggeredEntrance(
                    index: i,
                    child: ModuleStop(
                      bubbleKey: _bubbleKeys[i],
                      module: modules[i],
                      state: widget.controller.stateFor(i),
                      onTap: () => Get.toNamed(AppRoutes.module, arguments: modules[i].id),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
