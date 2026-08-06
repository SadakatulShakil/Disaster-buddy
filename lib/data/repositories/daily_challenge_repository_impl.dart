import '../../core/error/result.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/repositories/daily_challenge_repository.dart';
import '../datasources/daily_challenge_asset_source.dart';

final class DailyChallengeRepositoryImpl implements DailyChallengeRepository {
  const DailyChallengeRepositoryImpl(this._source);

  final DailyChallengeAssetSource _source;

  @override
  Future<Result<List<DailyChallenge>>> getChallenges() => _source.loadChallenges();
}
