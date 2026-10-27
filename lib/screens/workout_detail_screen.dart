import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import 'set_logging_screen.dart';

/// Pre-workout screen: what the session is, and the button that starts it.
///
/// The layout follows the Figma "Train · Lower body detail" frame: a compact
/// toolbar, a photographic title band, the focus the plan was built around,
/// the exercise line-up with its rest notes, and one full-width action.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, this.route});

  final RouteSettings? route;

  static String routeFor(String id) => '$routeName/$id';
  static const String routeName = '/workout-detail';

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

    if (workout == null) return const _NotFound();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: _Toolbar(workout: workout),
                  ),
                ),
                SliverToBoxAdapter(child: _Hero(workout: workout)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (workout.targetMuscleGroups.isNotEmpty ||
                            workout.equipment.isNotEmpty) ...[
                          _Focus(workout: workout),
                          const SizedBox(height: 8),
                        ],
                        _LineupHeading(count: workout.logs.length),
                        if (workout.logs.isEmpty)
                          const _NoExercises()
                        else
                          _Lineup(logs: workout.logs),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _StartWorkoutButton(workout: workout),
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

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
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
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const Spacer(),
            Text(
              workout.date.day.toString().padLeft(2, '0'),
              style: text.annotation.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Icon(Icons.more_horiz_rounded, size: 22, color: scheme.onSurface),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final focus = [
      if (workout.modality != null) workout.modality!.label.toUpperCase(),
      if (workout.split != null) workout.split!.label.toUpperCase(),
    ].join(' / ');
    final meta = [
      if (workout.durationMin > 0) '${workout.durationMin} min',
      '${workout.logs.length} '
          '${workout.logs.length == 1 ? 'exercise' : 'exercises'}',
      '${workout.totalSets} sets',
    ].join('  /  ');

    return SizedBox(
      height: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/workout_hero.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xE8121512), Color(0x21121512)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  focus.isEmpty
                      ? workout.targetMuscleGroups
                            .take(2)
                            .join(' / ')
                            .toUpperCase()
                      : focus,
                  style: text.labelCaps.copyWith(
                    fontSize: 10,
                    color: const Color(0xFFD5FC61),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  workout.title.toUpperCase(),
                  style: text.dataHero.copyWith(
                    fontSize: 44,
                    height: 0.98,
                    color: const Color(0xFFF2F1E9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  style: text.annotation.copyWith(
                    fontSize: 12,
                    color: const Color(0xFFF2F1E9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Focus extends StatelessWidget {
  const _Focus({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final values = [...workout.targetMuscleGroups, ...workout.equipment];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S FOCUS",
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 5),
        Text(
          values.join('  ·  '),
          style: text.exerciseMeta.copyWith(
            fontSize: 13,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LineupHeading extends StatelessWidget {
  const _LineupHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            'THE LINEUP',
            style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            '$count ${count == 1 ? 'exercise' : 'exercises'}',
            style: text.annotation.copyWith(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Lineup extends StatelessWidget {
  const _Lineup({required this.logs});

  final List<ExerciseLog> logs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < logs.length; index++)
          _ExerciseRow(index: index, log: logs[index]),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.index, required this.log});

  final int index;
  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: text.dataMetric.copyWith(
                fontSize: 23,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.exercise.name,
                  style: text.exerciseMeta.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.sets.length} sets × ${log.setScheme}'
                  '${log.heaviestWeight == '0' ? '' : '  ·  ${log.heaviestWeight} kg'}',
                  style: text.annotation.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              '${log.restSeconds}s rest',
              textAlign: TextAlign.end,
              style: text.annotation.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _NoExercises extends StatelessWidget {
  const _NoExercises();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        'This session has no exercises yet. Add one on the logging screen '
        'when you start training.',
        style: context.text.annotation.copyWith(
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(SetLoggingScreen.routeFor(workout.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start workout',
                  style: text.labelCaps.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimary,
                  ),
                ),
                Icon(
                  Icons.play_arrow_rounded,
                  size: 22,
                  color: scheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
