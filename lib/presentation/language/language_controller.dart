import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/user_pref_service.dart';

class LanguageController extends GetxController {
  final _pref = UserPrefService.instance;

  // Default selection = whatever is stored, else Bangla.
  late final RxString selected =
      (_pref.languageCode ?? AppConstants.langBn).obs;

  void select(String code) => selected.value = code;

  Locale _localeFor(String code) => code == AppConstants.langEn
      ? const Locale('en', 'US')
      : const Locale('bn', 'BD');

  Future<void> confirm() async {
    final code = selected.value;
    await _pref.setLanguageCode(code);
    await _pref.setFirstRunDone();

    // Apply immediately across the app.
    Get.updateLocale(_localeFor(code));

    Get.offAllNamed(AppRoutes.home);
  }
}
