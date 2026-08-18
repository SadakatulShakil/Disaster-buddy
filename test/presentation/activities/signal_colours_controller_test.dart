// Matching the correct meaning for every signal must complete the
// activity, persist it, and award the badge exactly once; tapping a wrong
// meaning must never fail, penalize, or complete the activity.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/services/narration_service.dart';
import 'package:bipod_bondhu/core/services/sound_service.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';
import 'package:bipod_bondhu/core/theme/app_durations.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/signal_info.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/signal_colours/signal_colours_controller.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

Activity _signalActivity() => const Activity(
      id: 'signal_colours',
      type: ActivityType.signalColours,
      title: _text,
      themeColorHex: '#5B6EE1',
      iconAsset: 'icon.png',
      instructions: _text,
      content: SignalColoursContent(
        signals: [
          SignalInfo(
            id: 'calm',
            colorHex: '#2E9E5B',
            meaning: _text,
            action: _text,
            actionIcon: 'a.png',
            affirmation: _text,
            feedback: _text,
          ),
          SignalInfo(
            id: 'get_ready',
            colorHex: '#F4C430',
            meaning: _text,
            action: _text,
            actionIcon: 'b.png',
            affirmation: _text,
            feedback: _text,
          ),
          SignalInfo(
            id: 'danger',
            colorHex: '#D9534F',
            meaning: _text,
            action: _text,
            actionIcon: 'c.png',
            affirmation: _text,
            feedback: _text,
          ),
        ],
      ),
      badge: BadgeInfo(id: 'signal_spotter_badge', title: _text, iconAsset: 'badge.png'),
    );

SignalColoursController _buildController({
  required FakeActivityRepository activityRepository,
  required FakeActivityProgressRepository activityProgressRepository,
  required FakeProgressRepository progressRepository,
}) {
  return SignalColoursController(
    getActivity: GetActivity(activityRepository),
    completeActivity: CompleteActivity(
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    ),
    narrationService: NarrationService(tts: FakeFlutterTts()),
    soundService: SoundService(),
    activityId: 'signal_colours',
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  testWidgets('matching every signal completes, persists, and awards the badge once', (tester) async {
    final activityRepository = FakeActivityRepository([_signalActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    for (var i = 0; i < 3; i++) {
      await controller.selectOption(controller.currentSignal);
    }

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isTrue);
    expect(activityProgressRepository.completedByActivity['signal_colours'], isTrue);
    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, {'signal_spotter_badge'});
  });

  testWidgets('tapping a wrong meaning is rejected gently — no penalty, no completion', (tester) async {
    final activityRepository = FakeActivityRepository([_signalActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();
    final wrongOption = controller.signals.firstWhere((signal) => signal.id != controller.currentSignal.id);

    await controller.selectOption(wrongOption);

    expect(controller.currentAnsweredCorrectly.value, isFalse);
    expect(controller.isComplete.value, isFalse);
    expect(controller.lastWrongOptionId.value, wrongOption.id);
    expect(activityProgressRepository.completedByActivity['signal_colours'], isNull);
    expect(progressRepository.awardBadgeCallCount, 0);
    // Shows the correct signal's own specific feedback, not a generic
    // fallback.
    expect(controller.activeFeedback.value?.isCorrect, isFalse);
    expect(controller.activeFeedback.value?.message, _text.bn);

    // Let the reject-feedback clear timer fire so it isn't left pending
    // when the test ends.
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));

    // Still fully completable afterwards — the wrong tap didn't corrupt
    // anything.
    for (var i = 0; i < 3; i++) {
      await controller.selectOption(controller.currentSignal);
    }
    expect(controller.isComplete.value, isTrue);
  });

  testWidgets('replaying an already-completed activity does not double-award', (tester) async {
    final activityRepository = FakeActivityRepository([_signalActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository()..completedByActivity['signal_colours'] = true;
    final progressRepository = FakeProgressRepository()..earnedBadgeIds.add('signal_spotter_badge');
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    for (var i = 0; i < 3; i++) {
      await controller.selectOption(controller.currentSignal);
    }

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isFalse);
    expect(progressRepository.awardBadgeCallCount, 0);
  });
}
