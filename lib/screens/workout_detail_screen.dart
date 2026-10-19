import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'set_logging_screen.dart';

/// Pre-workout screen: what the session is, and the button that starts it.
///
/// Reachable from the dashboard through the named `/workout-detail` route,
/// which carries the workout id. The session comes from the provider by that
/// id, so the screen shows the user's own plan; an id that is not in the store
/// gets a not-found state rather than a made-up session.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, this.route});

  /// The route the shell pushes. Accepting the [RouteSettings] lets the screen
  /// read the id out of a `/workout-detail/:id` path as well as a route argument.
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
      body: CustomScrollView(
        slivers: [
          _HeroSliver(workout: workout),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pageHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workout.targetMuscleGroups.isNotEmpty ||
                      workout.equipment.isNotEmpty) ...[
                    _TrainingIntent(workout: workout),
                    const SizedBox(height: 24),
                  ],
                  if (workout.logs.isEmpty)
                    const _NoExercises()
                  else
                    _ExerciseList(workout: workout),
                  const SizedBox(height: 24),
                  _StartWorkoutButton(workout: workout),
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

/// Shown when the id in the route is not in the store - a session that was
/// deleted on another screen, or a link to one that never existed.
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

/// Hero section with photograph, scrim, category badge, and title.
class _HeroSliver extends StatelessWidget {
  const _HeroSliver({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: false,
      stretch: true,
      backgroundColor: scheme.onSurface,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero photograph
            Image.asset(
              'assets/images/workout_hero.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: scheme.surfaceContainerHighest),
            ),
            // Scrim gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF121512), // ink
                    Color(0x00121512), // transparent
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Category badge (lime), from the session's own focus.
                    if (workout.targetMuscleGroups.isNotEmpty)
                      Text(
                        workout.targetMuscleGroups
                            .take(2)
                            .join(' / ')
                            .toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.lime,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    const SizedBox(height: 8),
                    // Workout title (Barlow Condensed Bold 48)
                    Text(workout.title, style: text.dataHero),
                    const SizedBox(height: 4),
                    // Meta line, counted off the session rather than stated.
                    Text(
                      [
                        if (workout.durationMin > 0)
                          '${workout.durationMin} min',
                        if (workout.logs.isNotEmpty)
                          '${workout.logs.length} '
                              '${workout.logs.length == 1 ? 'exercise' : 'exercises'}',
                        if (workout.totalSets > 0) '${workout.totalSets} sets',
                      ].join('  ·  '),
                      style: text.exerciseMeta,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the session is for: the muscle groups it targets and the equipment it
/// needs, both taken from the plan itself.
///
/// Replaces a paragraph of invented coaching copy, which told every user to
/// leave two reps in reserve on every session regardless of what they had
/// planned or what they had logged before.
class _TrainingIntent extends StatelessWidget {
  const _TrainingIntent({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("TODAY'S FOCUS", style: text.labelCaps),
        const SizedBox(height: 10),
        if (workout.targetMuscleGroups.isNotEmpty)
          _Chips(
            values: workout.targetMuscleGroups,
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
          ),
        if (workout.targetMuscleGroups.isNotEmpty &&
            workout.equipment.isNotEmpty)
          const SizedBox(height: 8),
        if (workout.equipment.isNotEmpty)
          _Chips(
            values: workout.equipment,
            background: scheme.surfaceContainerHigh,
            foreground: scheme.onSurfaceVariant,
          ),
      ],
    );
  }
}

/// A wrapped row of pills. Wraps rather than scrolls: a long equipment list has
/// to stay readable at a glance without a gesture nobody knows is there.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.background,
    required this.foreground,
  });

  final List<String> values;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground),
            ),
          ),
      ],
    );
  }
}

/// A session with no exercises on it yet - what the create dialog produces.
class _NoExercises extends StatelessWidget {
  const _NoExercises();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        'This session has no exercises yet. Add one on the logging screen '
        'when you start training.',
        style: context.text.annotation.copyWith(height: 1.5),
      ),
    );
  }
}

/// Exercise list with numbering, names, set schemes, and rest times.
class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Text('THE LINEUP', style: text.labelCaps)]),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workout.logs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final log = workout.logs[index];
            return _ExerciseRow(index: index, log: log);
          },
        ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 42,
            alignment: Alignment.centerLeft,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: text.programBadge.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.exercise.name.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.setScheme}  ·  ${log.heaviestWeight} kg',
                  style: text.previousPerf,
                ),
              ],
            ),
          ),
          // Rest time
          Text('${log.restSeconds}s rest', style: text.setDim),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Start workout CTA button.
class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context)
              .pushNamed(SetLoggingScreen.routeFor(workout.id));
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(
          'Start ${workout.title}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
    );
  }
}
