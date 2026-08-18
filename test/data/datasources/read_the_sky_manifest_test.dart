// Loads the real assets/content/activities/read_the_sky.json manifest
// through the full ActivityAssetSourceImpl -> ActivityDto pipeline, so a
// mistake in the actual shipped content (not a synthetic fixture) fails
// this test.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/data/datasources/activity_asset_source.dart';
import 'package:bipod_bondhu/domain/entities/activity.dart';
import 'package:bipod_bondhu/domain/entities/activity_content.dart';
import 'package:bipod_bondhu/domain/entities/activity_type.dart';

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

const _assetKey = 'assets/content/activities/read_the_sky.json';

void main() {
  group('read_the_sky.json manifest', () {
    test('parses into a well-formed Activity', () async {
      final raw = File('assets/content/activities/read_the_sky.json').readAsStringSync();
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: raw}));

      final result = await source.loadActivity('read_the_sky');

      expect(result, isA<Success<Activity>>());
      final activity = (result as Success<Activity>).value;
      expect(activity.id, 'read_the_sky');
      expect(activity.type, ActivityType.readTheSky);
      expect(activity.badge, isNotNull);
      final signs = (activity.content as ReadTheSkyContent).signs;
      expect(signs.length, greaterThanOrEqualTo(4));
      for (final sign in signs) {
        expect(sign.image, isNotEmpty);
        expect(sign.options.length, greaterThanOrEqualTo(2));
        expect(sign.options.where((option) => option.isCorrect), hasLength(1));
      }

      // Content-accuracy guard: earthquakes have no reliable pre-warning
      // signs, so none of the shipped signs may claim to be one.
      final hazardTexts = [
        for (final sign in signs) ...[
          sign.correctHazard.en.toLowerCase(),
          sign.correctHazard.bn,
          for (final option in sign.options) option.label.en.toLowerCase(),
        ],
      ];
      for (final text in hazardTexts) {
        expect(text, isNot(contains('earthquake')));
        expect(text, isNot(contains('ভূমিকম্প')));
      }
    });

    test('a malformed variant (empty signs) returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/read_the_sky.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      broken['signs'] = <dynamic>[];
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: jsonEncode(broken)}));

      final result = await source.loadActivity('read_the_sky');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('a sign with no correct option returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/read_the_sky.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      final signs = broken['signs'] as List<dynamic>;
      final firstSign = signs[0] as Map<String, dynamic>;
      final options = firstSign['options'] as List<dynamic>;
      for (final option in options) {
        (option as Map<String, dynamic>)['isCorrect'] = false;
      }
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: jsonEncode(broken)}));

      final result = await source.loadActivity('read_the_sky');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('an unknown "type" returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/read_the_sky.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      broken['type'] = 'not_a_real_type';
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: jsonEncode(broken)}));

      final result = await source.loadActivity('read_the_sky');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('malformed JSON returns a Failure<ContentParseFailure>', () async {
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: '{ not valid json'}));

      final result = await source.loadActivity('read_the_sky');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });
  });
}
