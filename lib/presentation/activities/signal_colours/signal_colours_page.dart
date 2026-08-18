import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/feedback_bubble.dart';
import '../../widgets/mascot_view.dart';
import '../../widgets/progress_bar.dart';
import 'signal_colours_controller.dart';
import 'widgets/meaning_option_tile.dart';
import 'widgets/signal_colours_complete_summary.dart';
import 'widgets/signal_swatch.dart';

/// Signal Colours: match each cyclone-warning colour to its meaning and safe
/// action. Fully data-driven from the activity's manifest — signals,
/// meanings, actions, and the badge can all change with zero code edits.
class SignalColoursPage extends GetView<SignalColoursController> {
  const SignalColoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case SignalColoursViewStatus.loading:
          return const AppScaffold(body: AppLoader());
        case SignalColoursViewStatus.error:
          return AppScaffold(
            body: AppErrorView(message: controller.errorMessage.value, onRetry: controller.load),
          );
        case SignalColoursViewStatus.data:
          return _SignalColoursBody(controller: controller);
      }
    });
  }
}

class _SignalColoursBody extends StatefulWidget {
  const _SignalColoursBody({required this.controller});

  final SignalColoursController controller;

  @override
  State<_SignalColoursBody> createState() => _SignalColoursBodyState();
}

class _SignalColoursBodyState extends State<_SignalColoursBody> {
  final Rx<MascotMood> _mascotMood = MascotMood.think.obs;
  bool _narratedInstructions = false;
  int? _lastMascotSignalIndex;

  Color get _themeColor => AppColors.fromHex(widget.controller.activity.value!.themeColorHex);

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final themeColor = _themeColor;
    final activity = controller.activity.value!;
    final langCode = Get.locale?.languageCode ?? AppConstants.langBn;

    if (!_narratedInstructions) {
      _narratedInstructions = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.narrate(activity.instructions));
    }

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
                  color: themeColor,
                  semanticsLabel: 'back'.tr,
                  onPressed: () => Get.back(),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    activity.title.resolve(langCode),
                    style: AppTextStyles.h1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isComplete.value) {
                return SignalColoursCompleteSummary(
                  activity: activity,
                  badgeAwarded: controller.badgeAwarded.value,
                  themeColor: themeColor,
                );
              }

              final index = controller.signalIndex.value;
              final signal = controller.currentSignal;
              final options = controller.optionsFor(index);
              final answeredCorrectly = controller.currentAnsweredCorrectly.value;

              if (_lastMascotSignalIndex != index) {
                _lastMascotSignalIndex = index;
                WidgetsBinding.instance.addPostFrameCallback((_) => _mascotMood.value = MascotMood.think);
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'signal_colours_progress'.trParams({
                        'current': '${index + 1}',
                        'total': '${controller.signals.length}',
                      }),
                      style: AppTextStyles.caption,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    ProgressBar(progress: index / controller.signals.length, color: themeColor),
                    SizedBox(height: AppSpacing.md),
                    Obx(() => MascotView(mood: _mascotMood.value, size: 72)),
                    SizedBox(height: AppSpacing.md),
                    SignalSwatch(colorHex: signal.colorHex),
                    SizedBox(height: AppSpacing.md),
                    Text('signal_colours_question'.tr, style: AppTextStyles.h2, textAlign: TextAlign.center),
                    SizedBox(height: AppSpacing.lg),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final option in options)
                          MeaningOptionTile(
                            option: option,
                            themeColor: themeColor,
                            isCorrectReveal: answeredCorrectly && option.id == signal.id,
                            isWrongReveal: controller.lastWrongOptionId.value == option.id,
                            onTap: () {
                              controller.selectOption(option);
                              if (option.id == signal.id) _mascotMood.value = MascotMood.cheer;
                            },
                          ),
                      ],
                    ),
                    Obx(() {
                      final feedback = controller.activeFeedback.value;
                      if (feedback == null) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: AppSpacing.lg),
                        child: FeedbackBubble(
                          message: feedback.message,
                          isCorrect: feedback.isCorrect,
                          onTap: controller.dismissFeedback,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
