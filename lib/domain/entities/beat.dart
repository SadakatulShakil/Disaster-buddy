import 'package:equatable/equatable.dart';

import 'practice_config.dart';
import 'quiz_question.dart';
import 'slide.dart';

/// One step inside a [HazardModule]'s learning flow. A module always has
/// exactly one of each subtype, in order: [StoryBeat], [StepsBeat],
/// [PracticeBeat], [QuizBeat].
sealed class Beat extends Equatable {
  const Beat({required this.id, required this.order});

  final String id;
  final int order;
}

/// A short narrated story introducing the hazard.
final class StoryBeat extends Beat {
  const StoryBeat({
    required super.id,
    required super.order,
    required this.slides,
  });

  final List<Slide> slides;

  @override
  List<Object?> get props => [id, order, slides];
}

/// The step-by-step safe action for the hazard.
final class StepsBeat extends Beat {
  const StepsBeat({
    required super.id,
    required super.order,
    required this.slides,
  });

  final List<Slide> slides;

  @override
  List<Object?> get props => [id, order, slides];
}

/// A mini-game that lets the child practice the safe action.
final class PracticeBeat extends Beat {
  const PracticeBeat({
    required super.id,
    required super.order,
    required this.gameId,
    required this.config,
  });

  final String gameId;
  final PracticeConfig config;

  @override
  List<Object?> get props => [id, order, gameId, config];
}

/// A short picture quiz checking what the child learned.
final class QuizBeat extends Beat {
  const QuizBeat({
    required super.id,
    required super.order,
    required this.questions,
  });

  final List<QuizQuestion> questions;

  @override
  List<Object?> get props => [id, order, questions];
}
