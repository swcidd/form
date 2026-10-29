import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/taxonomy.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';

/// A repeat is written as sessions, not as a rule, so what these tests check is
/// the set of days it leaves behind.
void main() {
  // Monday. Every window assertion below counts Mondays from here.
  final monday = DateTime(2026, 10, 26);

  Workout session(
    DateTime date, {
    String id = '',
    String title = 'Lower Body A',
    List<ExerciseLog> logs = const [],
    WorkoutStatus status = WorkoutStatus.planned,
  }) {
    return Workout(
      id: id,
      title: title,
      date: date,
      status: status,
      durationMin: 55,
      estimatedKcal: 0,
      targetMuscleGroups: const [],
      equipment: const [],
      logs: logs,
      modality: Modality.strength,
    );
  }

  WorkoutProvider build({List<Workout> workouts = const []}) =>
      WorkoutProvider(today: monday, workouts: workouts);

  group('repeating a workout', () {
    test('writes the chosen weekday for the whole horizon', () {
      final provider = build();

      final created = provider.addRepeatingWorkout(
        session(monday, id: 'base'),
        {DateTime.monday},
      );

      // Eight Mondays in an eight-week run: the base, then seven more.
      expect(created, hasLength(8));
      expect(provider.workouts, hasLength(8));
      for (final workout in provider.workouts) {
        expect(workout.date.weekday, DateTime.monday);
      }
    });

    test('the base date is not written twice', () {
      final provider = build();

      provider.addRepeatingWorkout(session(monday, id: 'base'), {
        DateTime.monday,
      });

      // The base is itself a Monday, so a naive repeat would add a second
      // session to the same day it was created on.
      expect(provider.workoutsOn(monday), hasLength(1));
    });

    test('a day that already has a session is left alone', () {
      final secondMonday = DateTime(2026, 11, 2);
      final provider = build(workouts: [session(secondMonday, id: 'existing')]);

      final created = provider.addRepeatingWorkout(
        session(monday, id: 'base'),
        {DateTime.monday},
      );

      expect(provider.workoutsOn(secondMonday), hasLength(1));
      expect(provider.workoutsOn(secondMonday).single.id, 'existing');
      // Everything else still lands: only the taken day is skipped.
      expect(created, hasLength(7));
    });

    test('several weekdays are written independently', () {
      final provider = build();

      provider.addRepeatingWorkout(session(monday, id: 'base'), {
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      });

      // 8 of each weekday in an eight-week run. The base is Monday's first
      // occurrence rather than an extra session, so this is 24 and not 25.
      expect(provider.workouts, hasLength(24));
      final weekdays = provider.workouts.map((w) => w.date.weekday).toSet();
      expect(weekdays, {DateTime.monday, DateTime.wednesday, DateTime.friday});
    });

    test('no weekdays leaves a one-off', () {
      final provider = build();

      final created = provider.addRepeatingWorkout(
        session(monday, id: 'base'),
        const {},
      );

      expect(created, hasLength(1));
      expect(provider.workouts, hasLength(1));
    });

    test('the horizon is the weeks asked for', () {
      final provider = build();

      final created = provider.addRepeatingWorkout(
        session(monday, id: 'base'),
        {DateTime.monday},
        weeks: 2,
      );

      expect(created, hasLength(2));
      expect(created.last.date, DateTime(2026, 11, 2));
    });

    test('every session gets its own id', () {
      final provider = build();

      provider.addRepeatingWorkout(session(monday, id: 'base'), {
        DateTime.monday,
        DateTime.friday,
      });

      // Ids are what byId, the logging screen and delete all key on: a repeat
      // sharing one with another session edits the wrong day.
      final ids = provider.workouts.map((w) => w.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.where((id) => id == 'base'), hasLength(1));
    });

    test('minted ids step past ids already in the store', () {
      // Fixtures never go through load(), which is the only place the counter
      // used to move. A seeded store would otherwise hand out w0 twice.
      final provider = build(
        workouts: [session(monday.subtract(const Duration(days: 7)), id: 'w0')],
      );

      provider.addRepeatingWorkout(session(monday), {DateTime.monday});

      final ids = provider.workouts.map((w) => w.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, contains('w1'));
      expect(ids.where((id) => id == 'w0'), hasLength(1));
    });

    test('a rest day is not an occupied day', () {
      final secondMonday = DateTime(2026, 11, 2);
      final provider = build(
        workouts: [
          session(secondMonday, id: 'rest', status: WorkoutStatus.rest),
        ],
      );

      final created = provider.addRepeatingWorkout(
        session(monday, id: 'base'),
        {DateTime.monday},
      );

      // A rest marker is the calendar saying "nothing here", not a session
      // that would be duplicated by training on the day.
      expect(created, hasLength(8));
      expect(created.any((w) => w.date == secondMonday), isTrue);
    });

    test('repeats start clean', () {
      final provider = build();
      final logged = session(
        monday,
        id: 'base',
        logs: [
          ExerciseLog(
            exercise: const Exercise(
              name: 'Barbell back squat',
              equipment: 'Barbell',
              muscleGroups: ['Quads'],
            ),
            sets: const [WorkoutSet(reps: 8, weightKg: 90, completed: true)],
          ),
        ],
        status: WorkoutStatus.completed,
      );

      final created = provider.addRepeatingWorkout(logged, {DateTime.monday});
      final repeat = created.last;

      // A copy of a finished session would carry yesterday's sets into next
      // week's plan, which reads as work already done.
      expect(repeat.logs, isEmpty);
      expect(repeat.status, WorkoutStatus.planned);
      expect(repeat.hasNewPR, isFalse);
      expect(repeat.title, 'Lower Body A');
      expect(repeat.modality, Modality.strength);
    });

    test('the run stays inside its own horizon', () {
      final provider = build();

      provider.addRepeatingWorkout(session(monday, id: 'base'), {
        DateTime.monday,
      });

      // Nothing beyond the eighth week: the horizon is what stops a repeat
      // from writing a decade of empty sessions on first use.
      final last = provider.workouts
          .map((w) => w.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      expect(last, DateTime(2026, 12, 14));
      expect(last.difference(monday).inDays, lessThan(8 * 7));
    });
  });
}
