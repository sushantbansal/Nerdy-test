import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/math_api_models.dart';
import '../../domain/models/math_models.dart';
import 'progress_controller.dart';

class ProgressView extends GetView<ProgressController> {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Learning progress',
      subtitle: 'Mastery grows with every honest attempt.',
      background: CandyBackgroundStyle.mint,
      child: Obx(() {
        final profile = controller.profile;
        if (profile == null) {
          if (controller.isLoading.value) {
            return const LoadingView(message: 'Loading your learning map…');
          }
          return Padding(
            padding: const EdgeInsets.only(top: 30),
            child: ErrorState(
              message: controller.error.value.isEmpty
                  ? 'Your progress could not be loaded.'
                  : controller.error.value,
              onRetry: controller.refresh,
            ),
          );
        }

        final topics = controller.topics;
        final focus = controller.focusTopic;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OverallCard(profile: profile, topics: topics),
            if (focus != null) ...[
              const SizedBox(height: 16),
              _FocusCard(topic: focus),
            ],
            const SizedBox(height: 22),
            const SectionHeader(
              eyebrow: 'Skill map',
              title: 'Mastery by topic',
              emoji: '🧠',
              subtitle: 'Answer a few questions to grow each bar.',
            ),
            if (topics.isEmpty)
              const EmptyState(
                emoji: '🌱',
                title: 'Nothing tracked yet',
                message: 'Practice or play a match to start your mastery map.',
                compact: true,
              )
            else
              Column(
                children: [
                  for (final topic in topics) ...[
                    _TopicCard(topic: topic),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            _Legend(),
            const SizedBox(height: 14),
            Text(
              'Mastery uses rolling recent answers, so an early wobble does not '
              'follow you forever. Mistakes are part of learning.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      }),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.profile, required this.topics});

  final MathProfile profile;
  final List<TopicProgress> topics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mastered = topics
        .where((topic) => topic.mastery == MasteryLevel.mastered)
        .length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B276), Color(0xFF00795B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.mintDark.withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 40, height: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.grade.label} maths journey',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Level ${profile.level} · ${profile.xp} XP',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _BigStat(value: '${profile.correctAnswers}', label: 'correct'),
              _BigStat(
                value: '${profile.accuracy.round()}%',
                label: 'accuracy',
              ),
              _BigStat(value: '$mastered', label: 'mastered topics'),
              _BigStat(
                value: '${profile.practiceQuestions}',
                label: 'practice Qs',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.topic});

  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final color = topicColor(topic.topic);
    final theme = Theme.of(context);
    return CandyCard(
      color: AppColors.yellowSoft,
      borderColor: AppColors.yellow,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                color.withValues(alpha: 0.15),
                AppColors.surface,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              topic.topic.symbol,
              style: TextStyle(
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next best focus',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.yellowDark,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(topic.topic.label, style: theme.textTheme.titleMedium),
                Text(
                  '${topic.attempts} attempts · ${(topic.accuracy * 100).round()}% accuracy',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          ArcadeButton(
            label: 'Practise',
            size: ArcadeButtonSize.small,
            icon: Icons.play_arrow_rounded,
            onPressed: () =>
                Get.find<ProgressController>().practise(topic.topic),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final TopicProgress topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = topicColor(topic.topic);
    return CandyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    color.withValues(alpha: 0.14),
                    AppColors.surface,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  topic.topic.symbol,
                  style: TextStyle(
                    fontSize: 19,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.topic.label, style: theme.textTheme.titleMedium),
                    Text(
                      '${topic.correct}/${topic.attempts} correct · '
                      '${topic.masteredSkills}/${topic.skills.length} skills strong',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              MasteryPill(mastery: topic.mastery, compact: true),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: topic.accuracy,
              minHeight: 10,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final skill in topic.skills.take(4))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${skill.skill.replaceAll('_', ' ')} · '
                    '${skill.mastery.label}',
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CandyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How mastery works',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mastery in MasteryLevel.values)
                MasteryPill(mastery: mastery, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Not started → Learning → Practising → Proficient → Mastered. '
            'Recent correct answers move you up; a slip may move you down a step.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
