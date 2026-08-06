import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Singleton wrapper over SharedPreferences.
/// Same pattern used across the other RIMES apps.
///
/// Usage:
///   await UserPrefService.instance.init();   // once, in main()
///   UserPrefService.instance.languageCode;
class UserPrefService {
  UserPrefService._();
  static final UserPrefService instance = UserPrefService._();

  late final SharedPreferences _prefs;
  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    _prefs = await SharedPreferences.getInstance();
    _initialised = true;
  }

  // ---- First run ----
  bool get isFirstRun => _prefs.getBool(PrefKeys.isFirstRun) ?? true;
  Future<void> setFirstRunDone() =>
      _prefs.setBool(PrefKeys.isFirstRun, false);

  // ---- Language ----
  /// Null until the user picks a language on first run.
  String? get languageCode => _prefs.getString(PrefKeys.languageCode);
  Future<void> setLanguageCode(String code) =>
      _prefs.setString(PrefKeys.languageCode, code);

  // ---- Sound ----
  bool get soundEnabled => _prefs.getBool(PrefKeys.soundEnabled) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(PrefKeys.soundEnabled, value);

  // ---- Narration speed ----
  double get narrationSpeed =>
      _prefs.getDouble(PrefKeys.narrationSpeed) ??
      AppConstants.defaultNarrationSpeed;
  Future<void> setNarrationSpeed(double value) =>
      _prefs.setDouble(PrefKeys.narrationSpeed, value);
}
