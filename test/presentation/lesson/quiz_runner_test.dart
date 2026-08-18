// Phase 3: finishing a quiz must persist the aggregate score and complete
// the beat regardless of how many attempts each question took — there is
// no pass/fail gate.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:bipod_bondhu/core/constants/app_constants.dart';
import 'package:bipod_bondhu/core/localization/app_translations.dart';
import 'package:bipod_bondhu/core/theme/app_durations.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/localized_text.dart';
import 'package:bipod_bondhu/domain/entities/quiz_option.dart';
import 'package:bipod_bondhu/domain/entities/quiz_question.dart';
import 'package:bipod_bondhu/presentation/lesson/lesson_runner_callbacks.dart';
import 'package:bipod_bondhu/presentation/lesson/widgets/quiz_runner.dart';

QuizBeat _beat() => const QuizBeat(
      id: 'quiz_1',
      order: 1,
      questions: [
        QuizQuestion(
          id: 'q1',
          prompt: LocalizedText(bn: 'প্রশ্ন ১', en: 'Question 1'),
          options: [
            QuizOption(id: 'a', label: LocalizedText(bn: 'ভুল', en: 'Wrong'), isCorrect: false),
            QuizOption(id: 'b', label: LocalizedText(bn: 'ঠিক', en: 'Right'), isCorrect: true),
          ],
        ),
        QuizQuestion(
          id: 'q2',
          prompt: LocalizedText(bn: 'প্রশ্ন ২', en: 'Question 2'),
          options: [
            QuizOption(id: 'a', label: LocalizedText(bn: 'ঠিক২', en: 'Right2'), isCorrect: true),
            QuizOption(id: 'b', label: LocalizedText(bn: 'ভুল২', en: 'Wrong2'), isCorrect: false),
          ],
        ),
      ],
    );

class _FeedbackCall {
  _FeedbackCall({required this.message, required this.isCorrect});
  final String message;
  final bool isCorrect;
}

class _Spy {
  bool finished = false;
  String? quizId;
  int? correct;
  int? total;
  final List<_FeedbackCall> feedbackCalls = [];
}

LessonRunnerCallbacks _callbacks(_Spy spy) => LessonRunnerCallbacks(
      narrate: (_) {},
      stopNarration: () {},
      isSpeaking: false.obs,
      setMascotMood: (_) {},
      onBeatFinished: () => spy.finished = true,
      recordQuizResult: ({required quizId, required correct, required total}) async {
        spy.quizId = quizId;
        spy.correct = correct;
        spy.total = total;
      },
      showFeedback: ({required message, required isCorrect}) async {
        spy.feedbackCalls.add(_FeedbackCall(message: message, isCorrect: isCorrect));
      },
      clearFeedback: () {},
    );

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: AppConstants.designSize,
      builder: (context, _) => GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  tearDown(Get.reset);

  testWidgets('completing the quiz persists the score and completes the beat regardless of score', (tester) async {
    final spy = _Spy();
    await tester.pumpWidget(
      _wrap(QuizRunner(beat: _beat(), themeColor: Colors.teal, callbacks: _callbacks(spy))),
    );
    await tester.pumpAndSettle();

    // Q1: wrong first, then right — should NOT count as a first-try correct.
    await tester.tap(find.text('Wrong'));
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));
    expect(spy.finished, isFalse);

    await tester.tap(find.text('Right'));
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));

    // Q2: right on the first try.
    await tester.tap(find.text('Right2'));
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));

    expect(spy.finished, isTrue);
    expect(spy.quizId, 'quiz_1');
    expect(spy.correct, 1);
    expect(spy.total, 2);
  });

  testWidgets('a wrong option with its own feedback shows that specific text, not a generic fallback',
      (tester) async {
    final spy = _Spy();
    const beat = QuizBeat(
      id: 'quiz_1',
      order: 1,
      questions: [
        QuizQuestion(
          id: 'q1',
          prompt: LocalizedText(bn: 'প্রশ্ন ১', en: 'Question 1'),
          options: [
            QuizOption(
              id: 'a',
              label: LocalizedText(bn: 'ভুল', en: 'Wrong'),
              isCorrect: false,
              feedback: LocalizedText(bn: 'ব্যাখ্যা', en: 'Not that one — sturdy tables keep you safer.'),
            ),
            QuizOption(id: 'b', label: LocalizedText(bn: 'ঠিক', en: 'Right'), isCorrect: true),
          ],
        ),
      ],
    );
    await tester.pumpWidget(_wrap(QuizRunner(beat: beat, themeColor: Colors.teal, callbacks: _callbacks(spy))));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wrong'));
    await tester.pump();

    expect(spy.feedbackCalls, hasLength(1));
    expect(spy.feedbackCalls.single.isCorrect, isFalse);
    expect(spy.feedbackCalls.single.message, 'Not that one — sturdy tables keep you safer.');

    // No fail/penalty — the question is still answerable afterwards.
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));
    await tester.tap(find.text('Right'));
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));
    expect(spy.finished, isTrue);
  });

  testWidgets('an option with no authored feedback falls back to the generic message', (tester) async {
    final spy = _Spy();
    await tester.pumpWidget(
      _wrap(QuizRunner(beat: _beat(), themeColor: Colors.teal, callbacks: _callbacks(spy))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wrong'));
    await tester.pump();

    expect(spy.feedbackCalls, hasLength(1));
    expect(spy.feedbackCalls.single.isCorrect, isFalse);
    expect(spy.feedbackCalls.single.message, "Not quite — let's try again!");

    // Let the wrong-reveal clear timer fire so it isn't left pending when
    // the test ends.
    await tester.pump(AppDurations.normal + const Duration(milliseconds: 50));
  });

  testWidgets('a correct tap shows a positive confirmation via the same shared component', (tester) async {
    final spy = _Spy();
    await tester.pumpWidget(
      _wrap(QuizRunner(beat: _beat(), themeColor: Colors.teal, callbacks: _callbacks(spy))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Right'));
    await tester.pump();

    expect(spy.feedbackCalls, hasLength(1));
    expect(spy.feedbackCalls.single.isCorrect, isTrue);
    expect(spy.feedbackCalls.single.message, 'Well done!');

    // Let the advance-after-correct timer fire so it isn't left pending
    // when the test ends.
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 50));
  });
}
