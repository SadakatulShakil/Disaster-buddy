import 'dart:async';

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

  /// Ticks every time a new utterance is prepared or narration is stopped
  /// explicitly — lets [speakAndWaitUntilDone] tell its own utterance's
  /// start/completion apart from a differently-timed one still settling
  /// (see its own comment for the exact races this guards against).
  int _utteranceGeneration = 0;

  /// Whether narration is currently playing. UI (e.g. a play/pause button)
  /// can listen to this directly.
  final RxBool isSpeaking = false.obs;

  /// Speaks [text] in [langCode] (one of [AppConstants.langBn]/[langEn]),
  /// at the user's saved narration speed. Fire-and-forget — no-ops if sound
  /// is muted, the text is empty, or the engine already proved unavailable
  /// this session. Prefer [speakAndWaitUntilDone] wherever the caller is
  /// about to advance or replace this speech, so the child always hears it
  /// in full first.
  Future<void> speak(String text, {required String langCode}) async {
    if (!_available || text.isEmpty || !UserPrefService.instance.soundEnabled) return;

    try {
      await _prepare(langCode);
      await _tts.speak(text);
    } catch (e, st) {
      _fail(e, st);
    }
  }

  /// Speaks [text] exactly like [speak], but the returned future resolves
  /// only once the utterance actually finishes (tracked via [isSpeaking]'s
  /// real start/completion callbacks — never a guessed fixed duration), or
  /// immediately if nothing will actually play (muted/unavailable/empty).
  /// Callers that advance/narrate something new afterward MUST await this
  /// instead of racing a fixed timer, or the child's narration gets cut off
  /// mid-sentence.
  ///
  /// Guarded by a generous safety timeout in case a platform completion
  /// callback never arrives, so a flaky TTS engine can never strand the
  /// child on an unresponsive screen.
  ///
  /// Deliberately does NOT return early just because [isSpeaking] still
  /// reads false right after `_tts.speak()` returns — on-device, the
  /// engine's "I've actually started" callback is a genuinely separate,
  /// slightly-later round trip than the method call that requests speech,
  /// so checking the flag at that exact instant can catch it before it
  /// flips. Doing so was the bug behind narration/feedback getting cut off
  /// or skipped almost immediately on real devices despite passing in
  /// tests (a plain in-test fake can satisfy that check synchronously,
  /// masking the race). Instead this always waits for this utterance's own
  /// observed start-then-stop pair, tagging it with [_utteranceGeneration]
  /// so a late `isSpeaking = false` left over from whatever was stopped by
  /// this call's own [_prepare] can't be mistaken for *this* utterance
  /// finishing before it even started.
  Future<void> speakAndWaitUntilDone(String text, {required String langCode}) async {
    if (!_available || text.isEmpty || !UserPrefService.instance.soundEnabled) return;

    Worker? worker;
    try {
      final generation = await _prepare(langCode);

      var started = false;
      final completer = Completer<void>();
      worker = ever<bool>(isSpeaking, (speaking) {
        if (completer.isCompleted) return;
        if (speaking) {
          if (generation == _utteranceGeneration) started = true;
          return;
        }
        // Resolves on this utterance's own completion (started, now
        // stopped), or immediately if a newer call has already superseded
        // this one (its own start/stop can never arrive now).
        if (started || generation != _utteranceGeneration) completer.complete();
      });

      await _tts.speak(text);
      await completer.future.timeout(const Duration(seconds: 20), onTimeout: () {});
    } catch (e, st) {
      _fail(e, st);
    } finally {
      worker?.dispose();
    }
  }

  /// Stops any narration in progress. Safe to call even if nothing is
  /// speaking. Always call this on pause, navigation, and dispose to avoid
  /// overlapping speech.
  Future<void> stop() async {
    isSpeaking.value = false;
    _utteranceGeneration++;
    if (!_available) return;
    try {
      await _tts.stop();
    } catch (e, st) {
      AppLogger.error('NarrationService failed to stop', error: e, stackTrace: st);
    }
  }

  /// Prepares the engine for a new utterance and returns the generation
  /// number now current — every other in-flight [speakAndWaitUntilDone]
  /// call becomes stale the moment this runs, whether it's this method's
  /// own caller or a fire-and-forget [speak] elsewhere.
  Future<int> _prepare(String langCode) async {
    _bindHandlersOnce();
    await _tts.stop();
    await _tts.setLanguage(langCode == AppConstants.langEn ? 'en-US' : 'bn-BD');
    await _tts.setSpeechRate(_speechRateFor(UserPrefService.instance.narrationSpeed));
    return ++_utteranceGeneration;
  }

  void _fail(Object e, StackTrace st) {
    _available = false;
    isSpeaking.value = false;
    AppLogger.error('NarrationService unavailable — degrading to silent lessons', error: e, stackTrace: st);
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
