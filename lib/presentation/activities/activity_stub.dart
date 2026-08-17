import 'package:flutter/material.dart';

/// A future activity with no real content yet — shown on the Activities
/// screen as a clearly-labelled, non-interactive "coming soon" card so the
/// list reads as extensible without implying a broken/missing feature.
final class ActivityStub {
  const ActivityStub({required this.titleKey, required this.icon});

  /// Localization key for the display title (there's no manifest yet, so
  /// this is the one activity title that comes from `.tr` rather than
  /// content).
  final String titleKey;
  final IconData icon;
}

/// Activities planned for a future phase. Add the real thing by building it
/// and moving its id into `AppConstants.implementedActivities` — remove it
/// from this list at the same time. Empty for now: every planned activity
/// has shipped.
const List<ActivityStub> kFutureActivityStubs = [];
