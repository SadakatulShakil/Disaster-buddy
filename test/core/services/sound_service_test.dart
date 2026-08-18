// UX pass: SoundService must never play when sound is muted, and must
// degrade to a silent no-op (never crash, never throw) when a clip can't
// actually be played.
//
// The real `AudioPlayer` awaits a completer that only resolves once the
// native platform side calls back — which never happens in a plain test
// environment, so exercising it directly hangs instead of throwing. A fake
// subclass overrides just the methods `SoundService` calls, bypassing that
// platform round trip while still exercising the service's own logic.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/services/sound_service.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';

class _FakeAudioPlayer extends AudioPlayer {
  _FakeAudioPlayer({this.failing = false});

  /// When true, every call simulates a missing/corrupt clip.
  final bool failing;

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {}

  @override
  Future<void> setSourceAsset(String path, {String? mimeType}) async {
    if (failing) throw Exception('simulated missing asset: $path');
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (failing) throw Exception('simulated missing asset');
  }

  @override
  Future<void> stop() async {
    if (failing) throw Exception('simulated missing asset');
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  testWidgets('does not construct a player at all when sound is muted', (tester) async {
    await UserPrefService.instance.setSoundEnabled(false);
    var factoryCallCount = 0;
    final service = SoundService(playerFactory: () {
      factoryCallCount++;
      return _FakeAudioPlayer();
    });

    await service.playCorrect();
    await service.playWrong();
    await service.playComplete();

    expect(factoryCallCount, 0);
  });

  testWidgets('playing a working clip with sound enabled completes without throwing', (tester) async {
    await UserPrefService.instance.setSoundEnabled(true);
    final service = SoundService(playerFactory: () => _FakeAudioPlayer());

    await expectLater(service.playCorrect(), completes);
    await expectLater(service.playWrong(), completes);
    await expectLater(service.playComplete(), completes);
    await expectLater(service.playReward(), completes);
    await expectLater(service.playSticker(), completes);
  });

  testWidgets('a missing/corrupt clip degrades to a silent no-op instead of throwing', (tester) async {
    await UserPrefService.instance.setSoundEnabled(true);
    final service = SoundService(playerFactory: () => _FakeAudioPlayer(failing: true));

    // This is the exact "clip missing" scenario the service must survive —
    // the underlying player throws on every call, and the service must
    // never let that exception escape.
    await expectLater(service.playCorrect(), completes);
    // Calling it again exercises the "already known to have failed" path.
    await expectLater(service.playCorrect(), completes);
  });

  testWidgets('a clip that failed once is not retried on later calls', (tester) async {
    await UserPrefService.instance.setSoundEnabled(true);
    var factoryCallCount = 0;
    final service = SoundService(playerFactory: () {
      factoryCallCount++;
      return _FakeAudioPlayer(failing: true);
    });

    await service.playCorrect();
    final callsAfterFirstFailure = factoryCallCount;
    await service.playCorrect();

    // The same clip's player is reused rather than reconstructed on retry.
    expect(factoryCallCount, callsAfterFirstFailure);
  });

  testWidgets('preload() never throws even when every clip is missing', (tester) async {
    final service = SoundService(playerFactory: () => _FakeAudioPlayer(failing: true));

    await expectLater(service.preload(), completes);
  });
}
