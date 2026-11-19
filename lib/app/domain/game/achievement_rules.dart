/// Server-side achievement rules, mirrored for deterministic unit tests.
class AchievementStats {
  const AchievementStats({
    required this.gamesPlayed,
    required this.perfectMatches,
    required this.speedBonuses,
    required this.practiceAnswers,
    required this.practiceTopics,
    required this.practiceDays,
    required this.masteredSkills,
    required this.bestWinStreak,
    required this.level,
    required this.bestMatchAccuracy,
  });

  final int gamesPlayed;
  final int perfectMatches;
  final int speedBonuses;
  final int practiceAnswers;
  final int practiceTopics;
  final int practiceDays;
  final int masteredSkills;
  final int bestWinStreak;
  final int level;
  final double bestMatchAccuracy;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.xp,
  });

  final String code;
  final String title;
  final String description;
  final String icon;
  final int xp;
}

class AchievementRules {
  AchievementRules._();

  static const List<AchievementDefinition> definitions = [
    AchievementDefinition(
      code: 'first_match',
      title: 'First Match',
      description: 'Finish your first multiplayer math match.',
      icon: 'rocket',
      xp: 20,
    ),
    AchievementDefinition(
      code: 'perfect_match',
      title: 'Perfect Match',
      description: 'Answer every question correctly in one match.',
      icon: 'star',
      xp: 50,
    ),
    AchievementDefinition(
      code: 'accuracy_star',
      title: 'Accuracy Star',
      description: 'Finish a match with at least 80% accuracy.',
      icon: 'target',
      xp: 30,
    ),
    AchievementDefinition(
      code: 'speed_champion',
      title: 'Speed Champion',
      description: 'Earn three legitimate speed bonuses.',
      icon: 'bolt',
      xp: 30,
    ),
    AchievementDefinition(
      code: 'math_explorer',
      title: 'Math Explorer',
      description: 'Practice three different math topics.',
      icon: 'compass',
      xp: 25,
    ),
    AchievementDefinition(
      code: 'consistent_learner',
      title: 'Consistent Learner',
      description: 'Practice on three different days.',
      icon: 'calendar',
      xp: 35,
    ),
    AchievementDefinition(
      code: 'skill_master',
      title: 'Skill Master',
      description: 'Reach Mastered level in any skill.',
      icon: 'crown',
      xp: 60,
    ),
    AchievementDefinition(
      code: 'five_streak',
      title: 'High Five Streak',
      description: 'Win five matches in a row.',
      icon: 'flame',
      xp: 50,
    ),
    AchievementDefinition(
      code: 'practice_10',
      title: 'Practice Pro',
      description: 'Answer ten practice questions.',
      icon: 'pencil',
      xp: 20,
    ),
    AchievementDefinition(
      code: 'level_5',
      title: 'Rising Star',
      description: 'Reach player level 5.',
      icon: 'sparkle',
      xp: 40,
    ),
  ];

  static Set<String> evaluate(AchievementStats stats) {
    final unlocked = <String>{};
    if (stats.gamesPlayed >= 1) unlocked.add('first_match');
    if (stats.perfectMatches >= 1) unlocked.add('perfect_match');
    if (stats.bestMatchAccuracy >= 0.8) unlocked.add('accuracy_star');
    if (stats.speedBonuses >= 3) unlocked.add('speed_champion');
    if (stats.practiceTopics >= 3) unlocked.add('math_explorer');
    if (stats.practiceDays >= 3) unlocked.add('consistent_learner');
    if (stats.masteredSkills >= 1) unlocked.add('skill_master');
    if (stats.bestWinStreak >= 5) unlocked.add('five_streak');
    if (stats.practiceAnswers >= 10) unlocked.add('practice_10');
    if (stats.level >= 5) unlocked.add('level_5');
    return unlocked;
  }

  static AchievementDefinition? definitionFor(String code) {
    for (final definition in definitions) {
      if (definition.code == code) return definition;
    }
    return null;
  }
}
