// Regression test: children reported narration and feedback getting cut off
// or skipped almost instantly on real devices — the intro cue's "Story
// time!" banner, and the wrong/correct feedback bubble, all vanished before
// their own narration had actually finished. `speakAndWaitUntilDone` was
// checking `isSpeaking.value` right after `_tts.speak()` returned to decide
// whether to wait at all, but a real engine's "I've actually started"
// callback is a separate, slightly-later round trip than the method call
// requesting speech — so the check could catch it before it flips, skipping
// the wait entirely. A second, related race: a delayed cancel/completion
// callback left over from whatever `_prepare` just stopped could arrive
// after the new utterance's own wait started, resolving it immediately
// before the new utterance even began. Both only show up with a fake that
// simulates the real async round trip — a fake that fires its callbacks
// synchronously (as this project's shared `FakeFlutterTts` does by default)
// satisfies the old buggy check by coincidence and hides the bug.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/services/narration_service.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';

import '../../fakes/fake_flutter_tts.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  testWidgets('waits for the real completion callback even when the start callback arrives late',
      (tester) async {
    final tts = FakeFlutterTts(autoComplete: false);
    final service = NarrationService(tts: tts);

    var resolved = false;
    final future = service.speakAndWaitUntilDone('hello', langCode: 'en').then((_) => resolved = true);

    // Let `_tts.speak()` return without firing either callback yet —
    // simulating the real device's start-callback still being in flight.
    await tester.pump();
    expect(resolved, isFalse, reason: 'must not resolve before the engine even reports starting');

    tts.fireStart();
    await tester.pump();
    expect(resolved, isFalse, reason: 'must not resolve while still genuinely speaking');

    tts.fireCompletion();
    await future;
    expect(resolved, isTrue);
  });

  testWidgets('a leftover cancel callback from the previous utterance cannot resolve the new wait early',
      (tester) async {
    final tts = FakeFlutterTts(autoComplete: false);
    final service = NarrationService(tts: tts);

    // First utterance genuinely starts speaking — its own completion is
    // left to arrive late, after the second call below has already begun
    // preparing (exactly what happens when `_prepare`'s own `_tts.stop()`
    // cancels a still-playing utterance).
    await service.speak('first', langCode: 'en');
    tts.fireStart();
    await tester.pump();

    var secondResolved = false;
    final second =
        service.speakAndWaitUntilDone('world', langCode: 'en').then((_) => secondResolved = true);
    await tester.pump();

    // The stale cancel for the FIRST utterance arrives only now.
    tts.fireCompletion();
    await tester.pump();
    expect(secondResolved, isFalse, reason: 'a stale event from the previous utterance must be ignored');

    // The second utterance's own start/completion arrive next.
    tts.fireStart();
    await tester.pump();
    expect(secondResolved, isFalse);

    tts.fireCompletion();
    await second;
    expect(secondResolved, isTrue);
  });

  testWidgets('an explicit stop() call unblocks any in-flight wait instead of stranding it', (tester) async {
    final tts = FakeFlutterTts(autoComplete: false);
    final service = NarrationService(tts: tts);

    var resolved = false;
    final future = service.speakAndWaitUntilDone('hello', langCode: 'en').then((_) => resolved = true);
    await tester.pump();

    tts.fireStart();
    await tester.pump();
    expect(resolved, isFalse);

    await service.stop();
    await future;
    expect(resolved, isTrue);
  });
}
