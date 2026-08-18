import 'package:flutter/material.dart';

/// App-wide constants and keys.
class AppConstants {
  AppConstants._();

  static const String appName = 'Bipod Bondhu';

  // Design size for flutter_screenutil (iPhone X logical size).
  static const Size designSize = Size(375, 812);

  // Locales
  static const String langBn = 'bn';
  static const String langEn = 'en';

  // Hazard ids (Phase 1 content manifests use these).
  static const String hazardFlood = 'flood';
  static const String hazardLightning = 'lightning';
  static const String hazardEarthquake = 'earthquake';

  /// Not a hazard — a caring "helper" module. Always last: it unlocks once
  /// every hazard module is completed.
  static const String hazardFirstAid = 'first_aid';

  static const List<String> initialHazards = [
    hazardEarthquake,
    hazardFlood,
    hazardLightning,
    hazardFirstAid,
  ];

  // Cross-cutting activity ids (Phase 4 manifests, under
  // assets/content/activities/). Module-independent — reachable from their
  // own Activities entry point rather than the Adventure Map's module chain.
  static const String activityEmergencyKit = 'emergency_kit';
  static const String activitySignalColours = 'signal_colours';
  static const String activitySafeSpotFinder = 'safe_spot_finder';
  static const String activityReadTheSky = 'read_the_sky';

  /// Activities with real, loadable manifests. The Activities screen shows
  /// these plus clearly-labelled future stubs that aren't in this list.
  static const List<String> implementedActivities = [
    activityEmergencyKit,
    activitySignalColours,
    activitySafeSpotFinder,
    activityReadTheSky,
  ];

  // Database
  static const String dbName = 'bipod_bondhu.db';

  // Default narration speed for flutter_tts (0.0 - 1.0)
  static const double defaultNarrationSpeed = 0.45;
}

/// SharedPreferences keys (used only inside UserPrefService).
class PrefKeys {
  PrefKeys._();

  static const String isFirstRun = 'is_first_run';
  static const String languageCode = 'language_code';
  static const String soundEnabled = 'sound_enabled';
  static const String narrationSpeed = 'narration_speed';
}
