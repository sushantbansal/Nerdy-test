import 'package:get/get.dart';

import '../../core/utils/ui_feedback.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import '../../services/session_service.dart';

class TopicProgress {
  const TopicProgress({
    required this.topic,
    required this.attempts,
    required this.correct,
    required this.mastery,
    required this.skills,
    required this.xp,
  });

  final MathTopic topic;
  final int attempts;
  final int correct;
  final MasteryLevel mastery;
  final List<MathSkillProgress> skills;
  final int xp;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  int get masteredSkills => skills
      .where(
        (skill) =>
            skill.mastery == MasteryLevel.mastered ||
            skill.mastery == MasteryLevel.proficient,
      )
      .length;
}

class ProgressController extends GetxController {
  ProgressController(this._session);

  final SessionService _session;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  MathProfile? get profile => _session.profile.value;

  List<TopicProgress> get topics {
    final skills = profile?.skills ?? const <MathSkillProgress>[];
    final grouped = <MathTopic, List<MathSkillProgress>>{};
    for (final skill in skills) {
      grouped.putIfAbsent(skill.topic, () => []).add(skill);
    }
    final result =
        grouped.entries.map((entry) {
          final attempts = entry.value.fold<int>(
            0,
            (sum, skill) => sum + skill.attempts,
          );
          final correct = entry.value.fold<int>(
            0,
            (sum, skill) => sum + skill.correct,
          );
          final xp = entry.value.fold<int>(0, (sum, skill) => sum + skill.xp);
          final mastery = entry.value
              .map((skill) => skill.mastery)
              .reduce((a, b) => a.order >= b.order ? a : b);
          return TopicProgress(
            topic: entry.key,
            attempts: attempts,
            correct: correct,
            mastery: mastery,
            skills: entry.value,
            xp: xp,
          );
        }).toList()..sort((a, b) {
          final mastery = b.mastery.order.compareTo(a.mastery.order);
          if (mastery != 0) return mastery;
          return b.attempts.compareTo(a.attempts);
        });
    return result;
  }

  TopicProgress? get focusTopic {
    final list = topics;
    if (list.isEmpty) return null;
    final sorted = [...list]
      ..sort((a, b) {
        final mastery = a.mastery.order.compareTo(b.mastery.order);
        if (mastery != 0) return mastery;
        return a.attempts.compareTo(b.attempts);
      });
    return sorted.first;
  }

  int get totalAttempts =>
      topics.fold<int>(0, (sum, topic) => sum + topic.attempts);

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    error.value = '';
    try {
      await _session.refreshProfile();
    } catch (exception) {
      error.value = UiFeedback.friendly(exception);
    } finally {
      isLoading.value = false;
    }
  }

  void practise(MathTopic topic) {
    Get.toNamed('/practice', arguments: {'topic': topic});
  }
}
