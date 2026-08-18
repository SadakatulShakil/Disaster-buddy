import 'package:audioplayers/audioplayers.dart';

import '../utils/app_logger.dart';
import 'user_pref_service.dart';

/// Short, joyful sound effects — separate from [NarrationService], which is
/// speech-only. Registered as a permanent singleton in `InitialBinding`.
///
/// Every clip is independent: a missing/corrupt file only silences that one
/// event (logged once) rather than disabling every other sound, since sfx
/// files may be dropped in gradually. The app MUST run correctly before any
/// clip is bundled — every method degrades to a silent no-op on failure,
/// mirroring `PlaceholderArt`'s "graceful when asset missing" behaviour.
class SoundService {
  SoundService({AudioPlayer Function()? playerFactory}) : _playerFactory = playerFactory ?? AudioPlayer.new;

  static const String _sfxDir = 'audio/sfx';

  final AudioPlayer Function() _playerFactory;
  final Map<String, AudioPlayer> _players = {};
  final Set<String> _failedFiles = {};

  /// Best-effort warm-up so the first real play of each clip isn't the one
  /// that pays the asset-decode cost. Never awaited by callers — a slow or
  /// failing preload must never block app startup.
  Future<void> preload() async {
    for (final fileName in _allFileNames) {
      await _prepare(fileName);
    }
  }

  Future<void> playCorrect() => _play('correct.mp3');
  Future<void> playWrong() => _play('wrong.mp3');
  Future<void> playComplete() => _play('complete.mp3');
  Future<void> playReward() => _play('reward.mp3');
  Future<void> playSticker() => _play('sticker.mp3');

  static const List<String> _allFileNames = [
    'correct.mp3',
    'wrong.mp3',
    'complete.mp3',
    'reward.mp3',
    'sticker.mp3',
  ];

  Future<AudioPlayer?> _prepare(String fileName) async {
    if (_failedFiles.contains(fileName)) return null;
    try {
      final player = _players.putIfAbsent(fileName, () => _playerFactory()..setReleaseMode(ReleaseMode.stop));
      await player.setSourceAsset('$_sfxDir/$fileName');
      return player;
    } catch (e, st) {
      _failedFiles.add(fileName);
      AppLogger.error('SoundService: "$fileName" unavailable — degrading to silent sfx', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> _play(String fileName) async {
    if (!UserPrefService.instance.soundEnabled) return;
    if (_failedFiles.contains(fileName)) return;

    try {
      final player = _players.putIfAbsent(fileName, () => _playerFactory()..setReleaseMode(ReleaseMode.stop));
      await player.stop();
      await player.play(AssetSource('$_sfxDir/$fileName'));
    } catch (e, st) {
      _failedFiles.add(fileName);
      AppLogger.error('SoundService: "$fileName" unavailable — degrading to silent sfx', error: e, stackTrace: st);
    }
  }
}
