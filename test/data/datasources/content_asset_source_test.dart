import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/data/datasources/content_asset_source.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';

/// A minimal [AssetBundle] test double so parsing can be exercised without
/// touching the real asset bundle.
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
  group('ContentAssetSourceImpl', () {
    test('returns a Success with the parsed module for well-formed JSON', () async {
      final validJson = jsonEncode({
        'id': 'flood',
        'order': 2,
        'title': {'bn': 'বন্যা', 'en': 'Flood'},
        'themeColor': '#2E86C1',
        'iconAsset': 'icons/flood.png',
        'safeAction': {'bn': 'নিরাপদ', 'en': 'Stay safe'},
        'badge': {
          'id': 'flood_badge',
          'title': {'bn': 'বীর', 'en': 'Hero'},
          'iconAsset': 'icons/badge.png',
        },
        'beats': [
          {
            'id': 'fl_story',
            'order': 1,
            'type': 'story',
            'slides': [
              {
                'imageAsset': 'a.png',
                'text': {'bn': 'ক', 'en': 'a'},
              },
            ],
          },
        ],
      });
      final source = ContentAssetSourceImpl(
        bundle: _FakeAssetBundle({'assets/content/flood.json': validJson}),
      );

      final result = await source.loadModule('flood');

      expect(result, isA<Success<HazardModule>>());
      expect((result as Success<HazardModule>).value.id, 'flood');
    });

    test('returns a Failure<ContentParseFailure> for malformed JSON', () async {
      final source = ContentAssetSourceImpl(
        bundle: _FakeAssetBundle({'assets/content/flood.json': '{ this is not valid json'}),
      );

      final result = await source.loadModule('flood');

      expect(result, isA<Failure<HazardModule>>());
      expect((result as Failure<HazardModule>).failure, isA<ContentParseFailure>());
    });

    test('returns a Failure<ContentParseFailure> when a required field is missing', () async {
      final invalidJson = jsonEncode({'id': 'flood'}); // missing everything else
      final source = ContentAssetSourceImpl(
        bundle: _FakeAssetBundle({'assets/content/flood.json': invalidJson}),
      );

      final result = await source.loadModule('flood');

      expect(result, isA<Failure<HazardModule>>());
      expect((result as Failure<HazardModule>).failure, isA<ContentParseFailure>());
    });

    test('returns a Failure<AssetNotFoundFailure> when the manifest is missing', () async {
      final source = ContentAssetSourceImpl(bundle: _FakeAssetBundle({}));

      final result = await source.loadModule('unknown_hazard');

      expect(result, isA<Failure<HazardModule>>());
      expect((result as Failure<HazardModule>).failure, isA<AssetNotFoundFailure>());
    });
  });
}
