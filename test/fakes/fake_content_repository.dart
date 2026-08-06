import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/hazard_module.dart';
import 'package:bipod_bondhu/domain/repositories/content_repository.dart';

/// In-memory [ContentRepository] test double backed by a fixed module list.
class FakeContentRepository implements ContentRepository {
  FakeContentRepository(this.modules);

  final List<HazardModule> modules;

  @override
  Future<Result<HazardModule>> getModule(String moduleId) async {
    for (final module in modules) {
      if (module.id == moduleId) return Success(module);
    }
    throw StateError('No fake module registered for "$moduleId"');
  }

  @override
  Future<Result<List<HazardModule>>> getModules() async => Success(modules);
}
