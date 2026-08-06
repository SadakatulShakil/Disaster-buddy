import '../entities/badge_info.dart';
import '../entities/localized_text.dart';

/// Streak-length milestones that award a one-time streak sticker via the
/// existing badge/`AwardBadge` system, keyed under [ownerId] the same way a
/// module id or activity id keys its own badges — a stable pseudo-owner for
/// a cross-cutting (not module-specific) badge collection.
///
/// Unlike hazard/activity badges, these aren't sourced from a content
/// manifest — there's no educational content behind a streak length, just
/// an app-structural milestone — so they're defined directly here rather
/// than in a JSON manifest.
class StreakMilestones {
  StreakMilestones._();

  static const String ownerId = 'daily_streak';

  /// Every streak length that awards a sticker, ascending — the full set
  /// [badgeFor] can resolve, used by [GetEarnedCollection] to enumerate the
  /// streak stickers in a child's collection regardless of whether each one
  /// has been earned yet.
  static const List<int> lengths = [3, 7, 14, 21, 28];

  static BadgeInfo? badgeFor(int streakLength) {
    return switch (streakLength) {
      3 => const BadgeInfo(
          id: 'streak_3_badge',
          title: LocalizedText(bn: '৩ দিনের ধারা!', en: '3-Day Streak!'),
          iconAsset: 'badge_streak_3.png',
        ),
      7 => const BadgeInfo(
          id: 'streak_7_badge',
          title: LocalizedText(bn: '৭ দিনের ধারা!', en: '7-Day Streak!'),
          iconAsset: 'badge_streak_7.png',
        ),
      14 => const BadgeInfo(
          id: 'streak_14_badge',
          title: LocalizedText(bn: '১৪ দিনের ধারা!', en: '14-Day Streak!'),
          iconAsset: 'badge_streak_14.png',
        ),
      21 => const BadgeInfo(
          id: 'streak_21_badge',
          title: LocalizedText(bn: '২১ দিনের ধারা!', en: '21-Day Streak!'),
          iconAsset: 'badge_streak_21.png',
        ),
      28 => const BadgeInfo(
          id: 'streak_28_badge',
          title: LocalizedText(bn: '২৮ দিনের ধারা!', en: '28-Day Streak!'),
          iconAsset: 'badge_streak_28.png',
        ),
      _ => null,
    };
  }
}
