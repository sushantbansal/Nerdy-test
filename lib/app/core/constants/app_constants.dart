class AppConstants {
  AppConstants._();

  static const String appName = 'MathClash';
  static const String tagline = 'Play smart. Clash kindly.';
  static const String appVersion = '2.0.0';

  // Match defaults and safe limits (mirrored by the database).
  static const int defaultQuestionCount = 5;
  static const int minQuestionCount = 3;
  static const int maxQuestionCount = 8;

  static const int defaultAnswerSeconds = 18;
  static const int kindergartenAnswerSeconds = 30;
  static const int kindergartenMinAnswerSeconds = 20;
  static const int minAnswerSeconds = 10;
  static const int maxAnswerSeconds = 45;

  static const int defaultMaxPlayers = 4;
  static const int minPlayers = 2;
  static const int maxPlayers = 8;

  static const int minGrade = 0;
  static const int maxGrade = 5;

  static const int xpPerLevel = 250;

  // Child-friendly avatar options. Names are never uploaded as images.
  static const List<String> avatarEmojis = [
    '🦊',
    '🐼',
    '🐯',
    '🐸',
    '🐙',
    '🦄',
    '🐵',
    '🐶',
    '🐱',
    '🐰',
    '🦁',
    '🐨',
  ];

  static const List<String> avatarColors = [
    '#00A2FF',
    '#FF3D8B',
    '#00B276',
    '#8C45FF',
    '#FFCA00',
    '#FF7A00',
    '#00C2C7',
    '#F05A5A',
    '#5B7CFA',
    '#B05CFF',
    '#2BB673',
    '#FF9F1C',
  ];

  static const List<String> roomNameAdjectives = [
    'Sunny',
    'Super',
    'Turbo',
    'Cosmic',
    'Bubbly',
    'Brainy',
    'Speedy',
    'Happy',
  ];

  static const List<String> roomNameNouns = [
    'Arena',
    'Squad',
    'Clash',
    'Rockets',
    'Stars',
    'Comets',
    'Tigers',
    'Comets',
  ];
}
