/// Animation-duration scale. Every implicit/explicit animation in the app
/// picks one of these — never write a raw `Duration(milliseconds: n)`.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);

  /// Per-item delay for a staggered list of entrances/pop-ins (grids, etc).
  static const Duration staggerStep = Duration(milliseconds: 80);

  /// One cycle of a fast, attention-drawing loop (e.g. the next-available
  /// Adventure Map stop's pulse).
  static const Duration pulse = Duration(milliseconds: 1200);

  /// One cycle of a slow, ambient idle loop (e.g. the mascot's breathing).
  static const Duration breathing = Duration(seconds: 2);

  /// Minimum time the splash screen stays visible before navigating away.
  static const Duration splashHold = Duration(milliseconds: 1500);

  /// Calm minimum a beat's "Story time!"-style intro cue stays visible for
  /// before its runner mounts — paired with waiting for the cue's own
  /// narration to finish, so it's never a shorter, jarring flash even when
  /// muted.
  static const Duration beatIntroHold = Duration(milliseconds: 1100);
}
