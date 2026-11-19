/// Core, UI-independent domain models for the MathClash K-5 math game.
///
/// This library intentionally has no Flutter imports so it can be unit tested
/// and reused by the question-bank tooling.
library;

enum GradeLevel {
  kindergarten(0, 'Kindergarten', 'K'),
  grade1(1, 'Grade 1', '1'),
  grade2(2, 'Grade 2', '2'),
  grade3(3, 'Grade 3', '3'),
  grade4(4, 'Grade 4', '4'),
  grade5(5, 'Grade 5', '5');

  const GradeLevel(this.value, this.label, this.shortLabel);

  final int value;
  final String label;
  final String shortLabel;

  static GradeLevel fromValue(int? value) {
    return GradeLevel.values.firstWhere(
      (grade) => grade.value == value,
      orElse: () => GradeLevel.grade1,
    );
  }

  /// Topics that match the core learning objectives for this grade.
  ///
  /// The question generator can create every topic for every grade, but rooms,
  /// practice and the learning flow only offer skills that belong in the
  /// child's grade band.
  List<MathTopic> get topics => switch (this) {
    GradeLevel.kindergarten => const [
      MathTopic.mixed,
      MathTopic.addition,
      MathTopic.subtraction,
      MathTopic.geometry,
    ],
    GradeLevel.grade1 => const [
      MathTopic.mixed,
      MathTopic.addition,
      MathTopic.subtraction,
      MathTopic.placeValue,
      MathTopic.geometry,
      MathTopic.measurement,
    ],
    GradeLevel.grade2 => const [
      MathTopic.mixed,
      MathTopic.addition,
      MathTopic.subtraction,
      MathTopic.placeValue,
      MathTopic.multiplication,
      MathTopic.geometry,
      MathTopic.measurement,
    ],
    GradeLevel.grade3 => const [
      MathTopic.mixed,
      MathTopic.addition,
      MathTopic.subtraction,
      MathTopic.multiplication,
      MathTopic.division,
      MathTopic.fractions,
      MathTopic.geometry,
      MathTopic.measurement,
    ],
    GradeLevel.grade4 || GradeLevel.grade5 => MathTopic.values,
  };
}

enum MathTopic {
  addition('addition', 'Addition', '+'),
  subtraction('subtraction', 'Subtraction', '−'),
  multiplication('multiplication', 'Multiplication', '×'),
  division('division', 'Division', '÷'),
  fractions('fractions', 'Fractions', '½'),
  geometry('geometry', 'Geometry', '△'),
  measurement('measurement', 'Measurement', '📏'),
  placeValue('place_value', 'Place Value', '10'),
  mixed('mixed', 'Mixed Challenge', '★');

  const MathTopic(this.dbValue, this.label, this.symbol);

  final String dbValue;
  final String label;
  final String symbol;

  static MathTopic fromValue(String? value) {
    return MathTopic.values.firstWhere(
      (topic) => topic.dbValue == value,
      orElse: () => MathTopic.mixed,
    );
  }
}

enum MathDifficulty {
  easy('easy', 'Easy', 'Gentle start'),
  medium('medium', 'Medium', 'A good stretch'),
  hard('hard', 'Hard', 'Brain booster'),
  adaptive('adaptive', 'Adaptive', 'Matches your level');

  const MathDifficulty(this.dbValue, this.label, this.blurb);

  final String dbValue;
  final String label;
  final String blurb;

  static MathDifficulty fromValue(String? value) {
    return MathDifficulty.values.firstWhere(
      (difficulty) => difficulty.dbValue == value,
      orElse: () => MathDifficulty.medium,
    );
  }
}

enum RoomVisibility {
  public('public', 'Public', 'Anyone can find and join this room.'),
  private('private', 'Private', 'Only friends with the code can join.');

  const RoomVisibility(this.dbValue, this.label, this.description);

  final String dbValue;
  final String label;
  final String description;

  static RoomVisibility fromValue(String? value) {
    return RoomVisibility.values.firstWhere(
      (visibility) => visibility.dbValue == value,
      orElse: () => RoomVisibility.private,
    );
  }
}

enum RoomPhase {
  waiting('waiting'),
  countdown('countdown'),
  questionActive('question_active'),
  questionReveal('question_reveal'),
  nextQuestion('next_question'),
  finalResults('final_results'),
  completed('completed'),
  abandoned('abandoned');

  const RoomPhase(this.dbValue);

  final String dbValue;

  bool get isActiveMatch =>
      this == RoomPhase.countdown ||
      this == RoomPhase.questionActive ||
      this == RoomPhase.questionReveal ||
      this == RoomPhase.nextQuestion;

  bool get isFinished =>
      this == RoomPhase.finalResults ||
      this == RoomPhase.completed ||
      this == RoomPhase.abandoned;

  static RoomPhase fromValue(String? value) {
    return RoomPhase.values.firstWhere(
      (phase) => phase.dbValue == value,
      orElse: () => RoomPhase.waiting,
    );
  }
}

enum AnswerType {
  choice('choice'),
  numeric('numeric'),
  fraction('fraction'),
  text('text');

  const AnswerType(this.dbValue);

  final String dbValue;

  static AnswerType fromValue(String? value) {
    return AnswerType.values.firstWhere(
      (type) => type.dbValue == value,
      orElse: () => AnswerType.choice,
    );
  }
}

enum MatchOutcome {
  win('win'),
  loss('loss'),
  draw('draw');

  const MatchOutcome(this.dbValue);

  final String dbValue;

  static MatchOutcome? fromValue(String? value) {
    for (final outcome in MatchOutcome.values) {
      if (outcome.dbValue == value) return outcome;
    }
    return null;
  }
}

enum MasteryLevel {
  notStarted('not_started', 'Not started', 0),
  learning('learning', 'Learning', 1),
  practicing('practicing', 'Practicing', 2),
  proficient('proficient', 'Proficient', 3),
  mastered('mastered', 'Mastered', 4);

  const MasteryLevel(this.dbValue, this.label, this.order);

  final String dbValue;
  final String label;
  final int order;

  static MasteryLevel fromValue(String? value) {
    return MasteryLevel.values.firstWhere(
      (level) => level.dbValue == value,
      orElse: () => MasteryLevel.notStarted,
    );
  }
}

/// A structured visual aid. The renderer is responsible for turning [type]
/// and [data] into an age-appropriate diagram.
class QuestionVisual {
  const QuestionVisual({required this.type, required this.data});

  final String type;
  final Map<String, Object?> data;

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  factory QuestionVisual.fromJson(Map<String, dynamic> json) {
    return QuestionVisual(
      type: json['type'] as String? ?? 'objects',
      data: Map<String, Object?>.from(
        (json['data'] as Map?) ?? const <String, Object?>{},
      ),
    );
  }
}

/// A fully validated question. The correct answer never leaves the server for
/// competitive matches until the reveal phase.
class MathQuestion {
  const MathQuestion({
    required this.grade,
    required this.topic,
    required this.difficulty,
    required this.skill,
    required this.text,
    required this.correctAnswer,
    required this.options,
    required this.explanation,
    required this.answerType,
    required this.estimatedSeconds,
    required this.curriculumTags,
    this.id,
    this.hint,
    this.visual,
    this.source = 'generated',
  });

  final String? id;
  final int grade;
  final MathTopic topic;
  final MathDifficulty difficulty;
  final String skill;
  final String text;
  final String correctAnswer;
  final List<String> options;
  final String explanation;
  final AnswerType answerType;
  final int estimatedSeconds;
  final List<String> curriculumTags;
  final String? hint;
  final QuestionVisual? visual;
  final String source;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'grade': grade,
      'topic': topic.dbValue,
      'difficulty': difficulty.dbValue,
      'skill': skill,
      'text': text,
      'correct_answer': correctAnswer,
      'options': options,
      'explanation': explanation,
      'answer_type': answerType.dbValue,
      'estimated_seconds': estimatedSeconds,
      'curriculum_tags': curriculumTags,
      'hint': hint,
      'visual': visual?.toJson(),
      'source': source,
    };
  }
}

/// Deterministic result of scoring one question.
class QuestionScoreResult {
  const QuestionScoreResult({
    required this.pointsByPlayer,
    required this.speedBonusPlayerId,
    required this.fastestCorrectPlayerId,
    required this.speedBonusWithheldForTie,
  });

  final Map<String, int> pointsByPlayer;
  final String? speedBonusPlayerId;
  final String? fastestCorrectPlayerId;
  final bool speedBonusWithheldForTie;
}

class AnswerRecord {
  const AnswerRecord({
    required this.playerId,
    required this.isCorrect,
    required this.submittedAt,
    required this.responseMs,
  });

  final String playerId;
  final bool isCorrect;
  final DateTime submittedAt;
  final int responseMs;
}

class PlayerStanding {
  const PlayerStanding({
    required this.playerId,
    required this.points,
    required this.correctCount,
    required this.correctResponseMs,
  });

  final String playerId;
  final int points;
  final int correctCount;
  final int correctResponseMs;
}

class PlayerRanking {
  const PlayerRanking({
    required this.playerId,
    required this.rank,
    required this.outcome,
    required this.points,
    required this.correctCount,
    required this.correctResponseMs,
    required this.isTied,
  });

  final String playerId;
  final int rank;
  final MatchOutcome outcome;
  final int points;
  final int correctCount;
  final int correctResponseMs;
  final bool isTied;
}
