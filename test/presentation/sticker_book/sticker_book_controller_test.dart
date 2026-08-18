// Regression test: a child reported that badges earned via the activities
// (Ready Kit Hero, Signal Spotter, Safe Spot Hero) show up in Tuku's Den but
// are missing from the Sticker Book page. The page's controller used to
// source its list from hazard modules only (GetModules/GetModuleProgress),
// ignoring activity and streak badges entirely — it must instead share the
// same GetEarnedCollection source Tuku's Den already uses.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/collectible_sticker.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_earned_collection.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';
import 'package:bipod_bondhu/presentation/sticker_book/sticker_book_controller.dart';

import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

HazardModule _module(String id) => HazardModule(
      id: id,
      order: 1,
      title: _text,
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: _text,
      badge: BadgeInfo(id: '${id}_badge', title: _text, iconAsset: 'badge.png'),
      beats: const [],
    );

Activity _activity(String id) => Activity(
      id: id,
      type: ActivityType.kitBuilder,
      title: _text,
      themeColorHex: '#6C63FF',
      iconAsset: 'icon.png',
      instructions: _text,
      content: const KitBuilderContent(items: []),
      badge: BadgeInfo(id: '${id}_badge', title: _text, iconAsset: 'badge.png'),
    );

StickerBookController _buildController({
  required FakeContentRepository contentRepository,
  required FakeActivityRepository activityRepository,
  required FakeProgressRepository progressRepository,
}) {
  return StickerBookController(
    getEarnedCollection: GetEarnedCollection(
      getModules: GetModules(contentRepository),
      getActivities: GetActivities(activityRepository),
      progressRepository: progressRepository,
    ),
  );
}

void main() {
  testWidgets('shows earned badges from hazard modules, activities, and streaks alike', (tester) async {
    final progressRepository = FakeProgressRepository()
      ..earnedBadgeIds.addAll({'earthquake_badge', 'emergency_kit_badge', 'streak_7_badge'});
    final controller = _buildController(
      contentRepository: FakeContentRepository([_module('earthquake')]),
      activityRepository: FakeActivityRepository([_activity('emergency_kit')]),
      progressRepository: progressRepository,
    );
    addTearDown(controller.onClose);
    await controller.load();

    expect(controller.status.value, StickerBookViewStatus.data);
    final earnedIds = controller.earnedStickers.map((s) => s.badge.id).toSet();
    expect(earnedIds, {'earthquake_badge', 'emergency_kit_badge', 'streak_7_badge'});

    final activityBadge = controller.earnedStickers.firstWhere((s) => s.badge.id == 'emergency_kit_badge');
    expect(activityBadge.sourceKind, CollectibleSourceKind.activity);

    final streakBadge = controller.earnedStickers.firstWhere((s) => s.badge.id == 'streak_7_badge');
    expect(streakBadge.sourceKind, CollectibleSourceKind.streak);
    expect(streakBadge.streakLength, 7);
  });

  testWidgets('never shows a badge that has not actually been earned yet', (tester) async {
    final controller = _buildController(
      contentRepository: FakeContentRepository([_module('earthquake')]),
      activityRepository: FakeActivityRepository([_activity('emergency_kit')]),
      progressRepository: FakeProgressRepository(),
    );
    addTearDown(controller.onClose);
    await controller.load();

    expect(controller.status.value, StickerBookViewStatus.data);
    expect(controller.earnedStickers, isEmpty);
  });
}
