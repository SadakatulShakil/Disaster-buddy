import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/user_pref_service.dart';

/// Live-editable app settings, all persisted via [UserPrefService].
class SettingsController extends GetxController {
  final _pref = UserPrefService.instance;

  late final RxString languageCode = (_pref.languageCode ?? AppConstants.langBn).obs;
  late final RxBool soundEnabled = _pref.soundEnabled.obs;
  late final RxDouble narrationSpeed = _pref.narrationSpeed.obs;

  /// Persists [code] and applies it across the whole app immediately.
  Future<void> setLanguage(String code) async {
    if (code == languageCode.value) return;
    languageCode.value = code;
    await _pref.setLanguageCode(code);
    Get.updateLocale(_localeFor(code));
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled.value = value;
    await _pref.setSoundEnabled(value);
  }

  Future<void> setNarrationSpeed(double value) async {
    narrationSpeed.value = value;
    await _pref.setNarrationSpeed(value);
  }

  Locale _localeFor(String code) =>
      code == AppConstants.langEn ? const Locale('en', 'US') : const Locale('bn', 'BD');
}
