import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is created so onReady fires.
    controller;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mascot placeholder — swap for Tuku artwork / Lottie later.
            Container(
              width: 140.w,
              height: 140.w,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('🐯', style: TextStyle(fontSize: 64.sp)),
            ),
            SizedBox(height: 24.h),
            Text(
              'app_name'.tr,
              style: AppTextStyles.display.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'app_tagline'.tr,
              style: AppTextStyles.body.copyWith(
                color: AppColors.surfaceTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
