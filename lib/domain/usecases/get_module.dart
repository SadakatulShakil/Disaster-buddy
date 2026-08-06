import '../../core/error/result.dart';
import '../entities/hazard_module.dart';
import '../repositories/content_repository.dart';

/// Loads a single hazard module by id, for screens that only need one
/// module (e.g. ModuleHome) rather than the whole adventure map.
final class GetModule {
  const GetModule(this._contentRepository);

  final ContentRepository _contentRepository;

  Future<Result<HazardModule>> call(String moduleId) => _contentRepository.getModule(moduleId);
}
