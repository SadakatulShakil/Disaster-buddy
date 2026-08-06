// Phase E1: DailyChallengeAssetSource must load the real bundled pool
// cleanly, and convert any malformed content into a ContentParseFailure
// rather than throwing.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/data/datasources/daily_challenge_asset_source.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';

class _StringAssetBundle extends AssetBundle {
  _StringAssetBundle(this._value);

  final String _value;

  @override
  Future<ByteData> load(String key) async => ByteData(0);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and parses the real bundled daily_challenges.json', () async {
    final source = DailyChallengeAssetSourceImpl();

    final result = await source.loadChallenges();

    expect(result, isA<Success<List<DailyChallenge>>>());
    final challenges = (result as Success<List<DailyChallenge>>).value;
    expect(challenges, isNotEmpty);
    // Every hazard should be represented so selection/preference logic has
    // real candidates to work with.
    final hazards = challenges.map((c) => c.relatedHazardId).toSet();
    expect(hazards, {'earthquake', 'flood', 'lightning', 'first_aid'});
  });

  test('returns a ContentParseFailure for malformed JSON syntax', () async {
    final source = DailyChallengeAssetSourceImpl(bundle: _StringAssetBundle('not valid json'));

    final result = await source.loadChallenges();

    expect(result, isA<Failure<List<DailyChallenge>>>());
    expect((result as Failure<List<DailyChallenge>>).failure, isA<ContentParseFailure>());
  });

  test('returns a ContentParseFailure for an empty challenge pool', () async {
    final source = DailyChallengeAssetSourceImpl(bundle: _StringAssetBundle('{"challenges": []}'));

    final result = await source.loadChallenges();

    expect(result, isA<Failure<List<DailyChallenge>>>());
    expect((result as Failure<List<DailyChallenge>>).failure, isA<ContentParseFailure>());
  });

  test('returns a ContentParseFailure for an unknown challenge type', () async {
    const json = '''
    {
      "challenges": [
        {
          "id": "dc_1",
          "type": "not_a_type",
          "relatedHazardId": "earthquake",
          "payload": {}
        }
      ]
    }
    ''';
    final source = DailyChallengeAssetSourceImpl(bundle: _StringAssetBundle(json));

    final result = await source.loadChallenges();

    expect(result, isA<Failure<List<DailyChallenge>>>());
    expect((result as Failure<List<DailyChallenge>>).failure, isA<ContentParseFailure>());
  });
}
