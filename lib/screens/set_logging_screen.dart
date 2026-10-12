import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'workout_summary_screen.dart';

/// Active workout screen: live set logging with previous values, rest timer, and PR detection.
class SetLoggingScreen extends StatelessWidget {
  const SetLoggingScreen({super.key, this.route});

  final RouteSettings? route;

  static String routeFor(String id) => '$routeName/$id';
  static const String routeName = '/set-logging';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _StatusBar(workout: workout),
                _SessionToolbar(workout: workout),
                _SessionProgress(workout: workout),
                _ExerciseWorkspace(workout: workout),
              ],
            ),
          ),
          _LoggingAction(workout: workout),
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

/// iOS-style status bar.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:41',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_4_bar_rounded,
                    size: 17,
                    color: scheme.onSurface,
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.wifi_rounded, size: 17, color: scheme.onSurface),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.battery_full_rounded,
                    size: 17,
                    color: scheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Session toolbar with exercise title, timer, and finish action.
class _SessionToolbar extends StatelessWidget {
  const _SessionToolbar({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        color: scheme.onSurface,
        child: Row(
          children: [
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: scheme.surface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppColors.lime),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '12:34',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Finish',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.lime),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin progress bar at the top of the exercise area.
class _SessionProgress extends StatelessWidget {
  const _SessionProgress({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Calculate overall progress
    final totalSets = workout.logs.fold<int>(
      0,
      (sum, log) => sum + log.sets.length,
    );
    final completedSets = workout.logs.fold<int>(
      0,
      (sum, log) => sum + log.sets.where((s) => s.completed).length,
    );
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    return SliverToBoxAdapter(
      child: Container(
        height: 3,
        color: scheme.outlineVariant,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(color: AppColors.lime),
        ),
      ),
    );
  }
}

/// Main exercise logging area.
class _ExerciseWorkspace extends StatelessWidget {
  const _ExerciseWorkspace({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final firstUnfinished = workout.logs.indexWhere(
      (log) => log.sets.any((s) => !s.completed),
    );
    final currentIndex = firstUnfinished >= 0 ? firstUnfinished : 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current exercise header
            _CurrentExerciseHeader(
              index: currentIndex,
              total: workout.logs.length,
              log: workout.logs[currentIndex],
            ),
            const SizedBox(height: 16),
            // Set log table
            _SetLog(
              log: workout.logs[currentIndex],
              workoutId: workout.id,
              logIndex: currentIndex,
            ),
            const SizedBox(height: 24),
            // Other exercises (collapsed)
            ...workout.logs
                .asMap()
                .entries
                .where((e) => e.key != currentIndex)
                .map((e) {
                  return _CollapsedExercise(index: e.key, log: e.value);
                }),
          ],
        ),
      ),
    );
  }
}

class _CurrentExerciseHeader extends StatelessWidget {
  const _CurrentExerciseHeader({
    required this.index,
    required this.total,
    required this.log,
  });

  final int index;
  final int total;
  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'EXERCISE ${(index + 1).toString().padLeft(2, '0')} / $total',
              style: text.labelCaps.copyWith(color: AppColors.lime),
            ),
            const Spacer(),
            Icon(
              Icons.more_vert_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(log.exercise.name.toUpperCase(), style: text.exerciseName),
        const SizedBox(height: 4),
        Text(
          '${log.setScheme}  /  2 reps in reserve',
          style: text.exerciseMeta,
        ),
        const SizedBox(height: 12),
        // Previous performance
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              log.previousBest ?? 'No previous data',
              style: text.previousPerf,
            ),
          ],
        ),
      ],
    );
  }
}

/// Set logging table with SET, PREVIOUS, KG, REPS columns.
class _SetLog extends StatelessWidget {
  const _SetLog({
    required this.log,
    required this.workoutId,
    required this.logIndex,
  });

  final ExerciseLog log;
  final String workoutId;
  final int logIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    if (log.sets.isEmpty) {
      return Text(
        'No sets defined.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: [
        // Column headings
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              col(text.setDim, 'SET', flex: 3),
              col(text.setDim, 'PREVIOUS', flex: 5),
              col(text.setDim, 'KG', flex: 3),
              col(text.setDim, 'REPS', flex: 3),
              const SizedBox(width: 34),
              const SizedBox(width: 30),
            ],
          ),
        ),
        // Set rows
        for (var i = 0; i < log.sets.length; i++) ...[
          Divider(color: scheme.outlineVariant, height: 1),
          _SetRow(
            log: log,
            workoutId: workoutId,
            logIndex: logIndex,
            setIndex: i,
          ),
        ],
      ],
    );
  }

  Widget col(TextStyle? style, String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: style, overflow: TextOverflow.ellipsis),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.log,
    required this.workoutId,
    required this.logIndex,
    required this.setIndex,
  });

  final ExerciseLog log;
  final String workoutId;
  final int logIndex;
  final int setIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final provider = context.read<WorkoutProvider>();
    final set = log.sets[setIndex];
    final canRemove = log.sets.length > 1;

    // Previous value for this set index
    final prev = log.previousSets.length > setIndex
        ? log.previousSets[setIndex]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          col(
            text.setDim,
            'SET ${(setIndex + 1).toString().padLeft(2, '0')}',
            flex: 3,
          ),
          col(
            prev != null ? text.setValue : text.setDim,
            prev != null
                ? '${prev.weightKg.toStringAsFixed(1)} × ${prev.reps}'
                : '—',
            flex: 5,
          ),
          col(
            set.completed ? text.setValue : text.setDim,
            set.completed ? set.weightKg.toStringAsFixed(1) : '—',
            flex: 3,
          ),
          col(
            set.completed ? text.setValue : text.setDim,
            set.completed ? '${set.reps}' : '—',
            flex: 3,
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: Checkbox(
              value: set.completed,
              onChanged: (_) {
                provider.toggleSet(workoutId, logIndex, setIndex);
                // TODO: Auto-start rest timer
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: set.completed ? AppColors.lime : scheme.outline,
                width: 2,
              ),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (set.completed) return AppColors.lime;
                return Colors.transparent;
              }),
              checkColor: scheme.onSurface,
            ),
          ),
          SizedBox(
            width: 30,
            height: 34,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              tooltip: 'Remove set',
              onPressed: canRemove
                  ? () => provider.removeSet(workoutId, logIndex, setIndex)
                  : null,
              icon: Icon(
                Icons.close_rounded,
                color: canRemove
                    ? scheme.onSurfaceVariant
                    : scheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget col(TextStyle? style, String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: style, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Collapsed exercise preview for non-current exercises.
class _CollapsedExercise extends StatelessWidget {
  const _CollapsedExercise({required this.index, required this.log});

  final int index;
  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final completed = log.sets.where((s) => s.completed).length;
    final total = log.sets.length;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed == total
                  ? AppColors.lime
                  : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: completed == total
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.exercise.name.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$completed / $total sets  ·  ${log.restSeconds}s rest',
                  style: text.previousPerf,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom logging action bar with "Add set" button.
class _LoggingAction extends StatelessWidget {
  const _LoggingAction({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstUnfinished = workout.logs.indexWhere(
      (log) => log.sets.any((s) => !s.completed),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<WorkoutProvider>().addSet(
                    workout.id,
                    firstUnfinished >= 0 ? firstUnfinished : 0,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Set'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: scheme.outline),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.control,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(WorkoutSummaryScreen.routeFor(workout.id));
                },
                icon: const Icon(Icons.flag_rounded, size: 18),
                label: const Text('Finish Workout'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.control,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
