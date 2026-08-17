import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import 'language_controller.dart';

class LanguagePage extends GetView<LanguageController> {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showSkyDecoration: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.lg),
              Text('choose_language'.tr, style: AppTextStyles.h1),
              SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LangCard(
                      code: AppConstants.langBn,
                      label: 'বাংলা',
                      emoji: '🇧🇩',
                    ),
                    SizedBox(height: AppSpacing.md),
                    const _LangCard(
                      code: AppConstants.langEn,
                      label: 'English',
                      emoji: '🇬🇧',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: AppButton(label: 'continue'.tr, onPressed: controller.confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    required this.code,
    required this.label,
    required this.emoji,
  });

  final String code;
  final String label;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LanguageController>();
    return Obx(() {
      final isSelected = controller.selected.value == code;
      return Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: () => controller.select(code),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceTint : AppColors.surface,
              borderRadius: AppRadii.borderLg,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 36.sp)),
                SizedBox(width: AppSpacing.md),
                Text(label, style: AppTextStyles.h2),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        ),
      );
    });
  }
}
