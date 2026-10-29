import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';

/// A session's length is measured while it runs, not prescribed when it is
/// planned.
void main() {
  final today = DateTime(2026, 10, 29);

  Workout session({int durationMin = 0}) => Workout(
    id: 'w1',
    title: 'Lower Body A',
    date: today,
    status: WorkoutStatus.inProgress,
    durationMin: durationMin,
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
        sets: const [WorkoutSet(reps: 6, weightKg: 90)],
      ),
    ],
  );

  WorkoutProvider build({int durationMin = 0}) => WorkoutProvider(
    today: today,
    workouts: [session(durationMin: durationMin)],
  );

  test('finishing measures the session, and stops the clock', () {
    final provider = build();

    provider.startClock('w1');
    expect(provider.finishSessionClock('w1'), isNotNull);

    // The clock was consumed by finishing it: a second finish has nothing to
    // measure and must not overwrite the length with a fresh one.
    expect(provider.finishSessionClock('w1'), isNull);
  });

  test('a session with no clock records no length', () {
    // Something that was never started has not been timed, and inventing a
    // number for it would be worse than leaving it unmeasured.
    final provider = build(durationMin: 0);

    expect(provider.finishSessionClock('w1'), isNull);
    expect(provider.byId('w1')!.durationMin, 0);
  });

  test('a prescribed length is replaced by the measured one', () {
    final provider = build(durationMin: 45);
    expect(provider.byId('w1')!.durationMin, 45);

    provider.startClock('w1');
    provider.finishSessionClock('w1');

    // Under a minute reads as zero, and the 45 the plan used to prescribe is
    // gone: it was never a measurement.
    expect(provider.byId('w1')!.durationMin, 0);
  });

  test('starting a clock twice does not restart it', () {
    final provider = build();

    provider.startClock('w1');
    provider.startClock('w1');

    // Still exactly one clock, so finishing consumes it and the second finish
    // finds nothing.
    expect(provider.finishSessionClock('w1'), isNotNull);
    expect(provider.finishSessionClock('w1'), isNull);
  });

  test('a clock left running overnight is not a measurement', () {
    // The start is on the session now, so a session abandoned with the app
    // closed comes back with a start from a previous day. The hours in between
    // were not training - recording them would inflate the profile's total
    // hours with a marathon nobody ran.
    final provider = WorkoutProvider(
      today: today,
      workouts: [session().copyWith(startedAt: DateTime(2020, 1, 1, 7))],
    );

    expect(provider.finishSessionClock('w1'), isNull);
    expect(provider.byId('w1')!.durationMin, 0);

    // The stale start is cleared rather than kept: a clock that can never be
    // honestly finished is not a clock.
    expect(provider.byId('w1')!.startedAt, isNull);
  });

  test('finishing a session that is not there measures nothing', () {
    final provider = build();

    provider.startClock('nope');

    expect(provider.finishSessionClock('nope'), isNull);
  });
}
