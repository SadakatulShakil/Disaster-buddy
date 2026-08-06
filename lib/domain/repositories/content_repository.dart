import '../../core/error/result.dart';
import '../entities/hazard_module.dart';

/// Read access to the static hazard content bundled as JSON manifests.
/// Implemented in the data layer by `ContentRepositoryImpl`.
abstract interface class ContentRepository {
  /// Loads every module listed in `AppConstants.initialHazards`, ordered by
  /// [HazardModule.order].
  Future<Result<List<HazardModule>>> getModules();

  /// Loads a single module by its hazard id (e.g. `"earthquake"`).
  Future<Result<HazardModule>> getModule(String moduleId);
}
