import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// The real `FlutterTts` awaits a `MethodChannel` round trip that never
/// resolves in a plain test environment, so exercising it directly hangs
/// instead of throwing. This fake subclass overrides just the methods
/// `NarrationService` calls, bypassing that platform round trip while still
/// simulating the real start/completion handler lifecycle — so
/// `speakAndWaitUntilDone`'s wait-on-completion logic is genuinely
/// exercised rather than short-circuited.
class FakeFlutterTts extends FlutterTts {
  FakeFlutterTts({this.failing = false, this.autoComplete = true});

  /// When true, every call simulates an unavailable TTS engine.
  final bool failing;

  /// When true (the default — right for tests that don't care about the
  /// exact start/completion timing), [speak] fires the start handler
  /// synchronously and schedules the completion handler on a microtask,
  /// simulating a well-behaved engine without any test-side bookkeeping.
  /// Set false to drive [fireStart]/[fireCompletion] manually instead —
  /// needed to reproduce a real device's async start-callback round trip
  /// (see `narration_service_test.dart`).
  final bool autoComplete;

  /// Every string passed to [speak], in call order.
  final List<String> spoken = [];

  @override
  Future<dynamic> setLanguage(String language) async {
    if (failing) throw Exception('simulated tts unavailable');
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    if (failing) throw Exception('simulated tts unavailable');
  }

  @override
  Future<dynamic> stop() async {
    if (failing) throw Exception('simulated tts unavailable');
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    if (failing) throw Exception('simulated tts unavailable');
    spoken.add(text);
    if (!autoComplete) return;
    startHandler?.call();
    // Fires after `speak()` returns (a real device's completion callback
    // arrives well after `speak` is invoked, never before) — via a
    // microtask rather than a Timer, since a `testWidgets` body never fires
    // Timers without an explicit `tester.pump(duration)`, but does drain
    // microtasks normally.
    scheduleMicrotask(() => completionHandler?.call());
  }

  /// Manually fires the "utterance actually started" native callback.
  void fireStart() => startHandler?.call();

  /// Manually fires the "utterance finished" native callback.
  void fireCompletion() => completionHandler?.call();
}
