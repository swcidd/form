import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plus_one/data/app_database.dart';
import 'package:plus_one/data/workout_repository.dart';
import 'package:plus_one/exercise_library.dart';
import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/profile_stats.dart';
import 'package:plus_one/models/saved_exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/seed_data.dart';

void main() {
  // sqflite's default factory talks to the platform channel, which does not
  // exist in the test VM. Pointing it at the FFI build of the same SQLite
  // library runs the real engine, so the schema and the SQL are genuinely
  // under test rather than a mock agreeing with itself.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase app;
  late WorkoutRepository repository;

  setUp(() async {
    app = AppDatabase();
    repository = WorkoutRepository(app);
    // One in-memory database per test. A file would persist across cases and
    // leak rows between them, so "an empty store" would only be true for the
    // first test to run.
    await app.open(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await app.close();
  });

  Workout sampleWorkout({
    String id = 'w1',
    String title = 'Upper Body',
    List<ExerciseLog> logs = const [],
  }) {
    return Workout(
      id: id,
      title: title,
      date: DateTime(2026, 10, 6),
      status: WorkoutStatus.planned,
      durationMin: 45,
      estimatedKcal: 420,
      targetMuscleGroups: const ['Chest', 'Triceps'],
      equipment: const ['Barbell'],
      logs: logs,
    );
  }

  group('schema', () {
    test('enables referential integrity on the connection', () async {
      final db = await app.open();

      // The pragma is per-connection and off by default in SQLite. Without it
      // deleting a workout would leave its exercises and sets behind as
      // orphans, which the cascade in the schema would silently not perform.
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first.values.first, 1);
    });

    test('creates every table the app needs', () async {
      final db = await app.open();

      final names = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tables = names.map((row) => row['name']).toSet();

      expect(
        tables,
        containsAll(<String>[
          AppDatabase.workoutsTable,
          AppDatabase.exerciseLogsTable,
          AppDatabase.setsTable,
          AppDatabase.profileTable,
          AppDatabase.savedExercisesTable,
        ]),
      );
    });

    test('indexes the workout date for calendar queries', () async {
      final db = await app.open();

      // The calendar renders a month at a time and the dashboard sorts recent
      // sessions by date; without this the whole table is scanned per query.
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
      );
      expect(indexes.map((row) => row['name']), contains('idx_workouts_date'));
    });

    test(
      'migrating from version 1 keeps the account and adds the table',
      () async {
        // A file a v1 app left behind: the workouts, and no saved-exercises
        // table. Rewinding the version is what makes the next open run the
        // migration rather than the fresh-install path. A file rather than the
        // in-memory path, because each in-memory open is its own database and
        // closing it would throw the account away before the migration ran.
        final path = p.join(
          Directory.systemTemp.path,
          'form_migration_test.db',
        );
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
        addTearDown(() {
          if (file.existsSync()) file.deleteSync();
        });

        final oldDb = AppDatabase();
        final old = WorkoutRepository(oldDb);
        await oldDb.open(path: path);
        await old.replaceWorkout(sampleWorkout());
        final db = await oldDb.open();
        await db.execute('DROP TABLE ${AppDatabase.savedExercisesTable}');
        await db.execute('PRAGMA user_version = 1');
        await oldDb.close();

        // The next launch: same file, current version.
        final nextDb = AppDatabase();
        final next = WorkoutRepository(nextDb);
        await nextDb.open(path: path);
        expect(await next.loadWorkouts(), hasLength(1));
        expect(await next.loadSavedExercises(), isEmpty);
        await nextDb.close();
      },
    );
  });

  group('round trip', () {
    test('an empty store reads back as empty', () async {
      expect(await repository.loadWorkouts(), isEmpty);
      expect(await repository.loadProfile(), isNull);
    });

    test('a workout survives a write and a read', () async {
      await repository.replaceWorkout(sampleWorkout());
      final loaded = await repository.loadWorkouts();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'w1');
      expect(loaded.single.title, 'Upper Body');
      expect(loaded.single.status, WorkoutStatus.planned);
      expect(loaded.single.targetMuscleGroups, ['Chest', 'Triceps']);
      expect(loaded.single.date, DateTime(2026, 10, 6));
    });

    test('exercises and sets keep their order and values', () async {
      await repository.replaceWorkout(
        sampleWorkout(
          logs: [
            ExerciseLog(
              exercise: Exercise(
                name: 'Bench Press',
                equipment: 'Barbell',
                muscleGroups: const ['Chest'],
              ),
              sets: const [
                WorkoutSet(reps: 8, weightKg: 60, completed: true),
                WorkoutSet(reps: 8, weightKg: 65),
              ],
            ),
            ExerciseLog(
              exercise: Exercise(
                name: 'Pushdown',
                equipment: 'Cable',
                muscleGroups: const ['Triceps'],
              ),
              sets: const [WorkoutSet(reps: 12, weightKg: 25)],
            ),
          ],
        ),
      );

      final loaded = (await repository.loadWorkouts()).single;

      // Order is part of the identity: a workout lists its exercises in the
      // order they were performed, and sets within each in turn.
      expect(loaded.logs.map((l) => l.exercise.name), [
        'Bench Press',
        'Pushdown',
      ]);
      expect(loaded.logs.first.sets.map((s) => s.reps), [8, 8]);
      expect(loaded.logs.first.sets.map((s) => s.weightKg), [60.0, 65.0]);
      expect(loaded.logs.first.sets.map((s) => s.completed), [true, false]);
      expect(loaded.logs.last.sets.single.reps, 12);
    });

    test('writing the same id replaces rather than duplicates', () async {
      await repository.replaceWorkout(sampleWorkout(title: 'Before'));
      await repository.replaceWorkout(sampleWorkout(title: 'After'));

      final loaded = await repository.loadWorkouts();
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'After');
    });

    test('a rewrite does not leave the previous sets behind', () async {
      await repository.replaceWorkout(
        sampleWorkout(
          logs: [
            ExerciseLog(
              exercise: Exercise(
                name: 'Bench Press',
                equipment: 'Barbell',
                muscleGroups: const ['Chest'],
              ),
              sets: const [
                WorkoutSet(reps: 8, weightKg: 60),
                WorkoutSet(reps: 8, weightKg: 60),
                WorkoutSet(reps: 8, weightKg: 60),
              ],
            ),
          ],
        ),
      );
      await repository.replaceWorkout(
        sampleWorkout(
          logs: [
            ExerciseLog(
              exercise: Exercise(
                name: 'Bench Press',
                equipment: 'Barbell',
                muscleGroups: const ['Chest'],
              ),
              sets: const [WorkoutSet(reps: 5, weightKg: 70)],
            ),
          ],
        ),
      );

      // The old three rows must be gone, not merged with the new one. This is
      // the case the delete-then-insert strategy exists to prevent.
      final loaded = (await repository.loadWorkouts()).single;
      expect(loaded.logs.single.sets, hasLength(1));
      expect(loaded.logs.single.sets.single.reps, 5);
    });

    test('deleting a workout takes its exercises and sets with it', () async {
      await repository.replaceWorkout(
        sampleWorkout(
          logs: [
            ExerciseLog(
              exercise: Exercise(
                name: 'Bench Press',
                equipment: 'Barbell',
                muscleGroups: const ['Chest'],
              ),
              sets: const [WorkoutSet(reps: 8, weightKg: 60)],
            ),
          ],
        ),
      );

      await repository.deleteWorkout('w1');

      final db = await app.open();
      // Orphaned rows would not show in loadWorkouts, so they are counted
      // directly: a cascade that silently failed would look correct here.
      final logs = await db.query(AppDatabase.exerciseLogsTable);
      final sets = await db.query(AppDatabase.setsTable);

      expect(await repository.loadWorkouts(), isEmpty);
      expect(logs, isEmpty);
      expect(sets, isEmpty);
    });

    test('loads many workouts in date order', () async {
      for (final entry in {'a': 3, 'b': 1, 'c': 2}.entries) {
        await repository.replaceWorkout(
          Workout(
            id: entry.key,
            title: entry.key,
            date: DateTime(2026, 10, entry.value),
            status: WorkoutStatus.completed,
            durationMin: 30,
            estimatedKcal: 200,
            targetMuscleGroups: const [],
            equipment: const [],
            logs: const [],
          ),
        );
      }

      final loaded = await repository.loadWorkouts();
      expect(loaded.map((w) => w.id), ['b', 'c', 'a']);
    });

    test('an empty log list round trips without inventing exercises', () async {
      await repository.replaceWorkout(sampleWorkout());
      expect((await repository.loadWorkouts()).single.logs, isEmpty);
    });
  });

  group('profile', () {
    test('round trips every field including records and badges', () async {
      await repository.saveProfile(seedProfile());

      final loaded = await repository.loadProfile();
      final original = seedProfile();

      expect(loaded, isNotNull);
      expect(loaded!.name, original.name);
      expect(loaded.handle, original.handle);
      expect(loaded.weightKg, original.weightKg);
      expect(loaded.isPro, original.isPro);
      expect(loaded.records, hasLength(original.records.length));
      expect(loaded.achievements, hasLength(original.achievements.length));
      expect(loaded.records.first.value, original.records.first.value);
    });

    test('saving twice leaves a single row', () async {
      // The row is keyed on a constant, so an insert without the preceding
      // delete would raise a constraint error on the second call.
      await repository.saveProfile(seedProfile());
      await repository.saveProfile(seedProfile().copyWith(name: 'Sam Reyes'));

      final db = await app.open();
      final rows = await db.query(AppDatabase.profileTable);

      expect(rows, hasLength(1));
      expect((await repository.loadProfile())!.name, 'Sam Reyes');
    });

    test('an empty account round trips as zeros rather than nulls', () async {
      await repository.saveProfile(ProfileStats.empty());

      final loaded = await repository.loadProfile();
      expect(loaded!.name, '');
      expect(loaded.totalWorkouts, 0);
      expect(loaded.records, isEmpty);
    });
  });

  group('saved exercises', () {
    final at = DateTime(2026, 10, 18, 9, 30);

    LibraryExercise exercise({String name = 'Barbell Curl'}) => LibraryExercise(
      name: name,
      primaryMuscle: 'biceps',
      secondaryMuscle: 'forearms',
      instructions: 'Curl the bar slowly.',
      equipment: const ['Barbell'],
      category: 'strength',
      level: 'intermediate',
      images: const ['assets/images/free-db/barbell-curl_1.png'],
      tips: 'Keep the elbows fixed.',
      variations: const ['Hammer curl'],
    );

    SavedExercise kept({String name = 'Barbell Curl'}) => SavedExercise(
      exercise: exercise(name: name),
      savedAt: at,
    );

    test('an empty store reads back as empty', () async {
      expect(await repository.loadSavedExercises(), isEmpty);
    });

    test('round trips every field through the payload', () async {
      await repository.saveSavedExercise(kept());

      final loaded = await repository.loadSavedExercises();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, LibraryExercise.keyFor('Barbell Curl'));
      expect(loaded.single.savedAt, at);
      expect(loaded.single.exercise.name, 'Barbell Curl');
      expect(loaded.single.exercise.secondaryMuscle, 'forearms');
      expect(loaded.single.exercise.equipment, ['Barbell']);
      expect(loaded.single.exercise.level, 'intermediate');
      expect(loaded.single.exercise.images, [
        'assets/images/free-db/barbell-curl_1.png',
      ]);
      expect(loaded.single.exercise.tips, 'Keep the elbows fixed.');
      expect(loaded.single.exercise.variations, ['Hammer curl']);
    });

    test('keeping one exercise twice leaves a single row', () async {
      await repository.saveSavedExercise(kept());
      await repository.saveSavedExercise(kept());

      final loaded = await repository.loadSavedExercises();
      expect(loaded, hasLength(1));
    });

    test(
      'a row whose payload no longer decodes is skipped, not thrown',
      () async {
        await repository.saveSavedExercise(kept());

        // A saved row outlives the code that wrote it, so the payload can be
        // anything. One unreadable entry costs that entry, not the library.
        final db = await app.open();
        await db.update(
          AppDatabase.savedExercisesTable,
          {'payload': '{not json'},
          where: 'id = ?',
          whereArgs: [LibraryExercise.keyFor('Barbell Curl')],
        );

        expect(await repository.loadSavedExercises(), isEmpty);
      },
    );

    test('clear empties the saved list with the rest', () async {
      await repository.saveSavedExercise(kept());
      await repository.clear();

      expect(await repository.loadSavedExercises(), isEmpty);
    });
  });

  group('clear', () {
    test('empties every table', () async {
      await repository.replaceWorkout(sampleWorkout());
      await repository.saveProfile(seedProfile());
      await repository.saveSavedExercise(
        SavedExercise(
          exercise: LibraryExercise(
            name: 'Barbell Curl',
            primaryMuscle: 'biceps',
            instructions: 'Curl the bar.',
            equipment: const ['Barbell'],
            category: 'strength',
          ),
          savedAt: DateTime(2026, 10, 18),
        ),
      );

      await repository.clear();

      expect(await repository.loadWorkouts(), isEmpty);
      expect(await repository.loadProfile(), isNull);
      expect(await repository.loadSavedExercises(), isEmpty);
    });
  });
}
