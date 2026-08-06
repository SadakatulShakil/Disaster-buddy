import 'package:floor/floor.dart';

import '../entities/quiz_result_entity.dart';

@dao
abstract class QuizResultDao {
  @Query('SELECT * FROM quiz_results WHERE moduleId = :moduleId AND quizId = :quizId ORDER BY attemptedAt DESC')
  Future<List<QuizResultEntity>> findByQuiz(String moduleId, String quizId);

  @Insert(onConflict: OnConflictStrategy.abort)
  Future<void> insertResult(QuizResultEntity entity);
}
