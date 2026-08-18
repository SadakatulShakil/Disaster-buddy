// Loads the real assets/content/activities/signal_colours.json manifest
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

const _assetKey = 'assets/content/activities/signal_colours.json';

void main() {
  group('signal_colours.json manifest', () {
    test('parses into a well-formed Activity', () async {
      final raw = File('assets/content/activities/signal_colours.json').readAsStringSync();
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: raw}));

      final result = await source.loadActivity('signal_colours');

      expect(result, isA<Success<Activity>>());
      final activity = (result as Success<Activity>).value;
      expect(activity.id, 'signal_colours');
      expect(activity.type, ActivityType.signalColours);
      expect(activity.badge, isNotNull);
      final signals = (activity.content as SignalColoursContent).signals;
      expect(signals.length, greaterThanOrEqualTo(2));
      for (final signal in signals) {
        expect(signal.colorHex, startsWith('#'));
        expect(signal.affirmation, isNotNull);
        // UX pass: every signal carries its own specific wrong-tap feedback.
        expect(signal.feedback, isNotNull, reason: 'signal "${signal.id}" is missing feedback');
      }
    });

    test('a malformed variant (empty signals) returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/signal_colours.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      broken['signals'] = <dynamic>[];
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: jsonEncode(broken)}));

      final result = await source.loadActivity('signal_colours');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('an unknown "type" returns a Failure<ContentParseFailure>', () async {
      final raw = File('assets/content/activities/signal_colours.json').readAsStringSync();
      final broken = jsonDecode(raw) as Map<String, dynamic>;
      broken['type'] = 'not_a_real_type';
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: jsonEncode(broken)}));

      final result = await source.loadActivity('signal_colours');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });

    test('malformed JSON returns a Failure<ContentParseFailure>', () async {
      final source = ActivityAssetSourceImpl(bundle: _FakeAssetBundle({_assetKey: '{ not valid json'}));

      final result = await source.loadActivity('signal_colours');

      expect(result, isA<Failure<Activity>>());
      expect((result as Failure<Activity>).failure, isA<ContentParseFailure>());
    });
  });
}
