import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/data/app_database.dart';
import 'package:plus_one/data/workout_repository.dart';
import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/profile_stats.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// "Restarting the app" for the provider is a brand new instance over the same
/// database - which is exactly what `main` builds on launch. These tests do
/// that literally: mutate through one provider, throw it away, build another
/// and assert the account is still there.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase app;

  setUp(() async {
    app = AppDatabase();
    // One in-memory database per test, so an empty store is empty for every
    // case rather than only the first one to run.
    await app.open(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await app.close();
  });

  final today = DateTime(2026, 10, 6);

  WorkoutProvider launch() =>
      WorkoutProvider(today: today, repository: WorkoutRepository(app));

  Workout planned({String title = 'Upper Body'}) => Workout(
    id: '',
    title: title,
    date: today,
    status: WorkoutStatus.planned,
    durationMin: 45,
    estimatedKcal: 420,
    targetMuscleGroups: const ['Chest'],
    equipment: const ['Barbell'],
    logs: const [
      ExerciseLog(
        exercise: Exercise(
          name: 'Bench Press',
          equipment: 'Barbell',
          muscleGroups: ['Chest'],
        ),
        sets: [WorkoutSet(reps: 8, weightKg: 60)],
      ),
    ],
  );

  test('a workout saved before the restart is there after it', () async {
    final first = launch();
    final stored = first.addWorkout(planned());
    expect(first.byId(stored.id), isNotNull);

    final second = launch();
    await second.load();

    expect(second.workouts, hasLength(1));
    final restored = second.workouts.single;
    expect(restored.id, stored.id);
    expect(restored.title, 'Upper Body');
    expect(restored.logs.single.sets.single.reps, 8);
    expect(restored.logs.single.sets.single.weightKg, 60);
  });

  test('a set ticked before the restart is still ticked after it', () async {
    final first = launch();
    final stored = first.addWorkout(planned());
    first.toggleSet(stored.id, 0, 0);

    final second = launch();
    await second.load();

    final restored = second.byId(stored.id)!;
    expect(restored.logs.single.sets.single.completed, isTrue);
    // One set, ticked: the session the user finished reads as finished.
    expect(restored.status, WorkoutStatus.completed);
  });

  test('a workout deleted before the restart stays deleted', () async {
    final first = launch();
    final stored = first.addWorkout(planned());
    expect(first.deleteWorkout(stored.id), isTrue);

    final second = launch();
    await second.load();

    expect(second.workouts, isEmpty);
  });

  test('the profile comes back with the account', () async {
    final first = launch();
    first.updateProfile(
      ProfileStats.empty().copyWith(name: 'Sherwin', weightKg: 78),
    );

    final second = launch();
    await second.load();

    expect(second.profile.name, 'Sherwin');
    expect(second.profile.weightKg, 78);
  });

  test('a new id cannot collide with one the store already used', () async {
    final first = launch();
    final stored = first.addWorkout(planned());
    expect(stored.id, 'w0');

    final second = launch();
    await second.load();
    final next = second.addWorkout(planned(title: 'Lower Body'));

    expect(next.id, isNot(stored.id));
    expect(next.id, 'w1');
  });

  test('a provider with no repository never writes to the store', () async {
    final inMemory = WorkoutProvider(today: today);
    inMemory.addWorkout(planned());

    final second = launch();
    await second.load();

    expect(second.workouts, isEmpty);
  });
}
