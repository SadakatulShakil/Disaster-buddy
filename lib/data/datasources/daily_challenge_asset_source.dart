import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/daily_challenge.dart';
import '../models/daily_challenge_dto.dart';
import '../models/manifest_exception.dart';

/// Loads the bundled daily-challenge pool from
/// [AssetPaths.dailyChallenges]. Mirrors [ContentAssetSource]'s
/// parsing/failure-handling exactly — every failure mode is caught here and
/// converted into a [Result]; this never throws.
abstract interface class DailyChallengeAssetSource {
  Future<Result<List<DailyChallenge>>> loadChallenges();
}

final class DailyChallengeAssetSourceImpl implements DailyChallengeAssetSource {
  DailyChallengeAssetSourceImpl({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Result<List<DailyChallenge>>> loadChallenges() async {
    const path = AssetPaths.dailyChallenges;
    try {
      final raw = await _bundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final challenges = DailyChallengePoolDto.fromJson(json).toDomain();
      return Success(challenges);
    } on ManifestValidationException catch (e, st) {
      AppLogger.error('Invalid daily challenge pool at $path', error: e, stackTrace: st);
      return Failure(ContentParseFailure('The daily challenges could not be read.', cause: e, stackTrace: st));
    } on FormatException catch (e, st) {
      AppLogger.error('Malformed JSON at $path', error: e, stackTrace: st);
      return Failure(ContentParseFailure('The daily challenges could not be read.', cause: e, stackTrace: st));
    } on TypeError catch (e, st) {
      AppLogger.error('Unexpected JSON shape at $path', error: e, stackTrace: st);
      return Failure(ContentParseFailure('The daily challenges could not be read.', cause: e, stackTrace: st));
    } on FlutterError catch (e, st) {
      AppLogger.error('Asset not found at $path', error: e, stackTrace: st);
      return Failure(AssetNotFoundFailure('The daily challenges are missing.', cause: e, stackTrace: st));
    } catch (e, st) {
      AppLogger.error('Unknown error loading $path', error: e, stackTrace: st);
      return Failure(UnknownFailure('Something went wrong loading the daily challenges.', cause: e, stackTrace: st));
    }
  }
}
