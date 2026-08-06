import 'practice_game.dart';
import 'sequence_tap_game.dart';
import 'tap_correct_choice_game.dart';

/// Maps a manifest `PracticeBeat.gameId` to its [PracticeGame]. Add a new
/// mini-game by registering it here — nothing else needs to change.
class PracticeGameRegistry {
  PracticeGameRegistry._();

  static final Map<String, PracticeGame> _games = {
    'sequence_tap': const SequenceTapGame(),
    'tap_correct_choice': const TapCorrectChoiceGame(),
  };

  /// Looks up a game by its manifest id. Returns null for an unknown id —
  /// callers must show a friendly fallback rather than crash.
  static PracticeGame? find(String gameId) => _games[gameId];
}
