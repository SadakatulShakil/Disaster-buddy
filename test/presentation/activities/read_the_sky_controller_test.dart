// Matching the correct hazard for every sign must complete the activity,
// persist it, and award the badge exactly once; tapping a wrong hazard must
// never fail, penalize, or complete the activity.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
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
import 'package:bipod_bondhu/domain/entities/weather_sign.dart';
import 'package:bipod_bondhu/domain/entities/weather_sign_option.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/read_the_sky/read_the_sky_controller.dart';
import 'package:bipod_bondhu/presentation/widgets/feedback_presenter_mixin.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

Activity _readTheSkyActivity() => const Activity(
      id: 'read_the_sky',
      type: ActivityType.readTheSky,
      title: _text,
      themeColorHex: '#2E86AB',
      iconAsset: 'icon.png',
      instructions: _text,
      content: ReadTheSkyContent(
        signs: [
          WeatherSign(
            id: 'dark_clouds',
            image: 'sign_dark_clouds.png',
            description: _text,
            correctHazard: LocalizedText(bn: 'ঝড় আসছে', en: 'A storm is coming'),
            options: [
              WeatherSignOption(id: 'storm', label: LocalizedText(bn: 'ঝড়', en: 'A storm'), isCorrect: true),
              WeatherSignOption(id: 'flood', label: LocalizedText(bn: 'বন্যা', en: 'A flood'), isCorrect: false),
            ],
            feedback: LocalizedText(bn: 'আরেকবার ভাবো', en: 'Think again — it means a storm.'),
            action: LocalizedText(bn: 'বড়োকে বলো', en: 'Tell a grown-up right away.'),
          ),
          WeatherSign(
            id: 'rising_river',
            image: 'sign_rising_river.png',
            description: _text,
            correctHazard: LocalizedText(bn: 'বন্যা আসছে', en: 'A flood is coming'),
            options: [
              WeatherSignOption(id: 'flood', label: LocalizedText(bn: 'বন্যা', en: 'A flood'), isCorrect: true),
              WeatherSignOption(id: 'storm', label: LocalizedText(bn: 'ঝড়', en: 'A storm'), isCorrect: false),
            ],
            feedback: LocalizedText(bn: 'আরেকবার ভাবো', en: 'Think again — it means a flood.'),
            action: LocalizedText(bn: 'বড়োকে বলো', en: 'Tell a grown-up right away.'),
          ),
        ],
      ),
      badge: BadgeInfo(id: 'read_the_sky_badge', title: _text, iconAsset: 'badge.png'),
    );

ReadTheSkyController _buildController({
  required FakeActivityRepository activityRepository,
  required FakeActivityProgressRepository activityProgressRepository,
  required FakeProgressRepository progressRepository,
}) {
  return ReadTheSkyController(
    getActivity: GetActivity(activityRepository),
    completeActivity: CompleteActivity(
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    ),
    narrationService: NarrationService(tts: FakeFlutterTts()),
    soundService: SoundService(),
    activityId: 'read_the_sky',
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  testWidgets('matching every sign completes, persists, and awards the badge once', (tester) async {
    final activityRepository = FakeActivityRepository([_readTheSkyActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    for (var i = 0; i < 2; i++) {
      final correctOption = controller.currentSign.options.firstWhere((option) => option.isCorrect);
      await controller.selectOption(correctOption);
    }

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isTrue);
    expect(activityProgressRepository.completedByActivity['read_the_sky'], isTrue);
    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, {'read_the_sky_badge'});
  });

  testWidgets('tapping a wrong hazard is rejected gently — no penalty, no completion', (tester) async {
    final activityRepository = FakeActivityRepository([_readTheSkyActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();
    final wrongOption = controller.currentSign.options.firstWhere((option) => !option.isCorrect);

    await controller.selectOption(wrongOption);

    expect(controller.currentAnsweredCorrectly.value, isFalse);
    expect(controller.isComplete.value, isFalse);
    expect(controller.lastWrongOptionId.value, wrongOption.id);
    expect(activityProgressRepository.completedByActivity['read_the_sky'], isNull);
    expect(progressRepository.awardBadgeCallCount, 0);
    // Shows the sign's own specific feedback, not a generic fallback.
    expect(controller.activeFeedback.value?.isCorrect, isFalse);
    expect(controller.activeFeedback.value?.message, 'আরেকবার ভাবো');

    // Let the reject-feedback clear timer fire so it isn't left pending
    // when the test ends.
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));

    // Still fully completable afterwards — the wrong tap didn't corrupt
    // anything.
    for (var i = 0; i < 2; i++) {
      final correctOption = controller.currentSign.options.firstWhere((option) => option.isCorrect);
      await controller.selectOption(correctOption);
    }
    expect(controller.isComplete.value, isTrue);
  });

  testWidgets('a correct match shows the confirmed hazard plus the "tell a grown-up" reinforcement', (tester) async {
    final activityRepository = FakeActivityRepository([_readTheSkyActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    final feedbackMessages = <String>[];
    final worker = ever<ActiveFeedback?>(controller.activeFeedback, (feedback) {
      if (feedback != null && feedback.isCorrect) feedbackMessages.add(feedback.message);
    });
    addTearDown(worker.dispose);

    final correctOption = controller.currentSign.options.firstWhere((option) => option.isCorrect);
    await controller.selectOption(correctOption);

    expect(feedbackMessages, ['ঝড় আসছে বড়োকে বলো']);
  });

  testWidgets('replaying an already-completed activity does not double-award', (tester) async {
    final activityRepository = FakeActivityRepository([_readTheSkyActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository()..completedByActivity['read_the_sky'] = true;
    final progressRepository = FakeProgressRepository()..earnedBadgeIds.add('read_the_sky_badge');
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    for (var i = 0; i < 2; i++) {
      final correctOption = controller.currentSign.options.firstWhere((option) => option.isCorrect);
      await controller.selectOption(correctOption);
    }

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isFalse);
    expect(progressRepository.awardBadgeCallCount, 0);
  });
}
