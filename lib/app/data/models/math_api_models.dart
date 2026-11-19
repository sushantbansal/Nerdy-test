import '../../domain/models/math_models.dart';

/// Typed client-side view of the JSON returned by the authoritative RPCs.
///
/// The database is the source of truth. These models only parse what the
/// server is allowed to expose at the current phase; answer keys are `null`
/// until the reveal snapshot.

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => '$item').toList(growable: false);
  }
  return const <String>[];
}

String _string(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return '$value';
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final text = '$value';
  return text.isEmpty ? null : text;
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double _double(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

bool _bool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return '$value' == 'true';
}

DateTime _date(dynamic value) {
  final parsed = DateTime.tryParse('$value');
  return (parsed ?? DateTime.now()).toUtc();
}

DateTime? _optionalDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse('$value')?.toUtc();
}

class MathRoom {
  const MathRoom({
    required this.id,
    required this.code,
    required this.name,
    required this.hostId,
    required this.visibility,
    required this.grade,
    required this.topics,
    required this.difficulty,
    required this.questionCount,
    required this.answerSeconds,
    required this.maxPlayers,
    required this.speedBonusEnabled,
    required this.autoStart,
    required this.status,
    required this.isHost,
    required this.myReady,
    required this.canStart,
    this.countdownEndsAt,
  });

  final String id;
  final String code;
  final String name;
  final String hostId;
  final RoomVisibility visibility;
  final GradeLevel grade;
  final List<MathTopic> topics;
  final MathDifficulty difficulty;
  final int questionCount;
  final int answerSeconds;
  final int maxPlayers;
  final bool speedBonusEnabled;
  final bool autoStart;
  final RoomPhase status;
  final bool isHost;
  final bool myReady;
  final bool canStart;
  final DateTime? countdownEndsAt;

  bool get isWaiting => status == RoomPhase.waiting;

  factory MathRoom.fromJson(Map<String, dynamic> json) {
    return MathRoom(
      id: _string(json['id']),
      code: _string(json['room_code']),
      name: _string(json['name'], 'MathClash Room'),
      hostId: _string(json['host_id']),
      visibility: RoomVisibility.fromValue(_string(json['visibility'])),
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
      topics: _stringList(json['topics']).map(MathTopic.fromValue).toList(),
      difficulty: MathDifficulty.fromValue(_string(json['difficulty'])),
      questionCount: _int(json['question_count'], 5),
      answerSeconds: _int(json['answer_seconds'], 18),
      maxPlayers: _int(json['max_players'], 4),
      speedBonusEnabled: _bool(json['speed_bonus_enabled'], true),
      autoStart: _bool(json['auto_start']),
      status: RoomPhase.fromValue(_string(json['status'])),
      isHost: _bool(json['is_host']),
      myReady: _bool(json['my_ready']),
      canStart: _bool(json['can_start']),
      countdownEndsAt: _optionalDate(json['countdown_ends_at']),
    );
  }
}

class MathRoomSummary {
  const MathRoomSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.hostName,
    required this.hostAvatarIndex,
    required this.hostAvatarColor,
    required this.grade,
    required this.topics,
    required this.difficulty,
    required this.questionCount,
    required this.answerSeconds,
    required this.maxPlayers,
    required this.playerCount,
    required this.speedBonusEnabled,
    required this.isJoined,
  });

  final String id;
  final String code;
  final String name;
  final String hostName;
  final int hostAvatarIndex;
  final String hostAvatarColor;
  final GradeLevel grade;
  final List<MathTopic> topics;
  final MathDifficulty difficulty;
  final int questionCount;
  final int answerSeconds;
  final int maxPlayers;
  final int playerCount;
  final bool speedBonusEnabled;
  final bool isJoined;

  int get openSlots => (maxPlayers - playerCount).clamp(0, maxPlayers);
  bool get isFull => playerCount >= maxPlayers;

  factory MathRoomSummary.fromJson(Map<String, dynamic> json) {
    return MathRoomSummary(
      id: _string(json['id']),
      code: _string(json['room_code']),
      name: _string(json['name'], 'MathClash Room'),
      hostName: _string(json['host_name'], 'Player'),
      hostAvatarIndex: _int(json['host_avatar_index']),
      hostAvatarColor: _string(json['host_avatar_color'], '#00A2FF'),
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
      topics: _stringList(json['topics']).map(MathTopic.fromValue).toList(),
      difficulty: MathDifficulty.fromValue(_string(json['difficulty'])),
      questionCount: _int(json['question_count'], 5),
      answerSeconds: _int(json['answer_seconds'], 18),
      maxPlayers: _int(json['max_players'], 4),
      playerCount: _int(json['player_count']),
      speedBonusEnabled: _bool(json['speed_bonus_enabled'], true),
      isJoined: _bool(json['is_joined']),
    );
  }
}

class MathRoomPlayer {
  const MathRoomPlayer({
    required this.playerId,
    required this.displayName,
    required this.avatarIndex,
    required this.avatarColor,
    required this.seat,
    required this.isReady,
    required this.isConnected,
    required this.isHost,
    required this.points,
    required this.correctCount,
    required this.speedBonusCount,
    required this.submittedCurrent,
  });

  final String playerId;
  final String displayName;
  final int avatarIndex;
  final String avatarColor;
  final int seat;
  final bool isReady;
  final bool isConnected;
  final bool isHost;
  final int points;
  final int correctCount;
  final int speedBonusCount;
  final bool submittedCurrent;

  factory MathRoomPlayer.fromJson(Map<String, dynamic> json) {
    return MathRoomPlayer(
      playerId: _string(json['player_id']),
      displayName: _string(json['display_name'], 'Player'),
      avatarIndex: _int(json['avatar_index']),
      avatarColor: _string(json['avatar_color'], '#00A2FF'),
      seat: _int(json['seat']),
      isReady: _bool(json['is_ready']),
      isConnected: _bool(json['is_connected'], true),
      isHost: _bool(json['is_host']),
      points: _int(json['points']),
      correctCount: _int(json['correct_count']),
      speedBonusCount: _int(json['speed_bonus_count']),
      submittedCurrent: _bool(json['submitted_current']),
    );
  }
}

class MathMatchInfo {
  const MathMatchInfo({
    required this.id,
    required this.matchNumber,
    required this.status,
    required this.questionIndex,
    required this.questionCount,
    required this.answerSeconds,
    required this.speedBonusEnabled,
    this.countdownEndsAt,
    this.questionStartedAt,
    this.questionEndsAt,
    this.revealEndsAt,
    this.nextStartsAt,
    this.completedAt,
  });

  final String id;
  final int matchNumber;
  final RoomPhase status;
  final int questionIndex;
  final int questionCount;
  final int answerSeconds;
  final bool speedBonusEnabled;
  final DateTime? countdownEndsAt;
  final DateTime? questionStartedAt;
  final DateTime? questionEndsAt;
  final DateTime? revealEndsAt;
  final DateTime? nextStartsAt;
  final DateTime? completedAt;

  factory MathMatchInfo.fromJson(Map<String, dynamic> json) {
    return MathMatchInfo(
      id: _string(json['id']),
      matchNumber: _int(json['match_number'], 1),
      status: RoomPhase.fromValue(_string(json['status'])),
      questionIndex: _int(json['question_index']),
      questionCount: _int(json['question_count'], 5),
      answerSeconds: _int(json['answer_seconds'], 18),
      speedBonusEnabled: _bool(json['speed_bonus_enabled'], true),
      countdownEndsAt: _optionalDate(json['countdown_ends_at']),
      questionStartedAt: _optionalDate(json['question_started_at']),
      questionEndsAt: _optionalDate(json['question_ends_at']),
      revealEndsAt: _optionalDate(json['reveal_ends_at']),
      nextStartsAt: _optionalDate(json['next_starts_at']),
      completedAt: _optionalDate(json['completed_at']),
    );
  }
}

class MathQuestionView {
  const MathQuestionView({
    required this.id,
    required this.position,
    required this.text,
    required this.options,
    required this.answerType,
    required this.topic,
    required this.skill,
    required this.difficulty,
    required this.estimatedSeconds,
    this.visual,
    this.correctAnswer,
    this.explanation,
  });

  final String id;
  final int position;
  final String text;
  final List<String> options;
  final AnswerType answerType;
  final MathTopic topic;
  final String skill;
  final MathDifficulty difficulty;
  final int estimatedSeconds;
  final Map<String, dynamic>? visual;
  final String? correctAnswer;
  final String? explanation;

  factory MathQuestionView.fromJson(Map<String, dynamic> json) {
    final visual = json['visual'];
    return MathQuestionView(
      id: _string(json['id']),
      position: _int(json['position']),
      text: _string(json['text']),
      options: _stringList(json['options']),
      answerType: AnswerType.fromValue(_string(json['answer_type'])),
      topic: MathTopic.fromValue(_string(json['topic'])),
      skill: _string(json['skill']),
      difficulty: MathDifficulty.fromValue(_string(json['difficulty'])),
      estimatedSeconds: _int(json['estimated_seconds'], 15),
      visual: visual is Map ? Map<String, dynamic>.from(visual) : null,
      correctAnswer: _optionalString(json['correct_answer']),
      explanation: _optionalString(json['explanation']),
    );
  }
}

class MathAnswerView {
  const MathAnswerView({
    required this.answer,
    required this.responseMs,
    this.isCorrect,
    this.points,
    this.speedBonus,
  });

  final String answer;
  final int responseMs;
  final bool? isCorrect;
  final int? points;
  final bool? speedBonus;

  factory MathAnswerView.fromJson(Map<String, dynamic> json) {
    return MathAnswerView(
      answer: _string(json['answer']),
      responseMs: _int(json['response_ms']),
      isCorrect: json['is_correct'] == null ? null : _bool(json['is_correct']),
      points: _optionalInt(json['points']),
      speedBonus:
          json['speed_bonus'] == null ? null : _bool(json['speed_bonus']),
    );
  }
}

class MathRevealPlayerResult {
  const MathRevealPlayerResult({
    required this.playerId,
    required this.displayName,
    required this.answer,
    required this.isCorrect,
    required this.points,
    required this.speedBonus,
    required this.submitted,
    this.responseMs,
  });

  final String playerId;
  final String displayName;
  final String? answer;
  final bool isCorrect;
  final int points;
  final bool speedBonus;
  final bool submitted;
  final int? responseMs;

  factory MathRevealPlayerResult.fromJson(Map<String, dynamic> json) {
    return MathRevealPlayerResult(
      playerId: _string(json['player_id']),
      displayName: _string(json['display_name'], 'Player'),
      answer: _optionalString(json['answer']),
      isCorrect: _bool(json['is_correct']),
      points: _int(json['points']),
      speedBonus: _bool(json['speed_bonus']),
      submitted: _bool(json['submitted']),
      responseMs: _optionalInt(json['response_ms']),
    );
  }
}

class MathReveal {
  const MathReveal({
    required this.correctAnswer,
    required this.explanation,
    required this.speedBonusWithheldForTie,
    required this.results,
    this.fastestPlayerId,
    this.fastestPlayerName,
  });

  final String correctAnswer;
  final String explanation;
  final bool speedBonusWithheldForTie;
  final List<MathRevealPlayerResult> results;
  final String? fastestPlayerId;
  final String? fastestPlayerName;

  factory MathReveal.fromJson(Map<String, dynamic> json) {
    return MathReveal(
      correctAnswer: _string(json['correct_answer']),
      explanation: _string(json['explanation']),
      speedBonusWithheldForTie:
          _bool(json['speed_bonus_withheld_for_tie']),
      results: _mapList(json['results'])
          .map(MathRevealPlayerResult.fromJson)
          .toList(growable: false),
      fastestPlayerId: _optionalString(json['fastest_player_id']),
      fastestPlayerName: _optionalString(json['fastest_player_name']),
    );
  }
}

class MathStanding {
  const MathStanding({
    required this.playerId,
    required this.displayName,
    required this.avatarIndex,
    required this.avatarColor,
    required this.points,
    required this.correctCount,
    required this.speedBonusCount,
    required this.rank,
    this.result,
    this.totalResponseMs,
    this.questionCount,
    this.newAchievements = const [],
  });

  final String playerId;
  final String displayName;
  final int avatarIndex;
  final String avatarColor;
  final int points;
  final int correctCount;
  final int speedBonusCount;
  final int rank;
  final MatchOutcome? result;
  final int? totalResponseMs;
  final int? questionCount;
  final List<String> newAchievements;

  factory MathStanding.fromJson(Map<String, dynamic> json) {
    return MathStanding(
      playerId: _string(json['player_id']),
      displayName: _string(json['display_name'], 'Player'),
      avatarIndex: _int(json['avatar_index']),
      avatarColor: _string(json['avatar_color'], '#00A2FF'),
      points: _int(json['points']),
      correctCount: _int(json['correct_count']),
      speedBonusCount: _int(json['speed_bonus_count']),
      rank: _int(json['rank'], 99),
      result: MatchOutcome.fromValue(_optionalString(json['result'])),
      totalResponseMs: _optionalInt(json['total_response_ms']),
      questionCount: _optionalInt(json['question_count']),
      newAchievements: _stringList(json['new_achievements']),
    );
  }
}

class MathReviewItem {
  const MathReviewItem({
    required this.position,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.topic,
    this.visual,
    this.myAnswer,
    this.myIsCorrect = false,
  });

  final int position;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final MathTopic topic;
  final Map<String, dynamic>? visual;
  final String? myAnswer;
  final bool myIsCorrect;

  factory MathReviewItem.fromJson(Map<String, dynamic> json) {
    final visual = json['visual'];
    return MathReviewItem(
      position: _int(json['position']),
      questionText: _string(json['question_text']),
      options: _stringList(json['options']),
      correctAnswer: _string(json['correct_answer']),
      explanation: _string(json['explanation']),
      topic: MathTopic.fromValue(_string(json['topic'])),
      visual: visual is Map ? Map<String, dynamic>.from(visual) : null,
      myAnswer: _optionalString(json['my_answer']),
      myIsCorrect: _bool(json['my_is_correct']),
    );
  }
}

class MathFinalResults {
  const MathFinalResults({required this.standings, required this.review});

  final List<MathStanding> standings;
  final List<MathReviewItem> review;

  factory MathFinalResults.fromJson(Map<String, dynamic> json) {
    return MathFinalResults(
      standings: _mapList(json['standings'])
          .map(MathStanding.fromJson)
          .toList(growable: false),
      review: _mapList(json['review'])
          .map(MathReviewItem.fromJson)
          .toList(growable: false),
    );
  }
}

class MathRoomState {
  const MathRoomState({
    required this.serverNow,
    required this.room,
    required this.players,
    required this.leaderboard,
    required this.myNewAchievements,
    this.match,
    this.question,
    this.myAnswer,
    this.reveal,
    this.finalResults,
  });

  final DateTime serverNow;
  final MathRoom room;
  final List<MathRoomPlayer> players;
  final List<MathStanding> leaderboard;
  final List<String> myNewAchievements;
  final MathMatchInfo? match;
  final MathQuestionView? question;
  final MathAnswerView? myAnswer;
  final MathReveal? reveal;
  final MathFinalResults? finalResults;

  /// Difference between the server clock and this device, used to draw
  /// countdowns that agree across clients. The server still enforces deadlines.
  Duration get serverOffset => serverNow.difference(DateTime.now().toUtc());

  DateTime serverTime() => DateTime.now().toUtc().add(serverOffset);

  Duration remainingUntil(DateTime? deadline) {
    if (deadline == null) return Duration.zero;
    final remaining = deadline.difference(serverTime());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory MathRoomState.fromJson(Map<String, dynamic> json) {
    final match = json['match'];
    final question = json['question'];
    final myAnswer = json['my_answer'];
    final reveal = json['reveal'];
    final finalResults = json['final_results'];
    return MathRoomState(
      serverNow: _date(json['server_now']),
      room: MathRoom.fromJson(_map(json['room'])),
      players: _mapList(json['players'])
          .map(MathRoomPlayer.fromJson)
          .toList(growable: false),
      leaderboard: _mapList(json['leaderboard'])
          .map(MathStanding.fromJson)
          .toList(growable: false),
      myNewAchievements: _stringList(json['my_new_achievements']),
      match: match is Map ? MathMatchInfo.fromJson(_map(match)) : null,
      question:
          question is Map ? MathQuestionView.fromJson(_map(question)) : null,
      myAnswer: myAnswer is Map ? MathAnswerView.fromJson(_map(myAnswer)) : null,
      reveal: reveal is Map ? MathReveal.fromJson(_map(reveal)) : null,
      finalResults: finalResults is Map
          ? MathFinalResults.fromJson(_map(finalResults))
          : null,
    );
  }
}

class MathAchievement {
  const MathAchievement({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.xp,
    this.unlockedAt,
  });

  final String code;
  final String title;
  final String description;
  final String icon;
  final int xp;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  factory MathAchievement.fromJson(Map<String, dynamic> json) {
    return MathAchievement(
      code: _string(json['code']),
      title: _string(json['title']),
      description: _string(json['description']),
      icon: _string(json['icon'], 'star'),
      xp: _int(json['xp']),
      unlockedAt: _optionalDate(json['unlocked_at']),
    );
  }
}

class MathSkillProgress {
  const MathSkillProgress({
    required this.grade,
    required this.topic,
    required this.skill,
    required this.attempts,
    required this.correct,
    required this.consecutiveCorrect,
    required this.mastery,
    required this.xp,
  });

  final GradeLevel grade;
  final MathTopic topic;
  final String skill;
  final int attempts;
  final int correct;
  final int consecutiveCorrect;
  final MasteryLevel mastery;
  final int xp;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  factory MathSkillProgress.fromJson(Map<String, dynamic> json) {
    return MathSkillProgress(
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
      topic: MathTopic.fromValue(_string(json['topic'])),
      skill: _string(json['skill']),
      attempts: _int(json['attempts']),
      correct: _int(json['correct']),
      consecutiveCorrect: _int(json['consecutive_correct']),
      mastery: MasteryLevel.fromValue(_string(json['mastery'])),
      xp: _int(json['xp']),
    );
  }
}

class MathMatchHistoryItem {
  const MathMatchHistoryItem({
    required this.matchId,
    required this.completedAt,
    required this.grade,
    required this.topics,
    required this.questionCount,
    required this.playerCount,
    required this.points,
    required this.correctCount,
    required this.speedBonusCount,
    required this.rank,
  });

  final String matchId;
  final DateTime completedAt;
  final GradeLevel grade;
  final List<MathTopic> topics;
  final int questionCount;
  final int playerCount;
  final int points;
  final int correctCount;
  final int speedBonusCount;
  final int rank;

  factory MathMatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return MathMatchHistoryItem(
      matchId: _string(json['match_id']),
      completedAt: _date(json['completed_at']),
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
      topics: _stringList(json['topics']).map(MathTopic.fromValue).toList(),
      questionCount: _int(json['question_count']),
      playerCount: _int(json['player_count']),
      points: _int(json['points']),
      correctCount: _int(json['correct_count']),
      speedBonusCount: _int(json['speed_bonus_count']),
      rank: _int(json['rank'], 99),
    );
  }
}

class MathProfile {
  const MathProfile({
    required this.id,
    required this.displayName,
    required this.avatarIndex,
    required this.avatarColor,
    required this.grade,
    required this.isMe,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    required this.totalPoints,
    required this.averagePoints,
    required this.bestMatchPoints,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unansweredCount,
    required this.accuracy,
    required this.averageResponseMs,
    required this.currentWinStreak,
    required this.bestWinStreak,
    required this.practiceQuestions,
    required this.practiceCorrect,
    required this.practiceStreak,
    required this.bestPracticeStreak,
    required this.achievements,
    required this.skills,
    required this.recentMatches,
    this.fastestCorrectMs,
    this.lastPracticeOn,
    this.leaderboardRank,
    this.leaderboardVisible,
    this.soundEnabled,
    this.reducedMotion,
  });

  final String id;
  final String displayName;
  final int avatarIndex;
  final String avatarColor;
  final GradeLevel grade;
  final bool isMe;
  final int level;
  final int xp;
  final int xpToNext;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final double winRate;
  final int totalPoints;
  final double averagePoints;
  final int bestMatchPoints;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unansweredCount;
  final double accuracy;
  final int averageResponseMs;
  final int? fastestCorrectMs;
  final int currentWinStreak;
  final int bestWinStreak;
  final int practiceQuestions;
  final int practiceCorrect;
  final int practiceStreak;
  final int bestPracticeStreak;
  final DateTime? lastPracticeOn;
  final int? leaderboardRank;
  final bool? leaderboardVisible;
  final bool? soundEnabled;
  final bool? reducedMotion;
  final List<MathAchievement> achievements;
  final List<MathSkillProgress> skills;
  final List<MathMatchHistoryItem> recentMatches;

  double get accuracyPercent => accuracy;
  double get xpProgress {
    if (xpToNext <= 0) return 1;
    return (xp % 250) / 250;
  }

  MathTopic? get recommendedTopic {
    if (skills.isEmpty) return null;
    final sorted = [...skills]..sort((a, b) {
        final mastery = a.mastery.order.compareTo(b.mastery.order);
        if (mastery != 0) return mastery;
        return a.accuracy.compareTo(b.accuracy);
      });
    return sorted.first.topic;
  }

  factory MathProfile.fromJson(Map<String, dynamic> json) {
    final settingsVisible = json['sound_enabled'] != null;
    return MathProfile(
      id: _string(json['id']),
      displayName: _string(json['display_name'], 'Player'),
      avatarIndex: _int(json['avatar_index']),
      avatarColor: _string(json['avatar_color'], '#00A2FF'),
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
      isMe: _bool(json['is_me']),
      level: _int(json['level'], 1),
      xp: _int(json['xp']),
      xpToNext: _int(json['xp_to_next'], 250),
      gamesPlayed: _int(json['games_played']),
      wins: _int(json['wins']),
      losses: _int(json['losses']),
      draws: _int(json['draws']),
      winRate: _double(json['win_rate']),
      totalPoints: _int(json['total_points']),
      averagePoints: _double(json['average_points']),
      bestMatchPoints: _int(json['best_match_points']),
      correctAnswers: _int(json['correct_answers']),
      incorrectAnswers: _int(json['incorrect_answers']),
      unansweredCount: _int(json['unanswered_count']),
      accuracy: _double(json['accuracy']),
      averageResponseMs: _int(json['average_response_ms']),
      fastestCorrectMs: _optionalInt(json['fastest_correct_ms']),
      currentWinStreak: _int(json['current_win_streak']),
      bestWinStreak: _int(json['best_win_streak']),
      practiceQuestions: _int(json['practice_questions']),
      practiceCorrect: _int(json['practice_correct']),
      practiceStreak: _int(json['practice_streak']),
      bestPracticeStreak: _int(json['best_practice_streak']),
      lastPracticeOn: _optionalDate(json['last_practice_on']),
      leaderboardRank: _optionalInt(json['leaderboard_rank']),
      leaderboardVisible:
          settingsVisible ? _bool(json['leaderboard_visible']) : null,
      soundEnabled: settingsVisible ? _bool(json['sound_enabled']) : null,
      reducedMotion: settingsVisible ? _bool(json['reduced_motion']) : null,
      achievements: _mapList(json['achievements'])
          .map(MathAchievement.fromJson)
          .toList(growable: false),
      skills: _mapList(json['skills'])
          .map(MathSkillProgress.fromJson)
          .toList(growable: false),
      recentMatches: _mapList(json['recent_matches'])
          .map(MathMatchHistoryItem.fromJson)
          .toList(growable: false),
    );
  }
}

class MathLeaderboardEntry {
  const MathLeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.displayName,
    required this.avatarIndex,
    required this.avatarColor,
    required this.grade,
    required this.points,
    required this.wins,
    required this.games,
    required this.accuracy,
    required this.speedBonuses,
    required this.isMe,
  });

  final int rank;
  final String playerId;
  final String displayName;
  final int avatarIndex;
  final String avatarColor;
  final GradeLevel grade;
  final int points;
  final int wins;
  final int games;
  final double accuracy;
  final int speedBonuses;
  final bool isMe;

  factory MathLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return MathLeaderboardEntry(
      rank: _int(json['rank']),
      playerId: _string(json['player_id']),
      displayName: _string(json['display_name'], 'Player'),
      avatarIndex: _int(json['avatar_index']),
      avatarColor: _string(json['avatar_color'], '#00A2FF'),
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
      points: _int(json['points']),
      wins: _int(json['wins']),
      games: _int(json['games']),
      accuracy: _double(json['accuracy']),
      speedBonuses: _int(json['speed_bonuses']),
      isMe: _bool(json['is_me']),
    );
  }
}

class MathPracticeQuestion {
  const MathPracticeQuestion({
    required this.id,
    required this.grade,
    required this.topic,
    required this.skill,
    required this.difficulty,
    required this.text,
    required this.options,
    required this.answerType,
    required this.estimatedSeconds,
    this.hint,
    this.visual,
  });

  final String id;
  final GradeLevel grade;
  final MathTopic topic;
  final String skill;
  final MathDifficulty difficulty;
  final String text;
  final List<String> options;
  final AnswerType answerType;
  final int estimatedSeconds;
  final String? hint;
  final Map<String, dynamic>? visual;

  factory MathPracticeQuestion.fromJson(Map<String, dynamic> json) {
    final visual = json['visual'];
    return MathPracticeQuestion(
      id: _string(json['id']),
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
      topic: MathTopic.fromValue(_string(json['topic'])),
      skill: _string(json['skill']),
      difficulty: MathDifficulty.fromValue(_string(json['difficulty'])),
      text: _string(json['text']),
      options: _stringList(json['options']),
      answerType: AnswerType.fromValue(_string(json['answer_type'])),
      estimatedSeconds: _int(json['estimated_seconds'], 15),
      hint: _optionalString(json['hint']),
      visual: visual is Map ? Map<String, dynamic>.from(visual) : null,
    );
  }
}

class MathPracticeResult {
  const MathPracticeResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.xpEarned,
    required this.mastery,
    required this.skillAttempts,
    required this.skillCorrect,
    required this.practiceStreak,
    required this.practiceQuestions,
    required this.newAchievements,
    this.hint,
  });

  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final int xpEarned;
  final MasteryLevel mastery;
  final int skillAttempts;
  final int skillCorrect;
  final int practiceStreak;
  final int practiceQuestions;
  final List<String> newAchievements;
  final String? hint;

  factory MathPracticeResult.fromJson(Map<String, dynamic> json) {
    return MathPracticeResult(
      isCorrect: _bool(json['is_correct']),
      correctAnswer: _string(json['correct_answer']),
      explanation: _string(json['explanation']),
      xpEarned: _int(json['xp_earned']),
      mastery: MasteryLevel.fromValue(_string(json['mastery'])),
      skillAttempts: _int(json['skill_attempts']),
      skillCorrect: _int(json['skill_correct']),
      practiceStreak: _int(json['practice_streak']),
      practiceQuestions: _int(json['practice_questions']),
      newAchievements: _stringList(json['new_achievements']),
      hint: _optionalString(json['hint']),
    );
  }
}

class MathActiveRoom {
  const MathActiveRoom({
    required this.roomId,
    required this.roomCode,
    required this.name,
    required this.status,
    required this.grade,
  });

  final String roomId;
  final String roomCode;
  final String name;
  final RoomPhase status;
  final GradeLevel grade;

  factory MathActiveRoom.fromJson(Map<String, dynamic> json) {
    return MathActiveRoom(
      roomId: _string(json['room_id']),
      roomCode: _string(json['room_code']),
      name: _string(json['name'], 'MathClash Room'),
      status: RoomPhase.fromValue(_string(json['status'])),
      grade: GradeLevel.fromValue(_optionalInt(json['grade'])),
    );
  }
}
