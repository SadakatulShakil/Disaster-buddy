import '../../core/error/result.dart';
import '../entities/hazard_module.dart';
import '../repositories/content_repository.dart';

/// Loads every hazard module for the adventure map.
final class GetModules {
  const GetModules(this._contentRepository);

  final ContentRepository _contentRepository;

  Future<Result<List<HazardModule>>> call() => _contentRepository.getModules();
}
