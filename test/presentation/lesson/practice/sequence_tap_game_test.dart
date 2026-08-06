// Phase 3: SequenceTapGame must complete once every item is tapped in the
// right order, and a wrong tap must never fail the game — just prompt a
// retry with no penalty.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/core/theme/app_durations.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/practice_config.dart';
import 'package:bipod_bondhu/domain/entities/practice_item.dart';
import 'package:bipod_bondhu/presentation/lesson/lesson_runner_callbacks.dart';
import 'package:bipod_bondhu/presentation/lesson/practice/sequence_tap_game.dart';

const _en = LocalizedText(bn: 'নির্দেশনা', en: 'Instructions');

PracticeConfig _config() => const PracticeConfig(
      instructions: _en,
      items: [
        PracticeItem(id: 'drop', label: LocalizedText(bn: 'বসো', en: 'Drop'), sequenceOrder: 1),
        PracticeItem(id: 'cover', label: LocalizedText(bn: 'ঢেকে রাখো', en: 'Cover'), sequenceOrder: 2),
        PracticeItem(id: 'hold', label: LocalizedText(bn: 'ধরে থাকো', en: 'Hold On'), sequenceOrder: 3),
      ],
    );

class _Spy {
  bool finished = false;
}

LessonRunnerCallbacks _callbacks(_Spy spy) => LessonRunnerCallbacks(
      narrate: (_) {},
      stopNarration: () {},
      isSpeaking: false.obs,
      setMascotMood: (_) {},
      onBeatFinished: () => spy.finished = true,
      recordQuizResult: ({required quizId, required correct, required total}) async {},
    );

/// Wraps [builder] in a minimal GetX + ScreenUtil shell, calling it with a
/// live [BuildContext] once the tree is actually mounted.
Widget _wrap(WidgetBuilder builder) => ScreenUtilInit(
      designSize: AppConstants.designSize,
      builder: (context, _) => GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(body: Builder(builder: builder)),
      ),
    );

void main() {
  tearDown(Get.reset);

  testWidgets('tapping every item in the correct order completes the game', (tester) async {
    final spy = _Spy();
    await tester.pumpWidget(
      _wrap(
        (context) => const SequenceTapGame().build(
          context: context,
          config: _config(),
          themeColor: Colors.teal,
          callbacks: _callbacks(spy),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drop'));
    await tester.pump();
    await tester.tap(find.text('Cover'));
    await tester.pump();
    await tester.tap(find.text('Hold On'));
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));

    expect(spy.finished, isTrue);
  });

  testWidgets('an out-of-order tap does not fail — it just prompts a retry', (tester) async {
    final spy = _Spy();
    await tester.pumpWidget(
      _wrap(
        (context) => const SequenceTapGame().build(
          context: context,
          config: _config(),
          themeColor: Colors.teal,
          callbacks: _callbacks(spy),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Cover" (order 2) before "Drop" (order 1) — wrong.
    await tester.tap(find.text('Cover'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(spy.finished, isFalse);
    expect(find.text('Try again'), findsOneWidget);

    // The game must still be fully completable afterwards.
    await tester.tap(find.text('Drop'));
    await tester.pump();
    await tester.tap(find.text('Cover'));
    await tester.pump();
    await tester.tap(find.text('Hold On'));
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));

    expect(spy.finished, isTrue);
  });
}
