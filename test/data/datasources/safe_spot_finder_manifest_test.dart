// Loads the real assets/content/activities/safe_spot_finder.json manifest
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

const _assetKey = 'assets/content/activities/safe_spot_finder.json';

void main() {
  group('safe_spot_finder.json manifest', () {
    test('parses into a well-formed Activity', () async {
      final raw = File('assets/content/activities/safe_spot_finder.json').readAsStringSync();
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: raw}));

      final result = await source.loadActivity('safe_spot_finder');

      expect(result, isA<Success<Activity>>());
      final activity = (result as Success<Activity>).value;
      expect(activity.id, 'safe_spot_finder');
      expect(activity.type, ActivityType.safeSpotFinder);
      expect(activity.badge, isNotNull);
      final scenes = (activity.content as SafeSpotContent).scenes;
      expect(scenes.length, inInclusiveRange(2, 4));
      for (final scene in scenes) {
        expect(scene.spots.any((spot) => spot.isSafe), isTrue);
        for (final spot in scene.spots) {
          expect(spot.rect.x, inInclusiveRange(0.0, 1.0));
          expect(spot.rect.y, inInclusiveRange(0.0, 1.0));
        }
      }
    });

    test('a malformed variant (a scene with no safe spot) returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/safe_spot_finder.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      final firstScene = (broken['scenes'] as List).first as Map<String, dynamic>;
      for (final spot in firstScene['spots'] as List) {
        (spot as Map<String, dynamic>)['isSafe'] = false;
      }
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: jsonEncode(broken)}));

      final result = await source.loadActivity('safe_spot_finder');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('an unknown "type" returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/safe_spot_finder.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      broken['type'] = 'not_a_real_type';
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: jsonEncode(broken)}));

      final result = await source.loadActivity('safe_spot_finder');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('malformed JSON returns a Failure<ContentParseFailure>', () async {
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: '{ not valid json'}));

      final result = await source.loadActivity('safe_spot_finder');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });
  });
}
