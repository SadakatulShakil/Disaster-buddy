import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Corner-radius scale. Keeps every rounded shape in the app consistent —
/// never write a raw `BorderRadius.circular(n)` in a screen.
class AppRadii {
  AppRadii._();

  static double get sm => 8.r;
  static double get md => 16.r;
  static double get lg => 24.r;
  static double get xl => 32.r;

  /// Fully rounded (pill/circle) — larger than any realistic widget side.
  static double get pill => 999.r;

  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderPill => BorderRadius.circular(pill);
}
