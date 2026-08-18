import '../../domain/entities/beat.dart';
import '../widgets/mascot_view.dart';

/// Localization key for the brief spoken/shown cue when a beat begins (e.g.
/// "Story time!") — distinct from the persistent type label shown in
/// `beatMeta` (see `module/widgets/beat_stone.dart`).
String beatIntroTrKey(Beat beat) => switch (beat) {
      StoryBeat() => 'beat_intro_story',
      StepsBeat() => 'beat_intro_steps',
      PracticeBeat() => 'beat_intro_practice',
      QuizBeat() => 'beat_intro_quiz',
    };

/// Tuku's mood for that same intro moment.
MascotMood beatIntroMood(Beat beat) => switch (beat) {
      StoryBeat() => MascotMood.point,
      StepsBeat() => MascotMood.point,
      PracticeBeat() => MascotMood.happy,
      QuizBeat() => MascotMood.think,
    };
