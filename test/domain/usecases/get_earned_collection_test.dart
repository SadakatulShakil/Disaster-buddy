// Phase E2: GetEarnedCollection must enumerate every possible sticker —
// hazard modules, activities, and streak milestones — flagging each
// `earned` from the badges actually recorded, never filtering unearned
// ones out (the Den tray needs them to render as locked placeholders).

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';
import 'package:bipod_bondhu/domain/entities/badge_info.dart';
import 'package:bipod_bondhu/domain/entities/collectible_sticker.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/services/streak_milestones.dart';
import 'package:bipod_bondhu/domain/usecases/get_activities.dart';
import 'package:bipod_bondhu/domain/usecases/get_earned_collection.dart';
import 'package:bipod_bondhu/domain/usecases/get_modules.dart';

import '../../fakes/fake_activity_repository.dart';
import '../../fakes/fake_content_repository.dart';
import '../../fakes/fake_progress_repository.dart';

const _text = LocalizedText(bn: 'ক', en: 'a');

HazardModule _module(String id, int order) => HazardModule(
      id: id,
      order: order,
      title: _text,
      themeColorHex: '#A0522D',
      iconAsset: 'icon.png',
      safeAction: _text,
      badge: BadgeInfo(id: '${id}_badge', title: _text, iconAsset: 'badge.png'),
      beats: const [],
    );

Activity _activity(String id, {bool withBadge = true}) => Activity(
      id: id,
      type: ActivityType.kitBuilder,
      title: _text,
      themeColorHex: '#6C63FF',
      iconAsset: 'icon.png',
      instructions: _text,
      content: const KitBuilderContent(items: []),
      badge: withBadge ? BadgeInfo(id: '${id}_badge', title: _text, iconAsset: 'badge.png') : null,
    );

void main() {
  test('includes every module, activity-with-badge, and streak milestone, flagging earned correctly', () async {
    final contentRepository = FakeContentRepository([_module('earthquake', 1), _module('flood', 2)]);
    final activityRepository = FakeActivityRepository([_activity('emergency_kit'), _activity('no_badge_activity', withBadge: false)]);
    final progressRepository = FakeProgressRepository()..earnedBadgeIds.addAll(['earthquake_badge', 'streak_7_badge']);

    final useCase = GetEarnedCollection(
      getModules: GetModules(contentRepository),
      getActivities: GetActivities(activityRepository),
      progressRepository: progressRepository,
    );

    final result = await useCase();

    expect(result, isA<Success<List<CollectibleSticker>>>());
    final stickers = (result as Success<List<CollectibleSticker>>).value;

    // 2 modules + 1 badge-bearing activity + every streak milestone.
    expect(stickers.length, 2 + 1 + StreakMilestones.lengths.length);

    final earthquake = stickers.firstWhere((s) => s.badge.id == 'earthquake_badge');
    expect(earthquake.earned, isTrue);
    expect(earthquake.sourceKind, CollectibleSourceKind.module);

    final flood = stickers.firstWhere((s) => s.badge.id == 'flood_badge');
    expect(flood.earned, isFalse);

    final kit = stickers.firstWhere((s) => s.badge.id == 'emergency_kit_badge');
    expect(kit.sourceKind, CollectibleSourceKind.activity);

    final streak7 = stickers.firstWhere((s) => s.badge.id == 'streak_7_badge');
    expect(streak7.earned, isTrue);
    expect(streak7.sourceKind, CollectibleSourceKind.streak);
    expect(streak7.streakLength, 7);

    final streak3 = stickers.firstWhere((s) => s.badge.id == 'streak_3_badge');
    expect(streak3.earned, isFalse);

    expect(stickers.any((s) => s.badge.id == 'no_badge_activity_badge'), isFalse);
  });
}
