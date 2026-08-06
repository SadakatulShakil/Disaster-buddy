// Phase E2: DenController must derive a positive greeting/mood for every
// context — a new unplaced sticker beats a streak milestone, which beats
// simply noticing the child already visited today — and every mood must
// be an upbeat one; Tuku never looks sad, bored, or impatient.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/presentation/den/den_controller.dart';
import 'package:bipod_bondhu/presentation/widgets/mascot_view.dart';

void main() {
  group('DenController.computeGreetingContext', () {
    test('a new unplaced sticker takes priority over everything else', () {
      final context = DenController.computeGreetingContext(
        hasNewUnplacedSticker: true,
        alreadyCompletedToday: true,
        milestoneReachedToday: true,
      );
      expect(context, DenGreetingContext.newSticker);
    });

    test('a milestone reached today takes priority when there is no new sticker', () {
      final context = DenController.computeGreetingContext(
        hasNewUnplacedSticker: false,
        alreadyCompletedToday: true,
        milestoneReachedToday: true,
      );
      expect(context, DenGreetingContext.milestone);
    });

    test('returning today (already completed, no milestone) is a warm welcome-back', () {
      final context = DenController.computeGreetingContext(
        hasNewUnplacedSticker: false,
        alreadyCompletedToday: true,
        milestoneReachedToday: false,
      );
      expect(context, DenGreetingContext.returningToday);
    });

    test('first visit today (nothing done yet) is a calm default welcome', () {
      final context = DenController.computeGreetingContext(
        hasNewUnplacedSticker: false,
        alreadyCompletedToday: false,
        milestoneReachedToday: false,
      );
      expect(context, DenGreetingContext.firstVisitToday);
    });
  });

  group('DenController.moodForGreeting', () {
    test('every context maps to an upbeat mood, never idle/sad', () {
      for (final context in DenGreetingContext.values) {
        final mood = DenController.moodForGreeting(context);
        expect(mood, isIn([MascotMood.cheer, MascotMood.happy, MascotMood.point]));
      }
    });
  });
}
