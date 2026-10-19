import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/session_stats.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Post-workout summary: what the session added up to, counted from the sets
/// the user actually ticked.
///
/// Nothing here is stated in advance. The date is the session's own, the
/// duration is what the plan recorded, and a personal record is only claimed
/// when this session's best set beats the best set for the same exercise in an
/// earlier finished session - both of which are in the log, so the claim can be
/// checked against it.
class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({super.key, this.route});

  final RouteSettings? route;

  static String routeFor(String id) => '$routeName/$id';
  static const String routeName = '/workout-summary';

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final id = switch (arguments) {
      String value => value,
      Workout value => value.id,
      _ => _idFromPath(route?.name),
    };

    final provider = context.watch<WorkoutProvider>();
    final workout = id == null ? null : provider.byId(id);

    if (workout == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                'Session not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'It may have been removed from your calendar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = SessionStats(provider.workouts, today: provider.today);
    final topSet = stats.topSetIn(workout);
    final previous = topSet == null
        ? null
        : stats.previousBestOf(topSet.exercise, before: workout.date);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Top inset only — the OS draws the phone's status bar, not the app.
          SliverToBoxAdapter(
            child: SafeArea(bottom: false, child: SizedBox(height: 8)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pageHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompletionHeadline(workout: workout),
                  const SizedBox(height: 24),
                  _PerformanceMetrics(workout: workout, stats: stats),
                  const SizedBox(height: 24),
                  if (topSet != null &&
                      previous != null &&
                      topSet.estimatedOneRepMax > previous.estimatedOneRepMax)
                    _PersonalRecordCard(record: topSet, previous: previous),
                  const SizedBox(height: 24),
                  _SaveSummaryButton(workout: workout),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _idFromPath(String? routeName) {
    if (routeName == null) return null;
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return Uri.decodeComponent(segments[1]);
  }
}

/// Completion headline with the session's own date.
class _CompletionHeadline extends StatelessWidget {
  const _CompletionHeadline({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateFormat('EEE, MMM d').format(workout.date).toUpperCase()} / '
          '${workout.title}',
          style: text.labelCaps.copyWith(color: AppColors.lime),
        ),
        const SizedBox(height: 8),
        Text('WORK.\nBANKED.', style: text.dataHero),
        const SizedBox(height: 8),
        Text('You showed up. You got stronger.', style: text.exerciseMeta),
      ],
    );
  }
}

/// Performance metrics: total volume with the change against the last session,
/// divider, session totals.
class _PerformanceMetrics extends StatelessWidget {
  const _PerformanceMetrics({required this.workout, required this.stats});

  final Workout workout;
  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    final totalVolume = workout.logs.fold<double>(
      0,
      (sum, log) => sum + log.volume,
    );
    final previous = stats.lastVolumeOf(workout.title, before: workout.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Volume total
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL VOLUME', style: text.labelCaps),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        totalVolume.toStringAsFixed(0),
                        style: text.dataLarge,
                      ),
                      const SizedBox(width: 8),
                      Text('kg', style: text.exerciseMeta),
                    ],
                  ),
                ],
              ),
            ),
            // Only printed when there is a session to compare with; the first
            // time a title is used there is no baseline to report against.
            if (previous != null && previous > 0 && totalVolume > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalVolume >= previous ? '+' : ''}'
                    '${((totalVolume - previous) / previous * 100).round()}%',
                    style: text.dataChange.copyWith(
                      color: totalVolume >= previous
                          ? AppColors.lime
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text('vs. last session', style: text.annotation),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: AppColors.inkSubtle, height: 1, thickness: 1),
        const SizedBox(height: 16),
        // Session totals
        Row(
          children: [
            _MetricChip(
              label: 'DURATION',
              value: workout.durationMin > 0
                  ? '${workout.durationMin} min'
                  : '—',
            ),
            const SizedBox(width: 12),
            _MetricChip(label: 'SETS', value: '${workout.totalSets}'),
            const SizedBox(width: 12),
            _MetricChip(label: 'REPS', value: '${workout.totalReps}'),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelCaps),
          const SizedBox(height: 4),
          Text(value, style: text.metric),
        ],
      ),
    );
  }
}

/// Personal record card (lime background).
///
/// Only drawn when the session's best set actually beat the previous best for
/// the same exercise, and it names both numbers, so the claim is checkable
/// against the log rather than asserted.
class _PersonalRecordCard extends StatelessWidget {
  const _PersonalRecordCard({required this.record, required this.previous});

  final SetRecord record;
  final SetRecord previous;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEW PERSONAL RECORD',
                style: text.labelCaps.copyWith(color: scheme.onSurface),
              ),
              const Spacer(),
              Icon(
                Icons.emoji_events_rounded,
                size: 24,
                color: scheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.exercise.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          record.weightKg.toStringAsFixed(
                            record.weightKg == record.weightKg.roundToDouble()
                                ? 0
                                : 1,
                          ),
                          style: text.dataLarge.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'kg × ${record.reps}',
                          style: text.exerciseMeta.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    previous.label,
                    style: text.dataChange.copyWith(color: scheme.onSurface),
                  ),
                  Text(
                    'previous best · '
                    '${DateFormat('MMM d').format(previous.date)}',
                    style: text.annotation.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Save summary CTA.
class _SaveSummaryButton extends StatelessWidget {
  const _SaveSummaryButton({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: () {
          context.read<WorkoutProvider>().completeWorkout(workout.id);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        icon: const Icon(Icons.check_rounded, size: 20),
        label: const Text('Save Summary'),
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
    );
  }
}
