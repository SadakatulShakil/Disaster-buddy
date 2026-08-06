import 'package:floor/floor.dart';

/// The outcome of one quiz attempt. Auto-generated id because a child may
/// retry the same quiz, and every attempt is kept.
@Entity(tableName: 'quiz_results')
class QuizResultEntity {
  const QuizResultEntity({
    this.id,
    required this.moduleId,
    required this.quizId,
    required this.correctCount,
    required this.totalCount,
    required this.attemptedAt,
  });

  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String moduleId;
  final String quizId;
  final int correctCount;
  final int totalCount;

  /// Epoch millis.
  final int attemptedAt;
}
