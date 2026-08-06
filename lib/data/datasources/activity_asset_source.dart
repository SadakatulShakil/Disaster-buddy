import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/activity.dart';
import '../models/activity_dto.dart';
import '../models/manifest_exception.dart';

/// Loads a cross-cutting activity's content manifest from
/// `assets/content/activities/<id>.json`. Mirrors [ContentAssetSource]'s
/// parsing/failure-handling exactly, kept as a parallel source since
/// [Activity] has a different shape (items, no beats) than [HazardModule].
abstract interface class ActivityAssetSource {
  Future<Result<Activity>> loadActivity(String activityId);
}

/// Reads manifests via [AssetBundle] and parses them with [ActivityDto].
/// Every failure mode (missing asset, malformed JSON, invalid schema) is
/// caught here and converted into a [Result] — this never throws.
final class ActivityAssetSourceImpl implements ActivityAssetSource {
  ActivityAssetSourceImpl({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Result<Activity>> loadActivity(String activityId) async {
    final path = AssetPaths.activityManifest(activityId);
    try {
      final raw = await _bundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final activity = ActivityDto.fromJson(json).toDomain();
      return Success(activity);
    } on ManifestValidationException catch (e, st) {
      AppLogger.error('Invalid activity manifest at $path', error: e, stackTrace: st);
      return Failure(
        ContentParseFailure('The content for "$activityId" could not be read.', cause: e, stackTrace: st),
      );
    } on FormatException catch (e, st) {
      AppLogger.error('Malformed JSON at $path', error: e, stackTrace: st);
      return Failure(
        ContentParseFailure('The content for "$activityId" could not be read.', cause: e, stackTrace: st),
      );
    } on TypeError catch (e, st) {
      AppLogger.error('Unexpected JSON shape at $path', error: e, stackTrace: st);
      return Failure(
        ContentParseFailure('The content for "$activityId" could not be read.', cause: e, stackTrace: st),
      );
    } on FlutterError catch (e, st) {
      AppLogger.error('Asset not found at $path', error: e, stackTrace: st);
      return Failure(AssetNotFoundFailure('The content for "$activityId" is missing.', cause: e, stackTrace: st));
    } catch (e, st) {
      AppLogger.error('Unknown error loading $path', error: e, stackTrace: st);
      return Failure(UnknownFailure('Something went wrong loading "$activityId".', cause: e, stackTrace: st));
    }
  }
}
