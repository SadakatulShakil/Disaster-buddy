import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/asset_paths.dart';
import '../../core/error/failures.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/hazard_module.dart';
import '../models/hazard_module_dto.dart';
import '../models/manifest_exception.dart';

/// Loads a hazard's content manifest from `assets/content/<id>.json`.
abstract interface class ContentAssetSource {
  Future<Result<HazardModule>> loadModule(String hazardId);
}

/// Reads manifests via [AssetBundle] and parses them with [HazardModuleDto].
/// Every failure mode (missing asset, malformed JSON, invalid schema) is
/// caught here and converted into a [Result] — this never throws.
final class ContentAssetSourceImpl implements ContentAssetSource {
  ContentAssetSourceImpl({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Result<HazardModule>> loadModule(String hazardId) async {
    final path = AssetPaths.manifest(hazardId);
    try {
      final raw = await _bundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final module = HazardModuleDto.fromJson(json).toDomain();
      return Success(module);
    } on ManifestValidationException catch (e, st) {
      AppLogger.error('Invalid manifest at $path', error: e, stackTrace: st);
      return Failure(ContentParseFailure('The content for "$hazardId" could not be read.', cause: e, stackTrace: st));
    } on FormatException catch (e, st) {
      AppLogger.error('Malformed JSON at $path', error: e, stackTrace: st);
      return Failure(ContentParseFailure('The content for "$hazardId" could not be read.', cause: e, stackTrace: st));
    } on TypeError catch (e, st) {
      AppLogger.error('Unexpected JSON shape at $path', error: e, stackTrace: st);
      return Failure(ContentParseFailure('The content for "$hazardId" could not be read.', cause: e, stackTrace: st));
    } on FlutterError catch (e, st) {
      AppLogger.error('Asset not found at $path', error: e, stackTrace: st);
      return Failure(AssetNotFoundFailure('The content for "$hazardId" is missing.', cause: e, stackTrace: st));
    } catch (e, st) {
      AppLogger.error('Unknown error loading $path', error: e, stackTrace: st);
      return Failure(UnknownFailure('Something went wrong loading "$hazardId".', cause: e, stackTrace: st));
    }
  }
}
