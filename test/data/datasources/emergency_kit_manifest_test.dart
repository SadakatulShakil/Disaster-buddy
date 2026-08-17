// Loads the real assets/content/activities/emergency_kit.json manifest
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

void main() {
  group('emergency_kit.json manifest', () {
    test('parses into a well-formed Activity', () async {
      final raw = File('assets/content/activities/emergency_kit.json').readAsStringSync();
      final source = ActivityAssetSourceImpl(
        bundle: _FakeAssetBundle({'assets/content/activities/emergency_kit.json': raw}),
      );

      final result = await source.loadActivity('emergency_kit');

      expect(result, isA<Success<Activity>>());
      final activity = (result as Success<Activity>).value;
      expect(activity.id, 'emergency_kit');
      expect(activity.type, ActivityType.kitBuilder);
      expect(activity.badge?.id, 'ready_kit_badge');
      final items = (activity.content as KitBuilderContent).items;
      expect(items.where((item) => item.isCorrect), hasLength(7));
      expect(items.where((item) => !item.isCorrect), hasLength(4));
      for (final item in items.where((item) => item.isCorrect)) {
        expect(item.affirmation, isNotNull);
      }
    });

    test('a malformed variant (no correct items) returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/emergency_kit.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      for (final item in broken['items'] as List) {
        (item as Map<String, dynamic>)['isCorrect'] = false;
      }
      final source = ActivityAssetSourceImpl(
        bundle: _FakeAssetBundle({'assets/content/activities/emergency_kit.json': jsonEncode(broken)}),
      );

      final result = await source.loadActivity('emergency_kit');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('malformed JSON returns a Failure<ContentParseFailure>', () async {
      final source = ActivityAssetSourceImpl(
        bundle: _FakeAssetBundle({'assets/content/activities/emergency_kit.json': '{ not valid json'}),
      );

      final result = await source.loadActivity('emergency_kit');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });
  });
}
