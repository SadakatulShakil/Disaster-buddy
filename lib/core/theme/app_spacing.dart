import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing scale used for every gap/padding in the app. Values use `.r` so
/// a single token scales sanely for both horizontal and vertical gaps —
/// never hard-code a raw gap in a screen.
class AppSpacing {
  AppSpacing._();

  static double get xs => 4.r;
  static double get sm => 8.r;
  static double get md => 16.r;
  static double get lg => 24.r;
  static double get xl => 32.r;
  static double get xxl => 48.r;
}
