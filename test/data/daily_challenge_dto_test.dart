// Phase E1: daily_challenges.json must parse into the right payload type
// per `type`, reusing QuizQuestionDto/PracticeConfigDto exactly — and a
// malformed entry must throw ManifestValidationException rather than a
// raw type-cast crash.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/data/models/daily_challenge_dto.dart';
import 'package:bipod_bondhu/data/models/manifest_exception.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';

Map<String, dynamic> _quizJson({String type = 'quiz'}) => {
      'id': 'dc_1',
      'type': type,
      'relatedHazardId': 'earthquake',
      'difficulty': 2,
      'payload': {
        'id': 'dc_1_q',
        'prompt': {'bn': 'প্রশ্ন', 'en': 'Question'},
        'options': [
          {
            'id': 'a',
            'label': {'bn': 'ক', 'en': 'A'},
            'isCorrect': true,
          },
          {
            'id': 'b',
            'label': {'bn': 'খ', 'en': 'B'},
            'isCorrect': false,
          },
        ],
      },
    };

Map<String, dynamic> _practiceJson({String type = 'spotTheDanger'}) => {
      'id': 'dc_2',
      'type': type,
      'relatedHazardId': 'flood',
      'difficulty': 1,
      'payload': {
        'gameId': 'tap_correct_choice',
        'instructions': {'bn': 'নির্দেশ', 'en': 'Instructions'},
        'items': [
          {
            'id': 'i1',
            'label': {'bn': 'এক', 'en': 'One'},
            'isCorrect': true,
          },
          {
            'id': 'i2',
            'label': {'bn': 'দুই', 'en': 'Two'},
            'isCorrect': false,
          },
        ],
      },
    };

void main() {
  group('DailyChallengeDto.fromJson', () {
    test('parses a quiz challenge into a QuizChallengePayload', () {
      final dto = DailyChallengeDto.fromJson(_quizJson(), 'ctx');
      final domain = dto.toDomain();

      expect(domain.type, DailyChallengeType.quiz);
      expect(domain.relatedHazardId, 'earthquake');
      expect(domain.difficulty, 2);
      expect(domain.payload, isA<QuizChallengePayload>());
      final payload = domain.payload as QuizChallengePayload;
      expect(payload.question.options, hasLength(2));
    });

    test('parses a whatWouldYouDo challenge the same way as quiz', () {
      final dto = DailyChallengeDto.fromJson(_quizJson(type: 'whatWouldYouDo'), 'ctx');
      expect(dto.toDomain().payload, isA<QuizChallengePayload>());
    });

    test('parses a spotTheDanger challenge into a PracticeChallengePayload', () {
      final dto = DailyChallengeDto.fromJson(_practiceJson(), 'ctx');
      final domain = dto.toDomain();

      expect(domain.type, DailyChallengeType.spotTheDanger);
      expect(domain.payload, isA<PracticeChallengePayload>());
      final payload = domain.payload as PracticeChallengePayload;
      expect(payload.gameId, 'tap_correct_choice');
      expect(payload.config.items, hasLength(2));
    });

    test('parses a kitRound challenge the same way as spotTheDanger', () {
      final dto = DailyChallengeDto.fromJson(_practiceJson(type: 'kitRound'), 'ctx');
      expect(dto.toDomain().payload, isA<PracticeChallengePayload>());
    });

    test('defaults difficulty to 1 when omitted', () {
      final json = _quizJson()..remove('difficulty');
      final dto = DailyChallengeDto.fromJson(json, 'ctx');
      expect(dto.difficulty, 1);
    });

    test('throws ManifestValidationException for an unknown type', () {
      expect(
        () => DailyChallengeDto.fromJson(_quizJson(type: 'not_a_real_type'), 'ctx'),
        throwsA(isA<ManifestValidationException>()),
      );
    });

    test('throws ManifestValidationException when a required field is missing', () {
      final json = _quizJson()..remove('relatedHazardId');
      expect(() => DailyChallengeDto.fromJson(json, 'ctx'), throwsA(isA<ManifestValidationException>()));
    });

    test('throws ManifestValidationException when payload is missing', () {
      final json = _quizJson()..remove('payload');
      expect(() => DailyChallengeDto.fromJson(json, 'ctx'), throwsA(isA<ManifestValidationException>()));
    });
  });

  group('DailyChallengePoolDto.fromJson', () {
    test('parses a list of mixed-type challenges', () {
      final pool = DailyChallengePoolDto.fromJson({
        'challenges': [_quizJson(), _practiceJson()],
      });
      expect(pool.toDomain(), hasLength(2));
    });

    test('throws ManifestValidationException for an empty pool', () {
      expect(
        () => DailyChallengePoolDto.fromJson({'challenges': <Object?>[]}),
        throwsA(isA<ManifestValidationException>()),
      );
    });

    test('throws ManifestValidationException when "challenges" is missing', () {
      expect(() => DailyChallengePoolDto.fromJson({}), throwsA(isA<ManifestValidationException>()));
    });
  });
}
