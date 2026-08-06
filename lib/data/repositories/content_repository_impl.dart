import '../../core/constants/app_constants.dart';
import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/hazard_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/content_asset_source.dart';

/// Loads modules from bundled JSON manifests via [ContentAssetSource].
final class ContentRepositoryImpl implements ContentRepository {
  const ContentRepositoryImpl(this._source);

  final ContentAssetSource _source;

  @override
  Future<Result<HazardModule>> getModule(String moduleId) => _source.loadModule(moduleId);

  @override
  Future<Result<List<HazardModule>>> getModules() async {
    final modules = <HazardModule>[];
    for (final hazardId in AppConstants.initialHazards) {
      final result = await _source.loadModule(hazardId);
      switch (result) {
        case Success<HazardModule>(value: final module):
          modules.add(module);
        case Failure<HazardModule>(failure: final failure):
          AppLogger.error('getModules aborted: failed to load "$hazardId": ${failure.message}');
          return Failure(failure);
      }
    }
    modules.sort((a, b) => a.order.compareTo(b.order));
    return Success(modules);
  }
}
