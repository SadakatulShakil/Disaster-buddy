import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/slide.dart';
import '../../widgets/app_button.dart';
import '../../widgets/placeholder_art.dart';
import '../../widgets/mascot_view.dart' show MascotMood;
import '../lesson_runner_callbacks.dart';

/// Shared runner for [StoryBeat] and [StepsBeat]: swipeable/paged
/// illustrated slides, auto-narrated on entry, with tap-anywhere-to-advance.
/// When [emphasizeSteps] is true (a StepsBeat), each slide is shown as a
/// numbered, highlighted step rather than plain story prose.
class SlidePlayer extends StatefulWidget {
  const SlidePlayer({
    super.key,
    required this.slides,
    required this.themeColor,
    required this.emphasizeSteps,
    required this.callbacks,
  });

  final List<Slide> slides;
  final Color themeColor;
  final bool emphasizeSteps;
  final LessonRunnerCallbacks callbacks;

  @override
  State<SlidePlayer> createState() => _SlidePlayerState();
}

class _SlidePlayerState extends State<SlidePlayer> {
  late final PageController _pageController = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _narrateCurrent());
  }

  @override
  void dispose() {
    widget.callbacks.stopNarration();
    _pageController.dispose();
    super.dispose();
  }

  void _narrateCurrent() {
    widget.callbacks.narrate(widget.slides[_index].text);
    widget.callbacks.setMascotMood(MascotMood.point);
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _narrateCurrent();
  }

  void _goTo(int index) {
    widget.callbacks.stopNarration();
    _pageController.animateToPage(index, duration: AppDurations.normal, curve: Curves.easeOut);
  }

  void _handleAdvance() {
    if (_index == widget.slides.length - 1) {
      widget.callbacks.stopNarration();
      widget.callbacks.setMascotMood(MascotMood.happy);
      widget.callbacks.onBeatFinished();
    } else {
      _goTo(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleAdvance,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.slides.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => _SlideView(
                slide: widget.slides[i],
                stepNumber: widget.emphasizeSteps ? i + 1 : null,
                themeColor: widget.themeColor,
              ),
            ),
          ),
        ),
        _SlideControls(
          themeColor: widget.themeColor,
          callbacks: widget.callbacks,
          currentSlide: widget.slides[_index],
          onPrev: _index > 0 ? () => _goTo(_index - 1) : null,
          onNext: _handleAdvance,
          isLast: _index == widget.slides.length - 1,
        ),
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.stepNumber, required this.themeColor});

  final Slide slide;
  final int? stepNumber;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: AppSpacing.md),
          PlaceholderArt(
            assetPath: slide.imageAsset,
            themeColor: themeColor,
            fallbackIcon: Icons.image_rounded,
            size: 220.r,
            borderRadius: AppRadii.borderLg,
          ),
          SizedBox(height: AppSpacing.lg),
          if (stepNumber != null) ...[
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor),
              alignment: Alignment.center,
              child: Text('$stepNumber', style: AppTextStyles.h2.copyWith(color: AppColors.textOnPrimary)),
            ),
            SizedBox(height: AppSpacing.sm),
          ],
          Text(
            slide.text.resolve(langCode),
            style: stepNumber != null ? AppTextStyles.h2 : AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SlideControls extends StatelessWidget {
  const _SlideControls({
    required this.themeColor,
    required this.callbacks,
    required this.currentSlide,
    required this.onPrev,
    required this.onNext,
    required this.isLast,
  });

  final Color themeColor;
  final LessonRunnerCallbacks callbacks;
  final Slide currentSlide;
  final VoidCallback? onPrev;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppButton(
            variant: AppButtonVariant.icon,
            icon: Icons.arrow_back_ios_new_rounded,
            semanticsLabel: 'back'.tr,
            onPressed: onPrev,
          ),
          SizedBox(width: AppSpacing.sm),
          Obx(
            () => AppButton(
              variant: AppButtonVariant.icon,
              icon: callbacks.isSpeaking.value ? Icons.pause_circle_filled_rounded : Icons.volume_up_rounded,
              color: themeColor,
              semanticsLabel: 'replay'.tr,
              onPressed: () =>
                  callbacks.isSpeaking.value ? callbacks.stopNarration() : callbacks.narrate(currentSlide.text),
            ),
          ),
          const Spacer(),
          AppButton(
            label: isLast ? 'done'.tr : 'next'.tr,
            icon: isLast ? Icons.celebration_rounded : Icons.arrow_forward_rounded,
            color: themeColor,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
