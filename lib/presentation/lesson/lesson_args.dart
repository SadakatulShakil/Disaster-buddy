/// Navigation arguments for [BeatRunnerPage]/[LessonController].
final class LessonArgs {
  const LessonArgs({
    required this.moduleId,
    required this.startBeatId,
    required this.isReplay,
  });

  final String moduleId;
  final String startBeatId;

  /// True when reviewing a single already-completed beat from ModuleHome —
  /// the lesson shows just that beat and returns, instead of walking
  /// forward through the rest of the module.
  final bool isReplay;
}
