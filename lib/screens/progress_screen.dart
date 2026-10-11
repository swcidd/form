import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../widgets/brand_app_bar.dart';

/// Progress screen placeholder - shows strength progress, personal records and volume trends.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const String routeName = '/progress';

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Progress', style: text.dataHero),
          const SizedBox(height: 24),
          _ProgressCard(
            title: 'Estimated 1RM',
            subtitle: 'Bench Press',
            value: '102.5 kg',
            trend: '+5%',
            trendPositive: true,
          ),
          const SizedBox(height: 16),
          _ProgressCard(
            title: 'Volume (30 days)',
            subtitle: 'Total lifted',
            value: '48,200 kg',
            trend: '+12%',
            trendPositive: true,
          ),
          const SizedBox(height: 16),
          _ProgressCard(
            title: 'Frequency',
            subtitle: 'Sessions per week',
            value: '3.8',
            trend: 'Target: 4',
            trendPositive: false,
          ),
          const SizedBox(height: 24),
          Text('Personal Records', style: text.labelCaps),
          const SizedBox(height: 12),
          _PRCard(
            exercise: 'Bench Press',
            value: '100 kg × 1',
            date: 'Oct 5, 2024',
          ),
          const SizedBox(height: 12),
          _PRCard(exercise: 'Squat', value: '140 kg × 1', date: 'Sep 28, 2024'),
          const SizedBox(height: 12),
          _PRCard(
            exercise: 'Deadlift',
            value: '160 kg × 1',
            date: 'Oct 12, 2024',
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.trend,
    required this.trendPositive,
  });

  final String title;
  final String subtitle;
  final String value;
  final String trend;
  final bool trendPositive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.labelCaps),
                const SizedBox(height: 4),
                Text(subtitle, style: text.exerciseMeta),
                const SizedBox(height: 12),
                Text(value, style: text.dataLarge),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trend,
                style: text.dataChange.copyWith(
                  color: trendPositive ? Colors.green : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: trendPositive
                      ? Colors.green.withValues(alpha: 0.2)
                      : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      color: trendPositive
                          ? Colors.green
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PRCard extends StatelessWidget {
  const _PRCard({
    required this.exercise,
    required this.value,
    required this.date,
  });

  final String exercise;
  final String value;
  final String date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise, style: text.exerciseName.copyWith(fontSize: 20)),
                Text(value, style: text.metric),
              ],
            ),
          ),
          Text(date, style: text.annotation),
        ],
      ),
    );
  }
}
