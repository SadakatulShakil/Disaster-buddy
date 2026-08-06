// Phase 4: packing every correct item must complete the activity, persist
// it, and award the badge exactly once; dropping a wrong item must never
// fail, penalize, or complete the activity.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/services/narration_service.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';
import 'package:bipod_bondhu/core/theme/app_durations.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/kit_item.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/kit_builder/kit_builder_controller.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

Activity _kitActivity() => const Activity(
      id: 'emergency_kit',
      title: _text,
      themeColorHex: '#6C63FF',
      iconAsset: 'icon.png',
      instructions: _text,
      items: [
        KitItem(id: 'water', label: _text, imageAsset: 'water.png', isCorrect: true, affirmation: _text),
        KitItem(id: 'torch', label: _text, imageAsset: 'torch.png', isCorrect: true, affirmation: _text),
        KitItem(id: 'toy', label: _text, imageAsset: 'toy.png', isCorrect: false),
      ],
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
    narrationService: NarrationService(),
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
    await controller.load();
    final activity = controller.activity.value!;

    await controller.handleDrop(activity.items[0]); // water
    expect(controller.packedItemIds, {'water'});
    expect(controller.isComplete.value, isFalse);

    await controller.handleDrop(activity.items[1]); // torch — last correct item

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
    await controller.load();
    final activity = controller.activity.value!;
    final toy = activity.items.firstWhere((item) => item.id == 'toy');

    await controller.handleDrop(toy);

    expect(controller.packedItemIds, isEmpty);
    expect(controller.isComplete.value, isFalse);
    expect(controller.lastWrongItemId.value, 'toy');
    expect(activityProgressRepository.completedByActivity['emergency_kit'], isNull);
    expect(progressRepository.awardBadgeCallCount, 0);

    // Let the reject-feedback clear timer fire so it isn't left pending
    // when the test ends.
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));

    // Still fully completable afterwards — the wrong drop didn't corrupt
    // anything.
    await controller.handleDrop(activity.items[0]);
    await controller.handleDrop(activity.items[1]);
    expect(controller.isComplete.value, isTrue);
  });

  testWidgets('replaying an already-completed activity does not double-award', (tester) async {
    final activityRepository = FakeActivityRepository([_kitActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository()
      ..completedByActivity['emergency_kit'] = true;
    final progressRepository = FakeProgressRepository()..earnedBadgeIds.add('ready_kit_badge');
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    await controller.load();
    final activity = controller.activity.value!;

    await controller.handleDrop(activity.items[0]);
    await controller.handleDrop(activity.items[1]);

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isFalse);
    expect(progressRepository.awardBadgeCallCount, 0);
  });
}
