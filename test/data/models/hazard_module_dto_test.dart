import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/data/models/hazard_module_dto.dart';
import 'package:bipod_bondhu/data/models/manifest_exception.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';

Map<String, dynamic> _validManifest() => {
      'id': 'earthquake',
      'order': 1,
      'title': {'bn': 'ভূমিকম্প', 'en': 'Earthquake'},
      'themeColor': '#A0522D',
      'iconAsset': 'icons/earthquake.png',
      'safeAction': {'bn': 'নিরাপদ থাকো', 'en': 'Stay safe'},
      'badge': {
        'id': 'earthquake_badge',
        'title': {'bn': 'বীর', 'en': 'Hero'},
        'iconAsset': 'icons/badge.png',
      },
      'beats': [
        {
          'id': 'eq_story',
          'order': 1,
          'type': 'story',
          'slides': [
            {
              'imageAsset': 'a.png',
              'text': {'bn': 'ক', 'en': 'a'},
            },
          ],
        },
        {
          'id': 'eq_steps',
          'order': 2,
          'type': 'steps',
          'slides': [
            {
              'imageAsset': 'b.png',
              'text': {'bn': 'খ', 'en': 'b'},
            },
          ],
        },
        {
          'id': 'eq_practice',
          'order': 3,
          'type': 'practice',
          'gameId': 'tap_game',
          'config': {
            'instructions': {'bn': 'চাপো', 'en': 'Tap'},
            'items': [
              {
                'id': 'safe',
                'label': {'bn': 'নিরাপদ', 'en': 'Safe'},
                'isCorrect': true,
              },
              {
                'id': 'unsafe',
                'label': {'bn': 'বিপজ্জনক', 'en': 'Unsafe'},
                'isCorrect': false,
              },
            ],
          },
        },
        {
          'id': 'eq_quiz',
          'order': 4,
          'type': 'quiz',
          'questions': [
            {
              'id': 'q1',
              'prompt': {'bn': 'কী করবে?', 'en': 'What do you do?'},
              'options': [
                {
                  'id': 'a',
                  'label': {'bn': 'সঠিক', 'en': 'Right'},
                  'isCorrect': true,
                },
                {
                  'id': 'b',
                  'label': {'bn': 'ভুল', 'en': 'Wrong'},
                  'isCorrect': false,
                },
              ],
            },
          ],
        },
      ],
    };

void main() {
  group('HazardModuleDto.fromJson', () {
    test('parses a well-formed manifest into a HazardModule', () {
      final module = HazardModuleDto.fromJson(_validManifest()).toDomain();

      expect(module.id, 'earthquake');
      expect(module.order, 1);
      expect(module.title.en, 'Earthquake');
      expect(module.themeColorHex, '#A0522D');
      expect(module.badge.id, 'earthquake_badge');
      expect(module.beats, hasLength(4));
      expect(module.beats[0], isA<StoryBeat>());
      expect(module.beats[1], isA<StepsBeat>());
      expect(module.beats[2], isA<PracticeBeat>());
      expect(module.beats[3], isA<QuizBeat>());

      final quiz = module.beats[3] as QuizBeat;
      expect(quiz.questions, hasLength(1));
      expect(quiz.questions.first.options.any((o) => o.isCorrect), isTrue);
    });

    test('throws ManifestValidationException when a required field is missing', () {
      final broken = _validManifest()..remove('title');

      expect(() => HazardModuleDto.fromJson(broken), throwsA(isA<ManifestValidationException>()));
    });

    test('throws ManifestValidationException when beats is empty', () {
      final broken = _validManifest()..['beats'] = <dynamic>[];

      expect(() => HazardModuleDto.fromJson(broken), throwsA(isA<ManifestValidationException>()));
    });

    test('throws ManifestValidationException for an unknown beat type', () {
      final broken = _validManifest();
      (broken['beats'] as List)[0] = {
        'id': 'bad',
        'order': 1,
        'type': 'not_a_real_type',
      };

      expect(() => HazardModuleDto.fromJson(broken), throwsA(isA<ManifestValidationException>()));
    });

    test('throws ManifestValidationException when a quiz question has no correct option', () {
      final broken = _validManifest();
      final quizBeat = (broken['beats'] as List).last as Map<String, dynamic>;
      final question = (quizBeat['questions'] as List).first as Map<String, dynamic>;
      for (final option in question['options'] as List) {
        (option as Map<String, dynamic>)['isCorrect'] = false;
      }

      expect(() => HazardModuleDto.fromJson(broken), throwsA(isA<ManifestValidationException>()));
    });
  });
}
