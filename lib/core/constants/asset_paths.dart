/// Centralised asset paths. Never type raw 'assets/...' strings in widgets.
class AssetPaths {
  AssetPaths._();

  static const String _content = 'assets/content';
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _audio = 'assets/audio';
  static const String _animations = 'assets/animations';

  // Content manifests (Phase 1)
  static String manifest(String hazardId) => '$_content/$hazardId.json';

  /// Cross-cutting activity manifest (Phase 4), e.g. the Emergency Kit
  /// Builder — module-independent content living alongside the hazard
  /// manifests under its own subfolder.
  static String activityManifest(String activityId) => '$_content/activities/$activityId.json';

  /// The bundled pool of daily challenges (Phase E1) — a single JSON file
  /// (not one per id, since it's a rotating pool rather than per-hazard
  /// content).
  static const String dailyChallenges = '$_content/daily/daily_challenges.json';

  /// Per-mood Lottie file for [MascotView], e.g. `mascot_idle.json`. Not
  /// bundled yet — `MascotView` falls back to a static image, then a native
  /// animation, while it's absent, so this path resolving to nothing is
  /// expected for now.
  static String mascotAnimation(String moodName) => '$_animations/mascot_$moodName.json';

  /// Per-mood static mascot illustration for [MascotView], e.g.
  /// `tuku_idle.png` — the middle fallback tier, used when no Lottie
  /// animation is bundled for that mood but a static image is.
  static String mascotImage(String moodName) => '$_images/mascot/tuku_$moodName.png';

  // Branding
  static const String mascotTuku = '$_images/tuku.png';
  static const String logo = '$_images/logo.png';

  // Language picker flags
  static const String flagBn = '$_icons/flag_bn.png';
  static const String flagEn = '$_icons/flag_en.png';

  static String image(String name) => '$_images/$name';
  static String icon(String name) => '$_icons/$name';
  static String audio(String name) => '$_audio/$name';
}
