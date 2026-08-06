import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/daily_challenge.dart';
import 'package:bipod_bondhu/domain/repositories/daily_challenge_repository.dart';

/// In-memory [DailyChallengeRepository] test double backed by a fixed pool.
class FakeDailyChallengeRepository implements DailyChallengeRepository {
  FakeDailyChallengeRepository(this.challenges);

  final List<DailyChallenge> challenges;

  @override
  Future<Result<List<DailyChallenge>>> getChallenges() async => Success(challenges);
}
