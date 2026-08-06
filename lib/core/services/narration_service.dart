import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'user_pref_service.dart';

/// Speaks lesson text aloud via flutter_tts, honoring the current app
/// locale, the user's narration-speed preference, and the sound on/off
/// toggle. Registered as a permanent singleton in `InitialBinding`.
///
/// Every device call is wrapped so a missing TTS engine/voice/language
/// degrades silently after logging once — the lesson stays fully usable via
/// on-screen text, it just never speaks.
class NarrationService {
  NarrationService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _available = true;
  bool _handlersBound = false;

  /// Whether narration is currently playing. UI (e.g. a play/pause button)
  /// can listen to this directly.
  final RxBool isSpeaking = false.obs;

  /// Speaks [text] in [langCode] (one of [AppConstants.langBn]/[langEn]),
  /// at the user's saved narration speed. No-ops if sound is muted, the
  /// text is empty, or the engine already proved unavailable this session.
  Future<void> speak(String text, {required String langCode}) async {
    if (!_available || text.isEmpty || !UserPrefService.instance.soundEnabled) return;

    try {
      _bindHandlersOnce();
      await _tts.stop();
      await _tts.setLanguage(langCode == AppConstants.langEn ? 'en-US' : 'bn-BD');
      await _tts.setSpeechRate(_speechRateFor(UserPrefService.instance.narrationSpeed));
      await _tts.speak(text);
    } catch (e, st) {
      _available = false;
      isSpeaking.value = false;
      AppLogger.error('NarrationService unavailable — degrading to silent lessons', error: e, stackTrace: st);
    }
  }

  /// Stops any narration in progress. Safe to call even if nothing is
  /// speaking. Always call this on pause, navigation, and dispose to avoid
  /// overlapping speech.
  Future<void> stop() async {
    isSpeaking.value = false;
    if (!_available) return;
    try {
      await _tts.stop();
    } catch (e, st) {
      AppLogger.error('NarrationService failed to stop', error: e, stackTrace: st);
    }
  }

  void _bindHandlersOnce() {
    if (_handlersBound) return;
    _handlersBound = true;
    _tts.setStartHandler(() => isSpeaking.value = true);
    _tts.setCompletionHandler(() => isSpeaking.value = false);
    _tts.setCancelHandler(() => isSpeaking.value = false);
    _tts.setErrorHandler((message) {
      isSpeaking.value = false;
      AppLogger.error('NarrationService TTS error: $message');
    });
  }

  /// Maps the 0.0–1.0 `UserPrefService.narrationSpeed` preference to
  /// flutter_tts's platform speech-rate range.
  double _speechRateFor(double preference) => (0.3 + preference.clamp(0.0, 1.0) * 0.5).clamp(0.3, 0.8);
}
