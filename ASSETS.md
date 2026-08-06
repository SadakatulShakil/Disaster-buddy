# Bipod Bondhu — Asset Manifest

Every image/icon path listed here is referenced from a content manifest
(`assets/content/**/*.json`) or a core constant (`AssetPaths`), and is
rendered through **`PlaceholderArt`** (or, for the splash mascot, plain
`Image.asset`) — so the app already runs correctly with **none of these
files present**. Drop a real file in at the exact path below and it appears
automatically; no code or manifest changes needed.

All content-manifest paths are relative to `assets/images/` (see
`PlaceholderArt`/`AssetPaths.image`). Branding paths below are given in full.

Recommended format: PNG with transparency, roughly square unless noted,
optimized for mobile (a few hundred KB max). SVGs are supported via
`flutter_svg` if you prefer vector art for icons — swap the extension and
update the manifest's `imageAsset`/`iconAsset` value to match.

---

## 1. Branding & chrome

| Path | Used by | Notes |
|---|---|---|
| `assets/images/tuku.png` | `AssetPaths.mascotTuku` (currently unused directly — `MascotView`'s native placeholder is an emoji) | Reserved for a static Tuku illustration if ever needed outside `MascotView`. |
| `assets/images/logo.png` | `AssetPaths.logo` (not yet wired into a screen) | App logo, reserved. |
| `assets/icons/flag_bn.png` | Language picker (`LanguagePage`) — currently rendered via emoji flags, not this path | Reserved if emoji flags are swapped for custom art. |
| `assets/icons/flag_en.png` | Same as above | Reserved. |

## 2. Mascot mood art (optional, 3 fallback tiers)

`MascotView` tries each tier in order and falls back to the next if that
mood's file is absent — same widget/API at every tier, so upgrading the
mascot's look never requires touching any code:

1. **Lottie animation** — `assets/animations/mascot_<mood>.json`.
2. **Static illustration** — `assets/images/mascot/tuku_<mood>.png`, played
   with the same hand-built bob/scale/rotate motion as tier 3.
3. **Native emoji-in-a-circle** placeholder (always available, no file
   needed).

| Lottie path | Static image path | Mood |
|---|---|---|
| `assets/animations/mascot_idle.json` | `assets/images/mascot/tuku_idle.png` | `MascotMood.idle` |
| `assets/animations/mascot_happy.json` | `assets/images/mascot/tuku_happy.png` | `MascotMood.happy` |
| `assets/animations/mascot_cheer.json` | `assets/images/mascot/tuku_cheer.png` | `MascotMood.cheer` |
| `assets/animations/mascot_point.json` | `assets/images/mascot/tuku_point.png` | `MascotMood.point` |
| `assets/animations/mascot_think.json` | `assets/images/mascot/tuku_think.png` | `MascotMood.think` |

Note: `assets/animations/` is **not** listed in `pubspec.yaml`'s `assets:`
section yet — add it there once real Lottie files exist (an empty/missing
directory listed in `pubspec.yaml` breaks `flutter pub get`).
`assets/images/mascot/` **is** already listed, since static art is bundled.

## 3. Fonts

| Path | Notes |
|---|---|
| `assets/fonts/HindSiliguri-Regular.ttf` | Bangla-supporting font family `HindSiliguri` (see `AppTheme.fontFamily`). |
| `assets/fonts/HindSiliguri-Medium.ttf` | Weight 500. |
| `assets/fonts/HindSiliguri-SemiBold.ttf` | Weight 600. |
| `assets/fonts/HindSiliguri-Bold.ttf` | Weight 700. |

Uncomment the `fonts:` block in `pubspec.yaml` once these four files exist.
Until then Bangla still renders via the system font.

---

## 4. Module content — Earthquake (`assets/content/earthquake.json`)

| Path | Beat | Role |
|---|---|---|
| `icons/earthquake.png` | — | Module icon (Adventure Map stop, ModuleHome header). |
| `icons/badge_earthquake.png` | — | "Earthquake Hero" badge (ModuleHome, StickerBook, Reward). |
| `story/eq_slide_1.png` … `story/eq_slide_4.png` | story | 4 story slides. |
| `steps/eq_step_1.png` … `steps/eq_step_3.png` | steps | 3 numbered safe-action steps. |
| `practice/eq_drop.png` | practice | Sequence-tap item: Drop. |
| `practice/under_table.png` | practice | Sequence-tap item: Cover. |
| `practice/eq_hold.png` | practice | Sequence-tap item: Hold On. |
| `quiz/eq_q1.png` … `quiz/eq_q3.png` | quiz | 3 quiz question illustrations. |

## 5. Module content — Flood (`assets/content/flood.json`)

| Path | Beat | Role |
|---|---|---|
| `icons/flood.png` | — | Module icon. |
| `icons/badge_flood.png` | — | "Flood Guardian" badge. |
| `story/fl_slide_1.png` … `story/fl_slide_4.png` | story | 4 story slides. |
| `steps/fl_step_1.png` … `steps/fl_step_3.png` | steps | 3 steps. |
| `practice/rooftop.png` | practice | Tap-correct-choice: higher rooftop (correct). |
| `practice/flooded_street.png` | practice | Distractor. |
| `practice/near_river.png` | practice | Distractor. |
| `quiz/fl_q1.png` … `quiz/fl_q3.png` | quiz | 3 quiz question illustrations. |

## 6. Module content — Lightning (`assets/content/lightning.json`)

| Path | Beat | Role |
|---|---|---|
| `icons/lightning.png` | — | Module icon. |
| `icons/badge_lightning.png` | — | "Lightning Star" badge. |
| `story/lt_slide_1.png` … `story/lt_slide_4.png` | story | 4 story slides. |
| `steps/lt_step_1.png` … `steps/lt_step_3.png` | steps | 3 steps. |
| `practice/living_room.png` | practice | Tap-correct-choice: indoors (correct). |
| `practice/open_field.png` | practice | Distractor. |
| `practice/under_tree.png` | practice | Distractor. |
| `quiz/lt_q1.png` … `quiz/lt_q3.png` | quiz | 3 quiz question illustrations. |

## 7. Module content — First Aid (`assets/content/first_aid.json`)

A caring "helper" module, not a hazard — see `ModuleStop`'s heart icon
fallback (`Icons.favorite_rounded`) instead of a hazard icon.

| Path | Beat | Role |
|---|---|---|
| `icons/first_aid.png` | — | Module icon. |
| `icons/badge_first_aid.png` | — | "Helper Hero" badge. |
| `story/fa_slide_1.png` … `story/fa_slide_4.png` | story | 4 story slides. |
| `steps/fa_step_1.png` … `steps/fa_step_4.png` | steps | 4 steps (one more than other modules — genuinely 4 distinct actions: calm, call, 999, comfort). |
| `practice/fa_calm.png` | practice | Sequence-tap item: Stay calm. |
| `practice/fa_grownup.png` | practice | Sequence-tap item: Get a grown-up. |
| `practice/fa_call.png` | practice | Sequence-tap item: Call 999. |
| `quiz/fa_q1.png` … `quiz/fa_q3.png` | quiz | 3 quiz question illustrations. |

## 8. Activity content — Emergency Kit Builder (`assets/content/activities/emergency_kit.json`)

| Path | Role |
|---|---|
| `icons/emergency_kit.png` | Activity icon (Activities grid card, go-bag illustration in the builder). |
| `icons/badge_emergency_kit.png` | "Ready Kit Hero" badge. |
| `activities/kit/water.png` | Correct item: Water. |
| `activities/kit/torch.png` | Correct item: Torch. |
| `activities/kit/dry_food.png` | Correct item: Dry food. |
| `activities/kit/whistle.png` | Correct item: Whistle. |
| `activities/kit/papers.png` | Correct item: Important papers. |
| `activities/kit/first_aid_box.png` | Correct item: First-aid box. |
| `activities/kit/radio.png` | Correct item: Radio. |
| `activities/kit/toy.png` | Distractor: Toy. |
| `activities/kit/sweets.png` | Distractor: Sweets. |
| `activities/kit/football.png` | Distractor: Football. |
| `activities/kit/video_game.png` | Distractor: Video game. |

## 9. Daily challenges (`assets/content/daily/daily_challenges.json`) — Phase E1

A rotating pool of short challenges, one JSON file (not per-hazard). Every
`spotTheDanger`/`kitRound` entry's `payload.items[].imageAsset` reuses the
exact same asset paths already listed above (sections 5, 6, 8) — the daily
pool intentionally recycles existing hazard/kit art rather than needing its
own, so no new illustration assets are required to ship this pool.

| Path | Role |
|---|---|
| `icons/badge_streak_3.png` | "3-Day Streak!" milestone badge (StickerBook, streak celebration). |
| `icons/badge_streak_7.png` | "7-Day Streak!" milestone badge. |
| `icons/badge_streak_14.png` | "14-Day Streak!" milestone badge. |
| `icons/badge_streak_21.png` | "21-Day Streak!" milestone badge. |
| `icons/badge_streak_28.png` | "28-Day Streak!" milestone badge. |

The daily card's icon and the streak chip/chain's flame/freeze icons are
plain Material icons (`Icons.local_fire_department_rounded`,
`Icons.ac_unit_rounded`, `Icons.auto_awesome_rounded`) set directly in code,
not `PlaceholderArt` assets — consistent with other built-in iconography
used throughout the app (e.g. reward's `Icons.emoji_events_rounded`
fallback).

## 10. Tuku's Den (Phase E2)

No new illustration assets. The room itself (walls, floor, window, rug) is
entirely vector-drawn by `DenRoomPainter` — a `CustomPainter`, same
approach as the Adventure Map's `_JoyfulSkyPainter` — so it never depends
on raster art and re-themes instantly across the 3 free room themes
(meadow/sky/sunset, `DenRoomPalette`). Every sticker shown on a shelf or in
the collection tray reuses the exact same `BadgeInfo.iconAsset` already
listed above (sections 4–9) via `PlaceholderArt` — Tuku's Den introduces no
sticker art of its own, only a new place to arrange the existing
collection.

---

## Naming conventions

- **Module prefix**: `eq_` (earthquake), `fl_` (flood), `lt_` (lightning),
  `fa_` (first_aid) — used for story/steps/quiz filenames so assets from
  different modules never collide even sitting in the same shared
  `story/`, `steps/`, `quiz/` folders.
- **Practice items** are named for what they depict rather than
  module-prefixed (e.g. `practice/rooftop.png`), since the item itself is
  descriptive and mostly module-specific already; a couple (`eq_drop.png`,
  `eq_hold.png`) keep the module prefix where the depicted action is
  otherwise ambiguous.
- **Activities** get their own subfolder per activity:
  `activities/<activity_id>/<item_id>.png`.
- **Badges** are always `icons/badge_<owner_id>.png`.
- Quiz **options** support an optional per-option `imageAsset` in the
  manifest schema (`QuizOption.imageAsset`), but none of the four modules
  currently set one — every quiz today is question-illustration +
  text-only options. Add one to a manifest's option object to enable a
  picture answer for that choice; no code changes needed.

## Adding a new module or activity

1. Drop a new `assets/content/<id>.json` (or
   `assets/content/activities/<id>.json`) following the schema above.
2. Register its id in `AppConstants.initialHazards` (modules) or
   `AppConstants.implementedActivities` (activities).
3. List every asset path it references here, following the same grouping.

Until real art exists for a path, `PlaceholderArt` renders a themed, rounded
icon tile instead — never a broken-image glyph.

## Adding a new daily challenge

Append an entry to `assets/content/daily/daily_challenges.json`'s
`challenges` array — no code changes needed. Reuse an existing hazard's
`practice/`/`activities/kit/` image paths where the interaction matches, or
list a new path here (grouped under section 9) if it needs its own art.
