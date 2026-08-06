import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

/// Text styles. Sizes use .sp so they scale via flutter_screenutil.
/// fontFamily is applied globally in AppTheme, so we don't repeat it here.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => TextStyle(
        fontSize: 34.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get h1 => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  static TextStyle get h2 => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get title => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get body => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
        height: 1.4,
      );

  static TextStyle get bodyGrey => body.copyWith(color: AppColors.textGrey);

  static TextStyle get button => TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textGrey,
      );
  static TextStyle get sticker => TextStyle(
    fontSize: 30.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );
}
