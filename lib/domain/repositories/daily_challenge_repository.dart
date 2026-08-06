import '../../core/error/result.dart';
import '../entities/daily_challenge.dart';

/// The bundled pool of daily challenges content lives behind this
/// repository — mirrors [ContentRepository]'s shape for the same reason:
/// selection logic shouldn't care whether the pool came from a bundled
/// asset or, later, a remote source.
abstract interface class DailyChallengeRepository {
  Future<Result<List<DailyChallenge>>> getChallenges();
}
