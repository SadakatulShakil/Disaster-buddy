import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/section_header.dart';
import 'settings_controller.dart';

/// Fully functional settings: language, sound, and narration speed, all
/// wired live to [SettingsController] / `UserPrefService` and persisted
/// across restarts.
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          SectionHeader(title: 'language'.tr),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Expanded(
                child: _LanguageOption(code: AppConstants.langBn, label: 'বাংলা', emoji: '🇧🇩'),
              ),
              SizedBox(width: AppSpacing.md),
              const Expanded(
                child: _LanguageOption(code: AppConstants.langEn, label: 'English', emoji: '🇬🇧'),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'sound'.tr),
          SizedBox(height: AppSpacing.sm),
          Obx(
            () => AppCard(
              child: Row(
                children: [
                  const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: Text('sound'.tr, style: AppTextStyles.body)),
                  Switch(
                    value: controller.soundEnabled.value,
                    onChanged: controller.setSoundEnabled,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'narration_speed'.tr),
          SizedBox(height: AppSpacing.sm),
          Obx(
            () => AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('narration_slow'.tr, style: AppTextStyles.caption),
                      Expanded(
                        child: Slider(
                          value: controller.narrationSpeed.value,
                          onChanged: controller.setNarrationSpeed,
                        ),
                      ),
                      Text('narration_fast'.tr, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.code, required this.label, required this.emoji});

  final String code;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return Obx(() {
      final isSelected = controller.languageCode.value == code;
      return Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: () => controller.setLanguage(code),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceTint : AppColors.surface,
              borderRadius: AppRadii.borderLg,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: 28.sp)),
                SizedBox(height: AppSpacing.xs),
                Text(label, style: AppTextStyles.title),
                if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    });
  }
}
