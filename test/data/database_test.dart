import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plus_one/auth/local_auth_repository.dart';
import 'package:plus_one/auth/password_hasher.dart';
import 'package:plus_one/data/app_database.dart';
import 'package:plus_one/data/workout_repository.dart';
import 'package:plus_one/exercise_library.dart';
import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/profile_stats.dart';
import 'package:plus_one/models/saved_exercise.dart';
import 'package:plus_one/models/taxonomy.dart';
import 'package:plus_one/models/session.dart';
import 'package:plus_one/models/workout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/seed_data.dart';
import '../support/sign_up.dart';

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

  /// The account the app signs into when a file predates accounts.
  const device = Session.deviceUserId;

  setUp(() async {
    app = AppDatabase();
    repository = WorkoutRepository(app, userId: device);
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
          AppDatabase.accountsTable,
          AppDatabase.sessionTable,
        ]),
      );
    });

    test('indexes the workout date for calendar queries', () async {
      final db = await app.open();

      // The calendar renders a month at a time and the dashboard sorts recent
      // sessions by date; without this the whole table is scanned per query.
      // The index leads with the owner, because every one of those queries
      // reads one account's sessions.
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
      );
      expect(
        indexes.map((row) => row['name']),
        contains('idx_workouts_user_date'),
      );
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
        final old = WorkoutRepository(oldDb, userId: device);
        await oldDb.open(path: path);
        await old.replaceWorkout(sampleWorkout());
        final db = await oldDb.open();
        // Everything the two migrations after v1 added, so the next open has
        // to put all of it back rather than finding it already there.
        await db.execute('DROP TABLE ${AppDatabase.savedExercisesTable}');
        await db.execute('DROP TABLE ${AppDatabase.accountsTable}');
        await db.execute('DROP TABLE ${AppDatabase.sessionTable}');
        await db.execute('PRAGMA user_version = 1');
        await oldDb.close();

        // The next launch: same file, current version.
        final nextDb = AppDatabase();
        final next = WorkoutRepository(nextDb, userId: device);
        await nextDb.open(path: path);
        expect(await next.loadWorkouts(), hasLength(1));
        expect(await next.loadSavedExercises(), isEmpty);
        await nextDb.close();
      },
    );

    test(
      'migrating from version 2 keeps the training and adds sign-in',
      () async {
        // A file a v2 app left behind: training and saved exercises, no
        // accounts. Same reasoning as above about a file rather than the
        // in-memory path.
        final path = p.join(
          Directory.systemTemp.path,
          'form_auth_migration_test.db',
        );
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
        addTearDown(() {
          if (file.existsSync()) file.deleteSync();
        });

        final oldDb = AppDatabase();
        final old = WorkoutRepository(oldDb, userId: device);
        await oldDb.open(path: path);
        await old.replaceWorkout(sampleWorkout());
        final db = await oldDb.open();
        await db.execute('DROP TABLE IF EXISTS ${AppDatabase.accountsTable}');
        await db.execute('DROP TABLE IF EXISTS ${AppDatabase.sessionTable}');
        await db.execute('PRAGMA user_version = 2');
        await oldDb.close();

        // The next launch: same file, current version.
        final nextDb = AppDatabase();
        final next = WorkoutRepository(nextDb, userId: device);
        await nextDb.open(path: path);

        // The migration adds sign-in; it does not cost anyone their history.
        expect(await next.loadWorkouts(), hasLength(1));

        // And the new tables are usable, not merely present.
        final auth = LocalAuthRepository(
          nextDb,
          hasher: const PasswordHasher(iterations: 50),
        );
        final session = await signUp(
          auth,
          email: 'sam@example.com',
          password: 'one-rep-more',
        );
        expect(session.isGuest, isFalse);
        expect((await auth.restoreSession())?.userId, session.userId);
        await nextDb.close();
      },
    );

    test('migrating from version 3 gives every row an owner', () async {
      // A file a v3 app left behind. Opened once by the current code — so the
      // tables v4 does not touch are real — and then the training tables are
      // replaced with the shape v3 gave them. Written out rather than produced
      // by rewinding the version on a current file: that file's tables are
      // already the new shape, and the rebuild would pass whether or not it
      // worked.
      final path = p.join(
        Directory.systemTemp.path,
        'form_owner_migration_test.db',
      );
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final oldDb = AppDatabase();
      final db = await oldDb.open(path: path);
      for (final table in AppDatabase.accountScopedTables) {
        await db.execute('DROP TABLE $table');
      }
      for (final ddl in _v3TrainingTables) {
        await db.execute(ddl);
      }

      // The account tables were not rebuilt by v4, so this file keeps the
      // shape v3 gave them. That is what makes the v5 step add a column
      // instead of finding one the current code already made.
      await db.execute('DROP TABLE ${AppDatabase.accountsTable}');
      await db.execute('DROP TABLE ${AppDatabase.sessionTable}');
      for (final ddl in _v3IdentityTables) {
        await db.execute(ddl);
      }

      await db.insert(AppDatabase.workoutsTable, {
        'id': 'w1',
        'title': 'Upper Body',
        'date': DateTime(2026, 10, 6).millisecondsSinceEpoch,
        'status': 'planned',
        'targetMuscleGroups': '["Chest"]',
        'equipment': '["Barbell"]',
        'durationMin': 45,
        'estimatedKcal': 420,
      });
      await db.insert(AppDatabase.exerciseLogsTable, {
        'workoutId': 'w1',
        'position': 0,
        'name': 'Bench Press',
        'equipment': 'Barbell',
        'muscleGroups': '["Chest"]',
      });
      await db.insert(AppDatabase.setsTable, {
        'workoutId': 'w1',
        'logIndex': 0,
        'position': 0,
        'reps': 8,
        'weightKg': 60.0,
        'completed': 1,
      });
      await db.insert(AppDatabase.profileTable, {'id': 1, 'name': 'Sam'});
      await db.insert(AppDatabase.savedExercisesTable, {
        'id': 'barbell-curl',
        'savedAt': DateTime(2026, 10, 5).millisecondsSinceEpoch,
        'payload': '{"name":"Barbell Curl"}',
      });
      await db.execute('PRAGMA user_version = 3');
      await oldDb.close();

      // The next launch: same file, current version.
      final nextDb = AppDatabase();
      final mine = WorkoutRepository(nextDb, userId: device);
      final next = await nextDb.open(path: path);

      // Everything is where it was, and it is the device account's: the person
      // who trained before there were accounts is the one "continue offline"
      // signs in as.
      final workouts = await mine.loadWorkouts();
      expect(workouts, hasLength(1));
      expect(workouts.single.id, 'w1');
      expect(workouts.single.logs.single.exercise.name, 'Bench Press');
      expect(workouts.single.logs.single.sets.single.reps, 8);
      expect(await mine.loadSavedExercises(), hasLength(1));
      expect((await mine.loadProfile())?.name, 'Sam');

      // And the children came with their parent rather than being orphaned by
      // the rebuild.
      expect(await mine.loadWorkouts(), hasLength(1));

      // A named account made afterwards starts empty. The owner the migration
      // writes is the device account specifically, not everybody.
      final someoneElse = WorkoutRepository(nextDb, userId: 'someone-else');
      expect(await someoneElse.loadWorkouts(), isEmpty);
      expect(await someoneElse.loadSavedExercises(), isEmpty);
      expect(await someoneElse.loadProfile(), isNull);

      // v7 added the date of birth the sign-up fills; rows from before it
      // have no answer and are not asked to invent one.
      final columns = await next.rawQuery(
        'PRAGMA table_info(${AppDatabase.profileTable})',
      );
      expect(columns.map((column) => column['name']), contains('dateOfBirth'));
      expect((await mine.loadProfile())?.dateOfBirth, isNull);
      await nextDb.close();
    });

    test('migrating from version 5 adds the profile date of birth', () async {
      final path = p.join(
        Directory.systemTemp.path,
        'form_dob_migration_test.db',
      );
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      // Start from the current file, then put the profile back to its v5
      // shape — no date of birth and no remembered unit choices.
      final oldDb = AppDatabase();
      final db = await oldDb.open(path: path);
      for (final column in [
        'dateOfBirth',
        'heightImperial',
        'weightImperial',
      ]) {
        await db.execute(
          'ALTER TABLE ${AppDatabase.profileTable} DROP COLUMN $column',
        );
      }
      await db.insert(AppDatabase.profileTable, {
        'userId': device,
        'name': 'Sam',
      });
      await db.execute('PRAGMA user_version = 5');
      await oldDb.close();

      final nextDb = AppDatabase();
      final next = await nextDb.open(path: path);

      final columns = await next.rawQuery(
        'PRAGMA table_info(${AppDatabase.profileTable})',
      );
      expect(
        columns.map((column) => column['name']),
        containsAll(['dateOfBirth', 'heightImperial', 'weightImperial']),
      );
      final profile = await WorkoutRepository(
        nextDb,
        userId: device,
      ).loadProfile();
      expect(profile?.dateOfBirth, isNull);
      expect(profile?.heightImperial, isFalse);
      expect(profile?.weightImperial, isFalse);
      await nextDb.close();
    });

    test('migrating from the v6 age column adds the date of birth', () async {
      final path = p.join(
        Directory.systemTemp.path,
        'form_v6_age_migration_test.db',
      );
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      // v6 wrote an integer age. The v7 profile no longer uses it, but a file
      // that ran that build must still open.
      final oldDb = AppDatabase();
      final db = await oldDb.open(path: path);
      for (final column in [
        'dateOfBirth',
        'heightImperial',
        'weightImperial',
      ]) {
        await db.execute(
          'ALTER TABLE ${AppDatabase.profileTable} DROP COLUMN $column',
        );
      }
      await db.execute(
        'ALTER TABLE ${AppDatabase.profileTable} '
        'ADD COLUMN age INTEGER NOT NULL DEFAULT 0',
      );
      await db.insert(AppDatabase.profileTable, {
        'userId': device,
        'name': 'Sam',
      });
      await db.execute('PRAGMA user_version = 6');
      await oldDb.close();

      final nextDb = AppDatabase();
      final next = await nextDb.open(path: path);

      final columns = await next.rawQuery(
        'PRAGMA table_info(${AppDatabase.profileTable})',
      );
      expect(
        columns.map((column) => column['name']),
        containsAll(['dateOfBirth', 'heightImperial', 'weightImperial']),
      );
      final profile = await WorkoutRepository(
        nextDb,
        userId: device,
      ).loadProfile();
      expect(profile?.dateOfBirth, isNull);
      expect(profile?.heightImperial, isFalse);
      expect(profile?.weightImperial, isFalse);
      await nextDb.close();
    });

    test('migrating from version 7 remembers metric units', () async {
      final path = p.join(
        Directory.systemTemp.path,
        'form_v7_units_migration_test.db',
      );
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      // v7 had the date of birth but no unit choice. A file from that build
      // should open as metric without losing the date.
      final oldDb = AppDatabase();
      final db = await oldDb.open(path: path);
      for (final column in ['heightImperial', 'weightImperial']) {
        await db.execute(
          'ALTER TABLE ${AppDatabase.profileTable} DROP COLUMN $column',
        );
      }
      await db.insert(AppDatabase.profileTable, {
        'userId': device,
        'name': 'Sam',
        'dateOfBirth': DateTime(1996, 6, 15).toIso8601String(),
      });
      await db.execute('PRAGMA user_version = 7');
      await oldDb.close();

      final nextDb = AppDatabase();
      await nextDb.open(path: path);

      final profile = await WorkoutRepository(
        nextDb,
        userId: device,
      ).loadProfile();
      expect(profile?.dateOfBirth, DateTime(1996, 6, 15));
      expect(profile?.heightImperial, isFalse);
      expect(profile?.weightImperial, isFalse);
      await nextDb.close();
    });

    test('migrating from version 8 adds the classification axes', () async {
      final path = p.join(
        Directory.systemTemp.path,
        'form_v8_taxonomy_migration_test.db',
      );
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      // A v8 file has sessions but no modality/split/goal/kind. The columns
      // are added empty, and the session still opens as an unclassified
      // session rather than being coerced into Strength.
      final oldDb = AppDatabase();
      final db = await oldDb.open(path: path);
      for (final column in ['modality', 'split', 'goal', 'kind']) {
        await db.execute(
          'ALTER TABLE ${AppDatabase.workoutsTable} DROP COLUMN $column',
        );
      }
      await db.insert(AppDatabase.workoutsTable, {
        'userId': device,
        'id': 'w1',
        'title': 'Upper body',
        'date': DateTime(2026, 10, 6).millisecondsSinceEpoch,
        'status': 'planned',
      });
      await db.execute('PRAGMA user_version = 8');
      await oldDb.close();

      final nextDb = AppDatabase();
      final next = await nextDb.open(path: path);
      final columns = await next.rawQuery(
        'PRAGMA table_info(${AppDatabase.workoutsTable})',
      );
      expect(
        columns.map((column) => column['name']),
        containsAll(['modality', 'split', 'goal', 'kind']),
      );

      final workouts = await WorkoutRepository(
        nextDb,
        userId: device,
      ).loadWorkouts();
      expect(workouts, hasLength(1));
      expect(workouts.single.modality, isNull);
      expect(workouts.single.split, isNull);
      expect(workouts.single.goal, isNull);
      expect(workouts.single.kind, WorkoutKind.session);
      await nextDb.close();
    });
  });

  group('accounts keep their own rows', () {
    test('one account cannot read another\'s training', () async {
      final sam = WorkoutRepository(app, userId: 'sam');
      final alex = WorkoutRepository(app, userId: 'alex');
      await sam.replaceWorkout(sampleWorkout(title: 'Sam\'s push day'));

      expect(await sam.loadWorkouts(), hasLength(1));
      expect(await alex.loadWorkouts(), isEmpty);
    });

    test('the same workout id in two accounts is two sessions', () async {
      final sam = WorkoutRepository(app, userId: 'sam');
      final alex = WorkoutRepository(app, userId: 'alex');

      // Both accounts number their own sessions from one, so this is the
      // ordinary case rather than a conflict: with the key on the id alone the
      // second of these would replace the first.
      await sam.replaceWorkout(sampleWorkout(title: 'Sam\'s push day'));
      await alex.replaceWorkout(sampleWorkout(title: 'Alex\'s push day'));

      expect((await sam.loadWorkouts()).single.title, 'Sam\'s push day');
      expect((await alex.loadWorkouts()).single.title, 'Alex\'s push day');
    });

    test('deleting a workout leaves the other account\'s alone', () async {
      final sam = WorkoutRepository(app, userId: 'sam');
      final alex = WorkoutRepository(app, userId: 'alex');
      await sam.replaceWorkout(sampleWorkout(title: 'Sam\'s push day'));
      await alex.replaceWorkout(sampleWorkout(title: 'Alex\'s push day'));

      await sam.deleteWorkout('w1');

      expect(await sam.loadWorkouts(), isEmpty);
      expect((await alex.loadWorkouts()).single.title, 'Alex\'s push day');
    });

    test('two accounts can keep the same exercise', () async {
      final sam = WorkoutRepository(app, userId: 'sam');
      final alex = WorkoutRepository(app, userId: 'alex');
      final saved = SavedExercise(
        exercise: const LibraryExercise(
          name: 'Barbell Curl',
          primaryMuscles: ['biceps'],
          instructions: ['Curl the bar.'],
          equipment: ['Barbell'],
          category: 'strength',
        ),
        savedAt: DateTime(2026, 10, 5),
      );

      await sam.saveSavedExercise(saved);
      await alex.saveSavedExercise(saved);

      expect(await sam.loadSavedExercises(), hasLength(1));
      expect(await alex.loadSavedExercises(), hasLength(1));

      await sam.deleteSavedExercise(saved.id);
      expect(await sam.loadSavedExercises(), isEmpty);
      expect(await alex.loadSavedExercises(), hasLength(1));
    });

    test('two accounts have two profiles', () async {
      final sam = WorkoutRepository(app, userId: 'sam');
      final alex = WorkoutRepository(app, userId: 'alex');

      await sam.saveProfile(ProfileStats.empty().copyWith(name: 'Sam'));
      await alex.saveProfile(ProfileStats.empty().copyWith(name: 'Alex'));

      expect((await sam.loadProfile())?.name, 'Sam');
      expect((await alex.loadProfile())?.name, 'Alex');
    });

    test('clearing one account leaves the other standing', () async {
      final sam = WorkoutRepository(app, userId: 'sam');
      final alex = WorkoutRepository(app, userId: 'alex');
      await sam.replaceWorkout(sampleWorkout(title: 'Sam\'s push day'));
      await alex.replaceWorkout(sampleWorkout(title: 'Alex\'s push day'));
      await sam.saveProfile(ProfileStats.empty().copyWith(name: 'Sam'));

      await sam.clear();

      expect(await sam.loadWorkouts(), isEmpty);
      expect(await sam.loadProfile(), isNull);
      expect(await alex.loadWorkouts(), hasLength(1));
    });

    test('removing an account takes its training with it', () async {
      final sam = WorkoutRepository(app, userId: 'sam');
      final alex = WorkoutRepository(app, userId: 'alex');
      await sam.replaceWorkout(sampleWorkout(title: 'Sam\'s push day'));
      await alex.replaceWorkout(sampleWorkout(title: 'Alex\'s push day'));

      final auth = LocalAuthRepository(
        app,
        hasher: const PasswordHasher(iterations: 50),
      );
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );
      final owned = WorkoutRepository(app, userId: session.userId);
      await owned.replaceWorkout(sampleWorkout(title: 'Sam\'s push day'));
      expect(await owned.loadWorkouts(), hasLength(1));

      await auth.deleteAccount(session.userId);

      // The rows are gone, not merely hidden: an account nobody can sign into
      // again should not leave its training behind.
      expect(await owned.loadWorkouts(), isEmpty);
      expect(await auth.restoreSession(), isNull);
      expect((await alex.loadWorkouts()).single.title, 'Alex\'s push day');
    });
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
      primaryMuscles: ['biceps'],
      secondaryMuscles: ['forearms'],
      instructions: ['Curl the bar slowly.'],
      equipment: const ['Barbell'],
      category: 'strength',
      level: 'intermediate',
      images: const ['assets/images/free-db/barbell-curl_1.png'],
      tips: ['Keep the elbows fixed.'],
      aliases: const ['Hammer curl'],
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
      expect(loaded.single.exercise.tips, ['Keep the elbows fixed.']);
      expect(loaded.single.exercise.aliases, ['Hammer curl']);
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

    test('a payload that decodes to no exercise is skipped too', () async {
      await repository.saveSavedExercise(kept());

      // Valid JSON, no usable entry: an exercise with no name has no key to
      // match the bookmark against and nothing to draw, so it and every other
      // nameless row would share the empty one.
      final db = await app.open();
      await db.update(
        AppDatabase.savedExercisesTable,
        {'payload': '{"primaryMuscle":"biceps"}'},
        where: 'id = ?',
        whereArgs: [LibraryExercise.keyFor('Barbell Curl')],
      );

      expect(await repository.loadSavedExercises(), isEmpty);
    });

    test('clear empties the saved list with the rest', () async {
      await repository.saveSavedExercise(kept());
      await repository.clear();

      expect(await repository.loadSavedExercises(), isEmpty);
    });
  });

  group('clear', () {
    test('empties every training table', () async {
      await repository.replaceWorkout(sampleWorkout());
      await repository.saveProfile(seedProfile());
      await repository.saveSavedExercise(
        SavedExercise(
          exercise: LibraryExercise(
            name: 'Barbell Curl',
            primaryMuscles: ['biceps'],
            instructions: ['Curl the bar.'],
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

    test('leaves the account and the session standing', () async {
      final auth = LocalAuthRepository(
        app,
        hasher: const PasswordHasher(iterations: 50),
      );
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );
      await repository.replaceWorkout(sampleWorkout());

      await repository.clear();

      // Clearing training is not deleting the account. An account that lost
      // its password along with its workouts would be a trap: the way back in
      // would be gone at the moment someone cleaned up.
      expect(await repository.loadWorkouts(), isEmpty);
      expect((await auth.restoreSession())?.userId, session.userId);
    });
  });
}

/// The training tables as v3 built them: no owner column, and a primary key on
/// the row's own id rather than on it and the account.
///
/// Written out here rather than imported from the app, because reading this
/// shape is the v4 migration's whole job. A fixture produced by the current code
/// would be the new shape wearing an old version number, and the rebuild would
/// pass whether or not it worked.
const List<String> _v3IdentityTables = [
  '''
  CREATE TABLE accounts (
    id           TEXT    PRIMARY KEY,
    email        TEXT    NOT NULL UNIQUE,
    displayName  TEXT    NOT NULL DEFAULT '',
    passwordHash TEXT    NOT NULL,
    createdAt    INTEGER NOT NULL
  )
  ''',
  '''
  CREATE TABLE session (
    id          INTEGER PRIMARY KEY CHECK (id = 1),
    userId      TEXT    NOT NULL,
    email       TEXT,
    displayName TEXT,
    issuedAt    INTEGER NOT NULL
  )
  ''',
];

const List<String> _v3TrainingTables = [
  '''
  CREATE TABLE workouts (
    id                 TEXT    PRIMARY KEY,
    title              TEXT    NOT NULL,
    date               INTEGER NOT NULL,
    status             TEXT    NOT NULL,
    startTime          TEXT    NOT NULL DEFAULT '',
    place              TEXT    NOT NULL DEFAULT '',
    durationMin        INTEGER NOT NULL DEFAULT 0,
    estimatedKcal      INTEGER NOT NULL DEFAULT 0,
    targetMuscleGroups TEXT    NOT NULL DEFAULT '[]',
    equipment          TEXT    NOT NULL DEFAULT '[]'
  )
  ''',
  '''
  CREATE TABLE exercise_logs (
    workoutId    TEXT    NOT NULL,
    position     INTEGER NOT NULL,
    name         TEXT    NOT NULL,
    equipment    TEXT    NOT NULL DEFAULT '',
    muscleGroups TEXT    NOT NULL DEFAULT '[]',
    PRIMARY KEY (workoutId, position),
    FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE sets (
    workoutId TEXT    NOT NULL,
    logIndex  INTEGER NOT NULL,
    position  INTEGER NOT NULL,
    reps      INTEGER NOT NULL DEFAULT 0,
    weightKg  REAL    NOT NULL DEFAULT 0,
    completed INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (workoutId, logIndex, position),
    FOREIGN KEY (workoutId, logIndex)
      REFERENCES exercise_logs (workoutId, position) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE profile (
    id           INTEGER PRIMARY KEY CHECK (id = 1),
    name         TEXT    NOT NULL DEFAULT '',
    handle       TEXT    NOT NULL DEFAULT '',
    role         TEXT    NOT NULL DEFAULT '',
    memberSince  TEXT    NOT NULL DEFAULT '',
    isPro        INTEGER NOT NULL DEFAULT 0,
    weightKg     REAL    NOT NULL DEFAULT 0,
    heightCm     REAL    NOT NULL DEFAULT 0,
    bodyFatPct   REAL    NOT NULL DEFAULT 0,
    restingHrBpm INTEGER NOT NULL DEFAULT 0,
    totalWorkouts INTEGER NOT NULL DEFAULT 0,
    totalKcal    INTEGER NOT NULL DEFAULT 0,
    totalHours   INTEGER NOT NULL DEFAULT 0,
    streakDays   INTEGER NOT NULL DEFAULT 0,
    badgeCount   INTEGER NOT NULL DEFAULT 0,
    records      TEXT    NOT NULL DEFAULT '[]',
    achievements TEXT    NOT NULL DEFAULT '[]'
  )
  ''',
  '''
  CREATE TABLE saved_exercises (
    id      TEXT    PRIMARY KEY,
    savedAt INTEGER NOT NULL,
    payload TEXT    NOT NULL
  )
  ''',
];
