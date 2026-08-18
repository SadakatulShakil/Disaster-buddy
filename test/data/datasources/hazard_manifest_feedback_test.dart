// UX pass: every wrong quiz option and every practice item across all four
// real hazard manifests must carry specific, kind feedback text (not rely
// on the generic fallback) — and the manifests must still parse cleanly
// through the full ContentAssetSourceImpl -> HazardModuleDto pipeline with
// that content added.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<HazardModule> _loadRealModule(String hazardId) async {
  final path = 'assets/content/$hazardId.json';
  final raw = File(path).readAsStringSync();
  final source = ContentAssetSourceImpl(bundle: _FakeAssetBundle({path: raw}));

  final result = await source.loadModule(hazardId);
  expect(result, isA<Success<HazardModule>>());
  return (result as Success<HazardModule>).value;
}

void main() {
  for (final hazardId in ['earthquake', 'flood', 'lightning', 'first_aid']) {
    group('$hazardId.json', () {
      test('every wrong quiz option carries specific feedback', () async {
        final module = await _loadRealModule(hazardId);
        final quiz = module.beats.whereType<QuizBeat>().single;

        for (final question in quiz.questions) {
          for (final option in question.options) {
            if (!option.isCorrect) {
              expect(
                option.feedback,
                isNotNull,
                reason: '$hazardId question "${question.id}" option "${option.id}" is missing feedback',
              );
            }
          }
        }
      });

      test('every non-correct practice item carries specific feedback', () async {
        // Sequence-style items (e.g. Drop/Cover/Hold On) are never marked
        // `isCorrect` — every one of them can be tapped "out of turn", so
        // every one needs its own feedback. Choice-style items mark exactly
        // one `isCorrect` — that one is never wrong to tap, so only its
        // distractors need feedback.
        final module = await _loadRealModule(hazardId);
        final practice = module.beats.whereType<PracticeBeat>().single;

        for (final item in practice.config.items.where((item) => !item.isCorrect)) {
          expect(
            item.feedback,
            isNotNull,
            reason: '$hazardId practice item "${item.id}" is missing feedback',
          );
        }
      });
    });
  }
}
