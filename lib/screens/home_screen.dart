import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/progress_bar.dart';
import '../widgets/section_header.dart';
import '../navigation/app_tab.dart';
import '../widgets/stat_tile.dart';
import '../widgets/workout_card.dart';
import 'workout_detail_screen.dart';

/// The dashboard: what to train now, how the week is going, and what was
/// logged recently.
///
/// Ordered by what a lifter needs in priority. The session of the day is the
/// single most useful thing on the screen, so it leads and gets the largest
/// target. Everything below it is either a summary of past work or a way to
/// reach a screen that has more room for the detail.
///
/// Every figure is derived from [WorkoutProvider] rather than held here, so
/// ticking a set on the detail screen moves this screen the moment the user
/// comes back — there is no second copy of "progress" to fall out of sync.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onSelectTab});

  /// Switches the shell to another tab. Passed in rather than reached for
  /// through an InheritedWidget so the dashboard still renders standalone, on
  /// its own route or in a test, without a shell above it.
  final ValueChanged<AppTab>? onSelectTab;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final focus = provider.focusWorkout;

    return Scaffold(
      appBar: BrandAppBar(onAvatar: () => onSelectTab?.call(AppTab.profile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            DateFormat('EEEE, MMM d').format(provider.today).toUpperCase(),
            style: context.text.labelCaps,
          ),
          const SizedBox(height: 16),
          _FocusCard(workout: focus),
          const SizedBox(height: 24),
          const SectionHeader(label: 'This week'),
          const SizedBox(height: 10),
          _WeekRow(provider: provider),
          const SizedBox(height: 24),
          const SectionHeader(label: 'Recent sessions'),
          const SizedBox(height: 10),
          ..._recent(provider).map(
            (workout) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WorkoutCard(
                workout: workout,
                dense: true,
                onTap: () =>
                    Navigator.of(context)
                        .pushNamed(WorkoutDetailScreen.routeFor(workout.id)),
              ),
            ),
          ),
          if (_recent(provider).isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No finished sessions yet',
              message: 'Complete a workout and it will show up here.',
            ),
        ],
      ),
    );
  }

  /// The three most recent completed sessions, newest first.
  ///
  /// Filtered to completed rather than merely finished-dates so a planned
  /// session does not appear in a list labelled "recent sessions" before it
  /// has happened.
  static List<Workout> _recent(WorkoutProvider provider) {
    final finished =
        provider.workouts
            .where((w) => w.status == WorkoutStatus.completed)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return finished.take(3).toList();
  }
}

/// The session of the day, or the prompt to start one.
///
/// A single card rather than a list because there is one correct answer to
/// "what am I doing now". The button label changes with the workout's state
/// (start / resume / view) instead of reading "Continue" on a session with
/// nothing logged, which would send the user somewhere with nothing to do.
class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.workout});

  final Workout? workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final session = workout;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session == null ? 'NO SESSION SCHEDULED' : 'UP NEXT',
            style: context.text.labelCaps.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            session?.title ?? 'Rest day',
            style: textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (session != null) ...[
            const SizedBox(height: 6),
            Text(
              [
                session.startTime,
                session.place,
              ].where((part) => part.isNotEmpty).join(' · '),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${session.completedSets}/${session.totalSets} SETS',
                  style: context.text.labelCaps.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(session.progress * 100).round()}%',
                  style: context.text.labelCaps.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressBar(
              value: session.progress,
              height: 6,
              color: scheme.primary,
              trackColor: scheme.onPrimaryContainer.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(WorkoutDetailScreen.routeFor(session.id)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  session.completedSets > 0 && !session.isDone
                      ? 'Resume workout'
                      : session.isDone
                      ? 'View summary'
                      : 'Start workout',
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Nothing on the plan today. Pick a session from the calendar '
                'when you are ready to train.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Two figures for the current week: sessions against the goal, and the streak.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.provider});

  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              value: '${provider.workoutsThisWeek}/${provider.weeklyGoal}',
              label: 'Sessions',
              icon: Icons.event_available_outlined,
              caption: 'This week',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              value: '${provider.streakDays}',
              label: 'Day streak',
              icon: Icons.local_fire_department_outlined,
              caption: 'Consecutive days',
            ),
          ),
        ],
      ),
    );
  }
}
