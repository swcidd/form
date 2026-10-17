import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'set_logging_screen.dart';

/// Pre-workout screen: shows the plan, hero image, and "Start workout" CTA.
///
/// Reachable from the dashboard and library through the named `/workout-detail`
/// route, which carries the workout id.
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

    // In a real app, fetch from provider. For now, build from id.
    final workout = _buildWorkoutFromId(id);

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
                  _TrainingIntent(workout: workout),
                  const SizedBox(height: 24),
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

  /// Placeholder: build a workout from the Figma "Lower Body A" example.
  /// In production this comes from the repository.
  Workout _buildWorkoutFromId(String? id) {
    return Workout(
      id: id ?? 'lower-body-a',
      title: 'LOWER BODY A',
      date: DateTime.now(),
      startTime: '18:00',
      place: 'Gym',
      status: WorkoutStatus.planned,
      durationMin: 55,
      estimatedKcal: 400,
      targetMuscleGroups: ['Quads', 'Glutes', 'Hamstrings', 'Calves', 'Abs'],
      equipment: ['Barbell', 'Dumbbells', 'Machine', 'Bodyweight'],
      logs: [
        ExerciseLog(
          exercise: Exercise(
            name: 'Barbell back squat',
            equipment: 'Barbell',
            muscleGroups: ['Quads', 'Glutes'],
          ),
          sets: [
            WorkoutSet(reps: 6, weightKg: 90),
            WorkoutSet(reps: 6, weightKg: 90),
            WorkoutSet(reps: 6, weightKg: 90),
            WorkoutSet(reps: 8, weightKg: 90),
          ],
          previousBest: '87.5 kg × 8 · Oct 05',
          restSeconds: 120,
        ),
        ExerciseLog(
          exercise: Exercise(
            name: 'Romanian deadlift',
            equipment: 'Barbell',
            muscleGroups: ['Hamstrings', 'Glutes'],
          ),
          sets: [
            WorkoutSet(reps: 8, weightKg: 70),
            WorkoutSet(reps: 8, weightKg: 70),
            WorkoutSet(reps: 8, weightKg: 70),
          ],
          previousBest: '72.5 kg × 8 · Oct 05',
          restSeconds: 120,
        ),
        ExerciseLog(
          exercise: Exercise(
            name: 'Bulgarian split squat',
            equipment: 'Dumbbells',
            muscleGroups: ['Quads', 'Glutes'],
          ),
          sets: [
            WorkoutSet(reps: 10, weightKg: 20),
            WorkoutSet(reps: 10, weightKg: 20),
            WorkoutSet(reps: 10, weightKg: 20),
          ],
          previousBest: '20 kg × 10 · Oct 05',
          restSeconds: 90,
        ),
        ExerciseLog(
          exercise: Exercise(
            name: 'Leg press',
            equipment: 'Machine',
            muscleGroups: ['Quads', 'Glutes'],
          ),
          sets: [
            WorkoutSet(reps: 12, weightKg: 140),
            WorkoutSet(reps: 12, weightKg: 140),
            WorkoutSet(reps: 12, weightKg: 140),
          ],
          previousBest: '130 kg × 12 · Oct 05',
          restSeconds: 90,
        ),
        ExerciseLog(
          exercise: Exercise(
            name: 'Standing calf raise',
            equipment: 'Machine',
            muscleGroups: ['Calves'],
          ),
          sets: [
            WorkoutSet(reps: 15, weightKg: 60),
            WorkoutSet(reps: 15, weightKg: 60),
            WorkoutSet(reps: 15, weightKg: 60),
          ],
          previousBest: '55 kg × 15 · Oct 05',
          restSeconds: 60,
        ),
        ExerciseLog(
          exercise: Exercise(
            name: 'Hanging leg raise',
            equipment: 'Bodyweight',
            muscleGroups: ['Abs'],
          ),
          sets: [
            WorkoutSet(reps: 12, weightKg: 0),
            WorkoutSet(reps: 12, weightKg: 0),
            WorkoutSet(reps: 12, weightKg: 0),
          ],
          previousBest: 'BW × 12 · Oct 05',
          restSeconds: 60,
        ),
      ],
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
                    // Category badge (lime)
                    Text(
                      'STRENGTH / LOWER',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.lime,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Workout title (Barlow Condensed Bold 48)
                    Text(workout.title, style: text.dataHero),
                    const SizedBox(height: 4),
                    // Meta line
                    Text(
                      '55 min  ·  6 exercises  ·  20 sets',
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

/// Training intent card.
class _TrainingIntent extends StatelessWidget {
  const _TrainingIntent({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("TODAY'S FOCUS", style: text.labelCaps),
        const SizedBox(height: 8),
        Text(
          'Build a stronger base. Controlled eccentrics, powerful reps. '
          'Leave 2 reps in reserve.',
          style: text.exerciseMeta.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

/// Exercise list with numbering, names, set schemes, and rest times.
class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('THE LINEUP', style: text.labelCaps),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                'Edit workout',
                style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
          Navigator.of(
            context,
          ).pushNamed(SetLoggingScreen.routeFor(workout.id));
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
