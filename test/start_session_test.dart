import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/taxonomy.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';

/// A workout is a template. Starting it logs a session of its own, so finishing
/// one does not consume the plan and the numbers actually lifted never
/// overwrite the numbers that were prescribed.
void main() {
  final today = DateTime(2026, 10, 29);

  Workout routine() => Workout(
    id: 'r1',
    title: 'Lower Body A',
    date: today,
    status: WorkoutStatus.planned,
    kind: WorkoutKind.routine,
    durationMin: 55,
    estimatedKcal: 0,
    targetMuscleGroups: const [],
    equipment: const [],
    logs: [
      ExerciseLog(
        exercise: const Exercise(
          name: 'Barbell Back Squat',
          equipment: 'Barbell',
          muscleGroups: ['Quads'],
        ),
        sets: const [
          WorkoutSet(reps: 6, weightKg: 90, completed: true),
          WorkoutSet(reps: 6, weightKg: 90),
        ],
      ),
    ],
  );

  WorkoutProvider build() =>
      WorkoutProvider(today: today, workouts: [routine()]);

  test('starting a routine logs a separate session', () {
    final provider = build();

    final session = provider.startSession(provider.byId('r1')!);

    expect(session.id, isNot('r1'));
    expect(provider.workouts, hasLength(2));
    expect(session.kind, WorkoutKind.session);
    expect(session.date, today);
    expect(session.status, WorkoutStatus.inProgress);
    expect(session.title, 'Lower Body A');
  });

  test('the session opens on the plan with nothing ticked', () {
    final provider = build();

    final session = provider.startSession(provider.byId('r1')!);

    expect(session.logs, hasLength(1));
    expect(session.logs.single.sets, hasLength(2));
    // The prescription carries over; the ticks do not.
    expect(
      session.logs.single.sets.map((set) => set.weightKg),
      everyElement(90),
    );
    expect(session.logs.single.sets.map((set) => set.reps), everyElement(6));
    expect(session.logs.single.sets.any((set) => set.completed), isFalse);
  });

  test('the routine is left exactly as it was', () {
    final provider = build();
    final before = provider.byId('r1')!;

    provider.startSession(before);

    final after = provider.byId('r1')!;
    expect(after.kind, WorkoutKind.routine);
    expect(after.status, WorkoutStatus.planned);
    // The set that was already ticked on the plan is still ticked: starting a
    // session must not reach back into the template.
    expect(after.logs.single.sets.first.completed, isTrue);
    expect(
      provider.workouts.where((w) => w.kind == WorkoutKind.routine),
      hasLength(1),
    );
  });

  test('starting twice logs two sessions', () {
    final provider = build();

    final first = provider.startSession(provider.byId('r1')!);
    final second = provider.startSession(provider.byId('r1')!);

    // The whole point: a second session on the same day is a second session,
    // not the same record reopened.
    expect(first.id, isNot(second.id));
    expect(provider.workouts, hasLength(3));
  });
}
