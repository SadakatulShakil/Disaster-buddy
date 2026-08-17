/// English strings. Keys are shared with bn_strings.dart.
const Map<String, String> enStrings = {
  // App
  'app_name': 'Disaster Buddy',
  'app_tagline': 'Learn to stay safe!',

  // Language picker
  'choose_language': 'Choose your language',
  'bangla': 'বাংলা',
  'english': 'English',
  'continue': 'Continue',

  // Intro / mascot
  'meet_tuku': 'Hi, I\'m Tuku!',
  'tuku_intro': 'Let\'s learn how to stay safe together.',
  'lets_go': 'Let\'s go!',
  'skip': 'Skip',

  // Home
  'home_title': 'My Adventures',
  'home_greeting': 'What will we learn today?',

  // Hazards
  'hazard_flood': 'Flood',
  'hazard_lightning': 'Lightning',
  'hazard_earthquake': 'Earthquake',

  // Common actions
  'play': 'Play',
  'replay': 'Replay',
  'next': 'Next',
  'back': 'Back',
  'retry': 'Try again',
  'done': 'Done',
  'well_done': 'Well done!',

  // Settings
  'settings': 'Settings',
  'language': 'Language',
  'sound': 'Sound',
  'narration_speed': 'Narration speed',

  // Sticker book
  'sticker_book': 'My Stickers',

  // Parent zone
  'parent_zone': 'Parent Zone',
  'parent_gate_prompt': 'For grown-ups: what is',
  'parent_gate_hold_prompt': 'Grown-ups: press and hold to continue',
  'parent_gate_wrong': 'Not quite — try again!',
  'unlock': 'Unlock',
  'progress_summary': 'Progress summary',
  'modules_completed': 'Adventures completed',
  'badges_earned': 'Badges earned',
  'family_emergency_plan': 'Family emergency plan',
  'official_resources': 'Official resources',
  'coming_in_phase5': 'Coming in a future update',
  'open_settings': 'Open settings',

  // Adventure map
  'coming_next': 'Coming next!',
  'module_completed': 'Completed!',
  'locked_module_hint': 'Finish the adventure before this one first.',
  'something_went_wrong': 'Oops! Something went wrong.',

  // Module home / beats
  'beat_story': 'Story',
  'beat_steps': 'Steps',
  'beat_from': 'Step',
  'beat_practice': 'Practice',
  'beat_quiz': 'Quiz',
  'resume_here': 'Continue here',
  'start_adventure': 'Start',

  // Beat stub (Phase 3 placeholder)
  'coming_soon_title': 'Coming soon!',
  'coming_soon_body': 'This part of the adventure is being built. Check back in the next update!',

  // Sticker book
  'empty_stickers_title': 'Earn your first sticker!',
  'empty_stickers_subtitle': 'Finish an adventure to earn a badge.',
  'sticker_from': 'From',

  // Settings
  'narration_slow': 'Slow',
  'narration_fast': 'Fast',

  // Lesson chrome
  'leave_lesson_prompt': "Leave this adventure? What you're doing now won't be saved.",
  'leave': 'Leave',
  'stay': 'Stay',
  'back_to_map': 'Back to map',
  'quiz_progress': 'Question @current of @total',

  // Activities
  'activities': 'Activities',
  'activities_subtitle': 'Fun things to try anytime!',
  'activities_completed': 'Activities completed',
  'activity_signal_colours': 'Signal Colours',
  'activity_safe_spot_finder': 'Safe Spot Finder',

  // Emergency Kit Builder
  'drag_items_hint': 'Drag items here',
  'kit_complete_summary': 'Your emergency kit is ready!',
  'back_to_activities': 'Back to Activities',
  'kit_bag_semantics': 'Emergency kit bag: @packed of @total items packed',

  // Signal Colours
  'signal_colours_question': 'What does this colour mean?',
  'signal_colours_progress': 'Signal @current of @total',
  'signal_colours_complete_summary': 'You know every signal colour!',

  // Safe Spot Finder
  'safe_spot_scene_progress': 'Scene @current of @total',
  'safe_spot_found_progress': '@found of @total safe spots found',
  'safe_spot_complete_summary': "You found every safe spot — you're a safety expert!",
  'safe_spot_hotspot_semantics_safe': 'Safe spot: @label',
  'safe_spot_hotspot_semantics_unsafe': 'Not safe: @label',

  // Daily challenge (Phase E1)
  'daily_challenge_title': "Tuku's Daily Challenge",
  'daily_challenge_new_caption': "Play today's new challenge!",
  'daily_challenge_done_caption': 'All done for today! Come back tomorrow.',
  'daily_challenge_new_semantics': "Tuku's Daily Challenge: new for today",
  'daily_challenge_done_semantics': "Tuku's Daily Challenge: done for today",
  'daily_challenge_done_title': 'Done for today!',
  'daily_challenge_come_back_tomorrow': 'Come back tomorrow for a brand-new challenge!',
  'view_streak': 'View streak',

  // Streak (Phase E1)
  'streak_chip_semantics': '@count day streak',
  'streak_chain_title': 'My Streak',
  'current_streak': 'Current streak',
  'best_streak': 'Best streak',
  'freezes_left': 'Freezes left',
  'streak_chain_subtitle': "See how you've done these past few weeks!",
  'streak_day_semantics': '@day: @state',
  'streak_day_done': 'Completed',
  'streak_day_frozen': 'Protected by a freeze',
  'streak_day_today': 'Today',
  'streak_day_missed': 'Missed',

  // Tuku's Den (Phase E2)
  'tuku_den': "Tuku's Den",
  'den_greeting_new_sticker': 'Ooh, a new sticker for us!',
  'den_greeting_milestone': '@days days in a row — wow!',
  'den_greeting_returning': 'Welcome back to the Den!',
  'den_greeting_first_visit': 'Welcome to my Den!',
  'den_tap_reaction': 'Hehe, that tickled!',
  'den_new_sticker_banner_title': 'A new sticker is here!',
  'den_new_sticker_banner_cta': 'Show me!',
  'den_new_sticker_indicator_semantics': '@label: new sticker waiting',
  'den_open_tray_button': 'My Stickers',
  'den_collection_tray_title': 'My Stickers',
  'den_locked_hint': 'Complete @source to earn this!',
  'den_locked_hint_streak': 'Reach a @days-day streak to earn this!',
  'den_slot_empty_semantics': 'Empty shelf spot',
  'den_slot_filled_semantics': 'Shelf spot with @sticker',
  'den_theme_title': 'Room theme',
  'den_theme_meadow': 'Meadow',
  'den_theme_sky': 'Sky',
  'den_theme_sunset': 'Sunset',

  // Parent-controlled progress reset
  'manage_progress_section': 'Manage Progress',
  'cancel': 'Cancel',
  'yes_reset': 'Yes, reset',
  'reset_success_title': 'All done!',
  'reset_learning_title': 'Reset learning only',
  'reset_learning_subtitle': "Clears adventures, activities & their badges. Keeps your streak, stickers & Tuku's Den.",
  'reset_learning_confirm_title': 'Reset all learning progress?',
  'reset_learning_confirm_body':
      "This erases every adventure and activity's progress, quiz results, and badges. Your streak, daily stickers, and Tuku's Den stay exactly as they are. This cannot be undone.",
  'reset_learning_success_body': 'Learning progress has been reset.',
  'reset_single_title': 'Reset one hazard',
  'reset_single_subtitle': 'Pick one adventure to start over. Nothing else changes.',
  'reset_single_picker_title': 'Which adventure?',
  'reset_single_confirm_title': 'Reset @module?',
  'reset_single_confirm_body':
      "This erases @module's progress, quiz results, and badge. Every other adventure, your streak, stickers, and Tuku's Den stay safe. This cannot be undone.",
  'reset_single_success_body': '@module has been reset.',
  'reset_everything_title': 'Reset everything',
  'reset_everything_subtitle': 'Erase all progress for a brand-new start. This cannot be undone.',
  'reset_everything_confirm_title': 'Reset everything?',
  'reset_everything_confirm_body':
      "This erases ALL adventures, activities, badges, your streak, daily stickers, and Tuku's Den — a fresh start, as if the app were brand new. Language and sound settings stay the same. This cannot be undone.",
  'reset_everything_success_body': 'Everything has been reset. Ready for a fresh start!',
  'reset_hold_title': 'Hold to confirm',
  'reset_hold_body': 'Press and hold the button below for a moment to permanently erase everything.',
  'reset_hold_button': 'Hold to reset everything',
};
