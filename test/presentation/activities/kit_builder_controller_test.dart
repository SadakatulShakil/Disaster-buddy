// Phase 4: packing every correct item must complete the activity, persist
// it, and award the badge exactly once; dropping a wrong item must never
// fail, penalize, or complete the activity.

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
import 'package:bipod_bondhu/domain/entities/kit_item.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/kit_builder/kit_builder_controller.dart';
import 'package:bipod_bondhu/presentation/widgets/feedback_presenter_mixin.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_flutter_tts.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

Activity _kitActivity() => const Activity(
      id: 'emergency_kit',
      type: ActivityType.kitBuilder,
      title: _text,
      themeColorHex: '#6C63FF',
      iconAsset: 'icon.png',
      instructions: _text,
      content: KitBuilderContent(
        items: [
          KitItem(id: 'water', label: _text, imageAsset: 'water.png', isCorrect: true, affirmation: _text),
          KitItem(id: 'torch', label: _text, imageAsset: 'torch.png', isCorrect: true, affirmation: _text),
          KitItem(id: 'toy', label: _text, imageAsset: 'toy.png', isCorrect: false, feedback: _text),
        ],
      ),
      badge: BadgeInfo(id: 'ready_kit_badge', title: _text, iconAsset: 'badge.png'),
    );

KitBuilderController _buildController({
  required FakeActivityRepository activityRepository,
  required FakeActivityProgressRepository activityProgressRepository,
  required FakeProgressRepository progressRepository,
}) {
  return KitBuilderController(
    getActivity: GetActivity(activityRepository),
    completeActivity: CompleteActivity(
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    ),
    narrationService: NarrationService(tts: FakeFlutterTts()),
    soundService: SoundService(),
    activityId: 'emergency_kit',
  );
}

void main() {
  // `NarrationService.speak` reads `UserPrefService.instance.soundEnabled`,
  // which needs a real (mocked) SharedPreferences backing.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  // testWidgets (not a plain `test`) so `WidgetsFlutterBinding` is
  // initialized before `NarrationService` constructs its `FlutterTts`,
  // which registers a MethodChannel handler in its constructor.
  testWidgets('adding all correct items completes, persists, and awards the badge once', (tester) async {
    final activityRepository = FakeActivityRepository([_kitActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    // `handleDrop` awaits the affirmation narrating fully — including its
    // own clear-when-done — before returning, so a correct drop's feedback
    // is already gone again by the time this await resolves. Capture it as
    // it's shown instead of checking it survives the await.
    final shownFeedback = <bool>[];
    final feedbackWorker = ever<ActiveFeedback?>(controller.activeFeedback, (feedback) {
      if (feedback != null) shownFeedback.add(feedback.isCorrect);
    });
    addTearDown(feedbackWorker.dispose);

    await controller.handleDrop(controller.items[0]); // water
    expect(controller.packedItemIds, {'water'});
    expect(controller.isComplete.value, isFalse);
    // Correct drops get a warm confirmation via the same shared component.
    expect(shownFeedback, contains(true));

    await controller.handleDrop(controller.items[1]); // torch — last correct item

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isTrue);
    expect(activityProgressRepository.completedByActivity['emergency_kit'], isTrue);
    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, {'ready_kit_badge'});
  });

  testWidgets('dropping a wrong item is rejected gently — no penalty, no completion', (tester) async {
    final activityRepository = FakeActivityRepository([_kitActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();
    final toy = controller.items.firstWhere((item) => item.id == 'toy');

    await controller.handleDrop(toy);

    expect(controller.packedItemIds, isEmpty);
    expect(controller.isComplete.value, isFalse);
    expect(controller.lastWrongItemId.value, 'toy');
    expect(activityProgressRepository.completedByActivity['emergency_kit'], isNull);
    expect(progressRepository.awardBadgeCallCount, 0);
    // Shows the item's own specific feedback, not a generic fallback.
    expect(controller.activeFeedback.value?.isCorrect, isFalse);
    expect(controller.activeFeedback.value?.message, _text.bn);

    // Let the reject-feedback clear timer fire so it isn't left pending
    // when the test ends.
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));

    // Still fully completable afterwards — the wrong drop didn't corrupt
    // anything.
    await controller.handleDrop(controller.items[0]);
    await controller.handleDrop(controller.items[1]);
    expect(controller.isComplete.value, isTrue);
  });

  testWidgets('replaying an already-completed activity does not double-award', (tester) async {
    final activityRepository = FakeActivityRepository([_kitActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository()..completedByActivity['emergency_kit'] = true;
    final progressRepository = FakeProgressRepository()..earnedBadgeIds.add('ready_kit_badge');
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    await controller.handleDrop(controller.items[0]);
    await controller.handleDrop(controller.items[1]);

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isFalse);
    expect(progressRepository.awardBadgeCallCount, 0);
  });
}
