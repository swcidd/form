import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/session_stats.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/one_rep_max_card.dart';
import '../widgets/section_header.dart';

/// What the logged sessions add up to.
///
/// Every figure is counted from the workouts in [WorkoutProvider] by
/// [SessionStats], so the screen cannot claim a lift that is not in the log.
/// A comparison is only printed when there is something to compare against;
/// an account with no finished sessions gets an empty state rather than a
/// scoreboard of zeros.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const String routeName = '/progress';

  /// How far back the headline numbers look, and how many records the list
  /// shows before it stops being a summary.
  static const int windowDays = 30;
  static const int recordCount = 3;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final stats = SessionStats(provider.workouts, today: provider.today);
    final records = stats.records;
    final trends = stats.oneRepMaxTrends;

    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Text('Progress', style: context.text.dataHero),
          const SizedBox(height: 24),
          if (stats.isEmpty)
            const EmptyState(
              icon: Icons.insights_rounded,
              title: 'No progress to show yet',
              message:
                  'Finish a session and the work you logged starts adding up '
                  'here.',
            )
          else ...[
            if (trends.isNotEmpty)
              OneRepMaxCard(trends: trends)
            else
              _ProgressCard(
                title: 'Estimated 1RM',
                subtitle: 'No weighted sets yet',
                value: '—',
              ),
            const SizedBox(height: 16),
            _volumeCard(stats),
            const SizedBox(height: 16),
            _ProgressCard(
              title: 'Frequency',
              subtitle: 'Sessions per week',
              value: stats.sessionsPerWeek.toStringAsFixed(1),
              trend: 'Target: ${provider.weeklyGoal}',
            ),
            const SizedBox(height: 28),
            const SectionHeader(label: 'Personal records'),
            const SizedBox(height: 12),
            if (records.isEmpty)
              _Note(
                text:
                    'Nothing to rank yet. Records are the heaviest set you '
                    'have logged for each exercise, and bodyweight work is '
                    'not counted.',
              )
            else
              ...records
                  .take(recordCount)
                  .map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordCard(record: record),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  /// Volume for the window, with the change against the window before it.
  ///
  /// The change is left off when there is no earlier window to compare with,
  /// rather than shown as "+100%" or a made-up baseline.
  Widget _volumeCard(SessionStats stats) {
    final change = stats.volumeChangeIn(windowDays);

    return _ProgressCard(
      title: 'Volume ($windowDays days)',
      subtitle: 'Total lifted',
      value: '${NumberFormat('#,##0').format(stats.volumeIn(windowDays))} kg',
      trend: change == null
          ? null
          : '${change >= 0 ? '+' : ''}${change.round()}%',
      trendPositive: change != null && change >= 0,
    );
  }
}

/// One headline number with an optional comparison.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.value,
    this.trend,
    this.trendPositive = false,
  });

  final String title;
  final String subtitle;
  final String value;

  /// The comparison, when the data supports one. Null draws nothing rather
  /// than an empty slot.
  final String? trend;
  final bool trendPositive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final comparison = trend;

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
                Text(
                  subtitle,
                  style: text.exerciseMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(value, style: text.dataLarge),
              ],
            ),
          ),
          if (comparison != null)
            Text(
              comparison,
              style: text.dataChange.copyWith(
                color: trendPositive ? Colors.green : scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// One personal record, with the day it was set.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final SetRecord record;

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
                Text(
                  record.exercise,
                  style: text.exerciseName.copyWith(fontSize: 20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(record.label, style: text.metric),
              ],
            ),
          ),
          Text(DateFormat('MMM d').format(record.date), style: text.annotation),
        ],
      ),
    );
  }
}

/// A plain line where a list has nothing to show, sized to sit inside a
/// scrolling column of real sections.
class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(text, style: context.text.annotation.copyWith(height: 1.5)),
    );
  }
}
