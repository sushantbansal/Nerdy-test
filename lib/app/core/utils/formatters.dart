import '../../domain/models/math_models.dart';

class Formatters {
  Formatters._();

  static String seconds(int value) => '${value}s';

  static String responseTime(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) return '—';
    if (milliseconds < 1000) return '${milliseconds}ms';
    return '${(milliseconds / 1000).toStringAsFixed(1)}s';
  }

  static String averageResponse(int milliseconds) {
    if (milliseconds <= 0) return '—';
    return '${(milliseconds / 1000).toStringAsFixed(1)}s';
  }

  static String percent(double value) {
    if (value == value.roundToDouble()) return '${value.round()}%';
    return '${value.toStringAsFixed(1)}%';
  }

  static String points(num value) {
    if (value == value.roundToDouble()) return '${value.round()}';
    return value.toStringAsFixed(1);
  }

  static String countdown(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0) return '0';
    if (seconds < 10) return seconds.toStringAsFixed(1);
    return seconds.ceil().toString();
  }

  static String countdownSeconds(Duration duration) {
    final seconds = duration.inSeconds;
    return seconds <= 0 ? '0' : '$seconds';
  }

  static String grade(GradeLevel grade) => grade.label;

  static String topic(MathTopic topic) => topic.label;

  static String topics(List<MathTopic> topics) {
    if (topics.isEmpty) return 'Mixed';
    if (topics.length <= 2) {
      return topics.map((topic) => topic.label).join(' + ');
    }
    return '${topics.first.label} +${topics.length - 1}';
  }

  static String difficulty(MathDifficulty difficulty) => difficulty.label;

  static String relativeDate(DateTime date) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(date.toUtc());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  static String matchResult(MatchOutcome? outcome) {
    return switch (outcome) {
      MatchOutcome.win => 'Win',
      MatchOutcome.loss => 'Loss',
      MatchOutcome.draw => 'Draw',
      null => 'Played',
    };
  }

  static String mastery(MasteryLevel mastery) => mastery.label;

  static String ordinal(int rank) {
    if (rank <= 0) return '—';
    final suffix = switch (rank % 100) {
      11 || 12 || 13 => 'th',
      _ => switch (rank % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        },
    };
    return '$rank$suffix';
  }

  static String roomCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
