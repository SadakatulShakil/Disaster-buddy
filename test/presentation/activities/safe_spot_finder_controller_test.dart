// Finding every safe spot across every scene must complete the activity,
// persist it, and award the badge exactly once; tapping an unsafe spot must
// never fail, penalize, or complete the activity. Also covers the
// normalized-rect -> pixel-rect hit-testing math the scene view relies on.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bipod_bondhu/core/services/narration_service.dart';
import 'package:bipod_bondhu/core/services/user_pref_service.dart';
import 'package:bipod_bondhu/core/theme/app_durations.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/normalized_rect.dart';
import 'package:bipod_bondhu/domain/entities/safe_spot_hotspot.dart';
import 'package:bipod_bondhu/domain/entities/safe_spot_scene.dart';
import 'package:bipod_bondhu/domain/usecases/complete_activity.dart';
import 'package:bipod_bondhu/domain/usecases/get_activity.dart';
import 'package:bipod_bondhu/presentation/activities/safe_spot_finder/safe_spot_finder_controller.dart';
import 'package:bipod_bondhu/presentation/activities/safe_spot_finder/widgets/safe_spot_scene_view.dart';

import '../../fakes/fake_activity_progress_repository.dart';
import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

Activity _safeSpotActivity() => const Activity(
      id: 'safe_spot_finder',
      type: ActivityType.safeSpotFinder,
      title: _text,
      themeColorHex: '#E07A5F',
      iconAsset: 'icon.png',
      instructions: _text,
      content: SafeSpotContent(
        scenes: [
          SafeSpotScene(
            id: 'scene1',
            sceneImage: 'scene1.png',
            prompt: _text,
            spots: [
              SafeSpotHotspot(
                id: 'safe1',
                rect: NormalizedRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
                isSafe: true,
                label: _text,
                feedback: _text,
              ),
              SafeSpotHotspot(
                id: 'unsafe1',
                rect: NormalizedRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2),
                isSafe: false,
                label: _text,
                feedback: _text,
              ),
            ],
          ),
          SafeSpotScene(
            id: 'scene2',
            sceneImage: 'scene2.png',
            prompt: _text,
            spots: [
              SafeSpotHotspot(
                id: 'safe2',
                rect: NormalizedRect(x: 0.3, y: 0.3, width: 0.2, height: 0.2),
                isSafe: true,
                label: _text,
                feedback: _text,
              ),
            ],
          ),
        ],
      ),
      badge: BadgeInfo(id: 'safe_spot_hero_badge', title: _text, iconAsset: 'badge.png'),
    );

SafeSpotFinderController _buildController({
  required FakeActivityRepository activityRepository,
  required FakeActivityProgressRepository activityProgressRepository,
  required FakeProgressRepository progressRepository,
}) {
  return SafeSpotFinderController(
    getActivity: GetActivity(activityRepository),
    completeActivity: CompleteActivity(
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    ),
    narrationService: NarrationService(),
    activityId: 'safe_spot_finder',
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.instance.init();
  });

  testWidgets('finding every safe spot across every scene completes, persists, and awards the badge once',
      (tester) async {
    final activityRepository = FakeActivityRepository([_safeSpotActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    await controller.load();

    final safe1 = controller.currentScene.spots.firstWhere((spot) => spot.isSafe);
    final outcome1 = await controller.handleTap(safe1);
    expect(outcome1, SafeSpotTapOutcome.newlySafe);
    expect(controller.sceneIndex.value, 1);
    expect(controller.isComplete.value, isFalse);

    final safe2 = controller.currentScene.spots.firstWhere((spot) => spot.isSafe);
    final outcome2 = await controller.handleTap(safe2);
    expect(outcome2, SafeSpotTapOutcome.newlySafe);

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isTrue);
    expect(activityProgressRepository.completedByActivity['safe_spot_finder'], isTrue);
    expect(progressRepository.awardBadgeCallCount, 1);
    expect(progressRepository.earnedBadgeIds, {'safe_spot_hero_badge'});
  });

  testWidgets('tapping an unsafe spot is rejected gently — no penalty, no completion', (tester) async {
    final activityRepository = FakeActivityRepository([_safeSpotActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository();
    final progressRepository = FakeProgressRepository();
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    await controller.load();
    final unsafe = controller.currentScene.spots.firstWhere((spot) => !spot.isSafe);

    final outcome = await controller.handleTap(unsafe);

    expect(outcome, SafeSpotTapOutcome.unsafe);
    expect(controller.sceneIndex.value, 0);
    expect(controller.foundSafeIds, isEmpty);
    expect(controller.isComplete.value, isFalse);
    expect(controller.lastUnsafeSpotId.value, unsafe.id);
    expect(activityProgressRepository.completedByActivity['safe_spot_finder'], isNull);
    expect(progressRepository.awardBadgeCallCount, 0);

    // Let the reject-feedback clear timer fire so it isn't left pending
    // when the test ends.
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));

    // Still fully completable afterwards — the unsafe tap didn't corrupt
    // anything.
    final safe1 = controller.currentScene.spots.firstWhere((spot) => spot.isSafe);
    await controller.handleTap(safe1);
    final safe2 = controller.currentScene.spots.firstWhere((spot) => spot.isSafe);
    await controller.handleTap(safe2);
    expect(controller.isComplete.value, isTrue);
  });

  testWidgets('replaying an already-completed activity does not double-award', (tester) async {
    final activityRepository = FakeActivityRepository([_safeSpotActivity()]);
    final activityProgressRepository = FakeActivityProgressRepository()
      ..completedByActivity['safe_spot_finder'] = true;
    final progressRepository = FakeProgressRepository()..earnedBadgeIds.add('safe_spot_hero_badge');
    final controller = _buildController(
      activityRepository: activityRepository,
      activityProgressRepository: activityProgressRepository,
      progressRepository: progressRepository,
    );
    await controller.load();

    final safe1 = controller.currentScene.spots.firstWhere((spot) => spot.isSafe);
    await controller.handleTap(safe1);
    final safe2 = controller.currentScene.spots.firstWhere((spot) => spot.isSafe);
    await controller.handleTap(safe2);

    expect(controller.isComplete.value, isTrue);
    expect(controller.badgeAwarded.value, isFalse);
    expect(progressRepository.awardBadgeCallCount, 0);
  });

  group('resolveHotspotRect', () {
    const spot = SafeSpotHotspot(
      id: 'spot',
      rect: NormalizedRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1),
      isSafe: true,
      label: _text,
      feedback: _text,
    );

    test('inflates a rect smaller than the minimum tap target, keeping its centre fixed', () {
      const sceneSize = Size(400, 300);
      final rawWidth = spot.rect.width * sceneSize.width; // 40
      final rawHeight = spot.rect.height * sceneSize.height; // 30
      final rawCenter = Offset(
        spot.rect.x * sceneSize.width + rawWidth / 2,
        spot.rect.y * sceneSize.height + rawHeight / 2,
      );

      final rect = resolveHotspotRect(spot, sceneSize, minTapTarget: 56);

      expect(rect.width, 56);
      expect(rect.height, 56);
      expect(rect.center.dx, closeTo(rawCenter.dx, 0.001));
      expect(rect.center.dy, closeTo(rawCenter.dy, 0.001));
    });

    test('leaves a rect already at least the minimum tap target unchanged', () {
      const bigSpot = SafeSpotHotspot(
        id: 'big',
        rect: NormalizedRect(x: 0.0, y: 0.0, width: 0.5, height: 0.5),
        isSafe: true,
        label: _text,
        feedback: _text,
      );
      const sceneSize = Size(400, 400); // raw rect: 200x200, well above the 56 minimum

      final rect = resolveHotspotRect(bigSpot, sceneSize, minTapTarget: 56);

      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.width, 200);
      expect(rect.height, 200);
    });
  });
}
