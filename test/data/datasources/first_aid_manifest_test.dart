// Loads the real assets/content/first_aid.json manifest through the full
// ContentAssetSourceImpl -> HazardModuleDto pipeline, so a mistake in the
// actual shipped content (not a synthetic fixture) fails this test.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/data/datasources/content_asset_source.dart';
import 'package:bipod_bondhu/domain/entities/beat.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';

class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this._contentsByKey);

  final Map<String, String> _contentsByKey;

  @override
  Future<ByteData> load(String key) async {
    final content = _contentsByKey[key];
    if (content == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  group('first_aid.json manifest', () {
    test('parses into a well-formed HazardModule', () async {
      final raw = File('assets/content/first_aid.json').readAsStringSync();
      final source = ContentAssetSourceImpl(bundle: _FakeAssetBundle({'assets/content/first_aid.json': raw}));

      final result = await source.loadModule('first_aid');

      expect(result, isA<Success<HazardModule>>());
      final module = (result as Success<HazardModule>).value;
      expect(module.id, 'first_aid');
      expect(module.badge.id, 'first_aid_badge');
      expect(module.beats, hasLength(4));
      expect(module.beats[0], isA<StoryBeat>());
      expect(module.beats[1], isA<StepsBeat>());
      expect(module.beats[2], isA<PracticeBeat>());
      expect(module.beats[3], isA<QuizBeat>());

      final practice = module.beats[2] as PracticeBeat;
      expect(practice.gameId, 'sequence_tap');
      expect(practice.config.items, hasLength(3));
      expect(
        practice.config.items.map((item) => item.sequenceOrder).toList(),
        containsAll(<int>[1, 2, 3]),
      );

      final quiz = module.beats[3] as QuizBeat;
      expect(quiz.questions, isNotEmpty);
      for (final question in quiz.questions) {
        expect(question.options.any((option) => option.isCorrect), isTrue);
      }
    });

    test('a malformed variant returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/first_aid.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>..remove('beats');
      final source = ContentAssetSourceImpl(
        bundle: _FakeAssetBundle({'assets/content/first_aid.json': jsonEncode(broken)}),
      );

      final result = await source.loadModule('first_aid');

      expect(result, isA<Failure<HazardModule>>());
      expect((result as Failure<HazardModule>).failure, isA<ContentParseFailure>());
    });
  });
}
