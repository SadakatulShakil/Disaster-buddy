// UX pass: QuizOption, PracticeItem, KitItem, and SignalInfo all gained an
// OPTIONAL `feedback` field for specific wrong-answer explanations. Every
// DTO must parse it when present and tolerate its absence (falling back to
// null, not throwing) — the runtime generic-message fallback lives in the
// presentation layer, not here.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/data/models/kit_item_dto.dart';
import 'package:bipod_bondhu/data/models/practice_item_dto.dart';
import 'package:bipod_bondhu/data/models/quiz_option_dto.dart';
import 'package:bipod_bondhu/data/models/signal_info_dto.dart';

void main() {
  group('QuizOptionDto.feedback', () {
    test('parses when present', () {
      final option = QuizOptionDto.fromJson({
        'id': 'a',
        'label': {'bn': 'ভুল', 'en': 'Wrong'},
        'isCorrect': false,
        'feedback': {'bn': 'ব্যাখ্যা', 'en': 'Explanation'},
      }, 'option').toDomain();

      expect(option.feedback?.en, 'Explanation');
    });

    test('falls back to null when absent', () {
      final option = QuizOptionDto.fromJson({
        'id': 'a',
        'label': {'bn': 'ভুল', 'en': 'Wrong'},
        'isCorrect': false,
      }, 'option').toDomain();

      expect(option.feedback, isNull);
    });
  });

  group('PracticeItemDto.feedback', () {
    test('parses when present', () {
      final item = PracticeItemDto.fromJson({
        'id': 'drop',
        'label': {'bn': 'বসো', 'en': 'Drop'},
        'sequenceOrder': 1,
        'feedback': {'bn': 'ব্যাখ্যা', 'en': 'Explanation'},
      }, 'item').toDomain();

      expect(item.feedback?.en, 'Explanation');
    });

    test('falls back to null when absent', () {
      final item = PracticeItemDto.fromJson({
        'id': 'drop',
        'label': {'bn': 'বসো', 'en': 'Drop'},
        'sequenceOrder': 1,
      }, 'item').toDomain();

      expect(item.feedback, isNull);
    });
  });

  group('KitItemDto.feedback', () {
    test('parses when present, alongside affirmation staying independent', () {
      final item = KitItemDto.fromJson({
        'id': 'toy',
        'label': {'bn': 'খেলনা', 'en': 'Toy'},
        'imageAsset': 'toy.png',
        'isCorrect': false,
        'feedback': {'bn': 'ব্যাখ্যা', 'en': 'Explanation'},
      }, 'item').toDomain();

      expect(item.feedback?.en, 'Explanation');
      expect(item.affirmation, isNull);
    });

    test('falls back to null when absent', () {
      final item = KitItemDto.fromJson({
        'id': 'toy',
        'label': {'bn': 'খেলনা', 'en': 'Toy'},
        'imageAsset': 'toy.png',
        'isCorrect': false,
      }, 'item').toDomain();

      expect(item.feedback, isNull);
    });
  });

  group('SignalInfoDto.feedback', () {
    test('parses when present, alongside affirmation staying independent', () {
      final signal = SignalInfoDto.fromJson({
        'id': 'calm',
        'colorHex': '#2E9E5B',
        'meaning': {'bn': 'ক', 'en': 'Calm'},
        'action': {'bn': 'খ', 'en': 'Play'},
        'actionIcon': 'a.png',
        'affirmation': {'bn': 'গ', 'en': 'Good job'},
        'feedback': {'bn': 'ব্যাখ্যা', 'en': 'Explanation'},
      }, 'signal').toDomain();

      expect(signal.feedback?.en, 'Explanation');
      expect(signal.affirmation?.en, 'Good job');
    });

    test('falls back to null when absent', () {
      final signal = SignalInfoDto.fromJson({
        'id': 'calm',
        'colorHex': '#2E9E5B',
        'meaning': {'bn': 'ক', 'en': 'Calm'},
        'action': {'bn': 'খ', 'en': 'Play'},
        'actionIcon': 'a.png',
      }, 'signal').toDomain();

      expect(signal.feedback, isNull);
    });
  });
}
