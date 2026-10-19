import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/session.dart';

/// Opens and owns the app's SQLite file.
///
/// Held as a single instance for the life of the process: `sqflite` serialises
/// writes internally, so re-opening per query costs latency and buys nothing.
/// Everything the app persists lives in this one file, which makes backup a
/// file copy and export an archive of it.
///
/// Schema lives here rather than in the DAOs so the shape of the whole store
/// can be read in one place. Bump [version] and add a step to [onUpgrade] for
/// any change; the app refuses to open a database it does not recognise
/// otherwise.
class AppDatabase {
  AppDatabase({this.fileName = 'plus_one.db'});

  final String fileName;

  /// Current schema version. Increment with every migration.
  static const int version = 4;

  static const String workoutsTable = 'workouts';
  static const String exerciseLogsTable = 'exercise_logs';
  static const String setsTable = 'sets';
  static const String profileTable = 'profile';
  static const String savedExercisesTable = 'saved_exercises';
  static const String accountsTable = 'accounts';
  static const String sessionTable = 'session';

  Database? _database;

  /// Whether the store is usable. False when the app is running against an
  /// injected provider in a test, which is how the UI tests run without a
  /// platform database.
  bool get isOpen => _database != null;

  Future<Database> open({String? path}) async {
    final existing = _database;
    if (existing != null) return existing;

    final resolved = path ?? p.join(await getDatabasesPath(), fileName);
    final opened = await openDatabase(
      resolved,
      version: version,
      onConfigure: _configure,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    _database = opened;
    return opened;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Enables the referential integrity SQLite keeps off by default.
  ///
  /// Without this, deleting a workout would leave its exercise logs and sets
  /// behind as orphans. The PRAGMA is per-connection, so it has to be set on
  /// every open rather than once at install time.
  Future<void> _configure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _create(Database db, int version) async {
    final batch = db.batch();

    batch.execute(_workoutsDdl(workoutsTable));
    batch.execute(_exerciseLogsDdl(exerciseLogsTable, workoutsTable));
    batch.execute(_setsDdl(setsTable, exerciseLogsTable));
    batch.execute(_profileDdl(profileTable));
    batch.execute(_savedExercisesDdl(savedExercisesTable));
    batch.execute(_accountsDdl);
    batch.execute(_sessionDdl);
    batch.execute(_workoutsIndexDdl(workoutsTable));

    await batch.commit(noResult: true);
  }

  /// Every table whose rows belong to one account, children before parents.
  ///
  /// The schema's own statement of what has an owner. Anything that deletes an
  /// account walks this list, so a table added later cannot be missed by a
  /// delete written earlier.
  static const List<String> accountScopedTables = [
    setsTable,
    exerciseLogsTable,
    workoutsTable,
    profileTable,
    savedExercisesTable,
  ];

  /// The name v4 stages a rebuilt table under, before renaming it into place.
  static const String _staged = '_v4';

  /// The workouts table, under whatever name it is being created.
  ///
  /// The name is a parameter because the v4 migration stages a copy of every
  /// table and renames it. Writing the shape down twice — once for a new install
  /// and once for the migration — is how a migration ends up disagreeing with a
  /// new install about what a row looks like.
  ///
  /// Keyed on `(userId, id)` rather than on `id`: every account numbers its own
  /// sessions from one, so two accounts both have a `w1`, and neither of them is
  /// the other's.
  static String _workoutsDdl(String table) =>
      '''
    CREATE TABLE $table (
      userId             TEXT    NOT NULL,
      id                 TEXT    NOT NULL,
      title              TEXT    NOT NULL,
      date               INTEGER NOT NULL,
      status             TEXT    NOT NULL,
      startTime          TEXT    NOT NULL DEFAULT '',
      place              TEXT    NOT NULL DEFAULT '',
      durationMin        INTEGER NOT NULL DEFAULT 0,
      estimatedKcal      INTEGER NOT NULL DEFAULT 0,
      targetMuscleGroups TEXT    NOT NULL DEFAULT '[]',
      equipment          TEXT    NOT NULL DEFAULT '[]',
      PRIMARY KEY (userId, id)
    )
  ''';

  /// Exercises are a child of a workout, keyed by position rather than by a
  /// surrogate id. The order they were logged in is meaningful and so is part
  /// of the identity, and the owner travels with the row, so the cascade finds
  /// the right account's exercises.
  static String _exerciseLogsDdl(String table, String workouts) =>
      '''
    CREATE TABLE $table (
      userId       TEXT    NOT NULL,
      workoutId    TEXT    NOT NULL,
      position     INTEGER NOT NULL,
      name         TEXT    NOT NULL,
      equipment    TEXT    NOT NULL DEFAULT '',
      muscleGroups TEXT    NOT NULL DEFAULT '[]',
      PRIMARY KEY (userId, workoutId, position),
      FOREIGN KEY (userId, workoutId) REFERENCES $workouts (userId, id)
        ON DELETE CASCADE
    )
  ''';

  static String _setsDdl(String table, String logs) =>
      '''
    CREATE TABLE $table (
      userId    TEXT    NOT NULL,
      workoutId TEXT    NOT NULL,
      logIndex  INTEGER NOT NULL,
      position  INTEGER NOT NULL,
      reps      INTEGER NOT NULL DEFAULT 0,
      weightKg  REAL    NOT NULL DEFAULT 0,
      completed INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (userId, workoutId, logIndex, position),
      FOREIGN KEY (userId, workoutId, logIndex)
        REFERENCES $logs (userId, workoutId, position) ON DELETE CASCADE
    )
  ''';

  /// One row per account, keyed on the account.
  ///
  /// A table rather than a key-value blob because these are columns the profile
  /// screen reads and the summary totals are computed from, and SQLite can type
  /// check them. The key used to be a constant `1` while the device had one
  /// account; it is the owner now, so two accounts have two profiles instead of
  /// taking turns at one.
  static String _profileDdl(String table) =>
      '''
    CREATE TABLE $table (
      userId        TEXT    PRIMARY KEY,
      name          TEXT    NOT NULL DEFAULT '',
      handle        TEXT    NOT NULL DEFAULT '',
      role          TEXT    NOT NULL DEFAULT '',
      memberSince   TEXT    NOT NULL DEFAULT '',
      isPro         INTEGER NOT NULL DEFAULT 0,
      weightKg      REAL    NOT NULL DEFAULT 0,
      heightCm      REAL    NOT NULL DEFAULT 0,
      bodyFatPct    REAL    NOT NULL DEFAULT 0,
      restingHrBpm  INTEGER NOT NULL DEFAULT 0,
      totalWorkouts INTEGER NOT NULL DEFAULT 0,
      totalKcal     INTEGER NOT NULL DEFAULT 0,
      totalHours    INTEGER NOT NULL DEFAULT 0,
      streakDays    INTEGER NOT NULL DEFAULT 0,
      badgeCount    INTEGER NOT NULL DEFAULT 0,
      records       TEXT    NOT NULL DEFAULT '[]',
      achievements  TEXT    NOT NULL DEFAULT '[]'
    )
  ''';

  /// The saved-exercises table.
  ///
  /// One payload column rather than a column per field: a saved entry is a copy
  /// of a catalogue record the app cannot ask for again while offline, and
  /// nothing queries inside it — the list reads and deletes whole rows. Keyed on
  /// the owner and the exercise, so two accounts can both keep the same one.
  static String _savedExercisesDdl(String table) =>
      '''
    CREATE TABLE $table (
      userId  TEXT    NOT NULL,
      id      TEXT    NOT NULL,
      savedAt INTEGER NOT NULL,
      payload TEXT    NOT NULL,
      PRIMARY KEY (userId, id)
    )
  ''';

  /// The calendar queries by owner and date on every month render, and the
  /// dashboard sorts the recent list by date. Without this the whole workout
  /// table is scanned per query.
  static String _workoutsIndexDdl(String table) =>
      'CREATE INDEX idx_workouts_user_date ON $table (userId, date)';

  /// An account that lives on this device.
  ///
  /// Keyed on a generated id rather than the address, because every other table
  /// attributes its rows to this id and an address is the thing a person is
  /// most likely to want to change. The email is unique, so the same address
  /// cannot end up with two accounts; it is stored already normalised, which is
  /// what makes that constraint mean "the same address" rather than "the same
  /// spelling". The password column holds a verifier, never a password.
  static const String _accountsDdl =
      '''
    CREATE TABLE $accountsTable (
      id           TEXT    PRIMARY KEY,
      email        TEXT    NOT NULL UNIQUE,
      displayName  TEXT    NOT NULL DEFAULT '',
      passwordHash TEXT    NOT NULL,
      createdAt    INTEGER NOT NULL
    )
  ''';

  /// Who is signed in, as one row keyed on a constant.
  ///
  /// A table rather than a preference because the session belongs to the same
  /// story as the account it names, and there is deliberately no foreign key
  /// here: the device session names no account, and signing out has to leave
  /// the account standing.
  static const String _sessionDdl =
      '''
    CREATE TABLE $sessionTable (
      id          INTEGER PRIMARY KEY CHECK (id = 1),
      userId      TEXT    NOT NULL,
      email       TEXT,
      displayName TEXT,
      issuedAt    INTEGER NOT NULL
    )
  ''';

  static void _createSavedExercises(DatabaseExecutor db) {
    db.execute(_savedExercisesDdl(savedExercisesTable));
  }

  static void _createAccounts(DatabaseExecutor db) {
    db.execute(_accountsDdl);
    db.execute(_sessionDdl);
  }

  Future<void> _upgrade(Database db, int from, int to) async {
    // v2 adds saved exercises, v3 accounts and the session.
    //
    // Both steps add their own tables and nothing else, never a recreate:
    // dropping what is already there would throw away the user's training
    // history to gain one feature. Each step creates the shape of its own time
    // for the same reason the v4 step rebuilds rather than trusts — a step that
    // wrote the newest shape would leave v4 rebuilding a table that has never
    // been written to.
    if (from < 2) {
      _createSavedExercises(db);
    }

    if (from < 3) {
      _createAccounts(db);
    }

    // v4 gives every row an owner.
    if (from < 4) {
      await _ownEverything(db);
    }
  }

  /// Fills in the `userId` column of everything written before there were
  /// accounts, and makes it part of each row's identity.
  ///
  /// Rebuilt rather than altered. The owner is part of what identifies a row —
  /// a workout is `(userId, id)`, because each account numbers its own sessions
  /// from one — and SQLite cannot change a primary key in place. So each table
  /// is copied into a staged one with the owner filled in and then renamed into
  /// place, which is also the only way to move a child's foreign key from a
  /// single column onto a pair.
  ///
  /// The rows that predate accounts belong to [Session.deviceUserId] — the
  /// device account that "continue offline" signs in as. An upgraded install
  /// therefore opens on its own training rather than on an empty app, and the
  /// named accounts a person makes afterwards start empty, which is what the
  /// app does for them on a fresh install too.
  ///
  /// The order is load-bearing. The copies go parent first, because a child's
  /// foreign key is checked against rows that have to be there by the time it is
  /// written. The old tables go children first, so no drop cascades onto a table
  /// that is about to be dropped anyway. And the renames go last, parents first,
  /// because renaming a table rewrites the references to it in the children
  /// still waiting to be renamed themselves.
  static Future<void> _ownEverything(Database db) async {
    final workouts = '$workoutsTable$_staged';
    final logs = '$exerciseLogsTable$_staged';
    final sets = '$setsTable$_staged';
    final profile = '$profileTable$_staged';
    final saved = '$savedExercisesTable$_staged';

    await db.execute(_workoutsDdl(workouts));
    await db.execute(_exerciseLogsDdl(logs, workouts));
    await db.execute(_setsDdl(sets, logs));
    await db.execute(_profileDdl(profile));
    await db.execute(_savedExercisesDdl(saved));

    final owner = Session.deviceUserId;

    await db.execute(
      'INSERT INTO $workouts '
      '(userId, id, title, date, status, startTime, place, durationMin, '
      'estimatedKcal, targetMuscleGroups, equipment) '
      'SELECT ?, id, title, date, status, startTime, place, durationMin, '
      'estimatedKcal, targetMuscleGroups, equipment FROM $workoutsTable',
      [owner],
    );
    await db.execute(
      'INSERT INTO $logs '
      '(userId, workoutId, position, name, equipment, muscleGroups) '
      'SELECT ?, workoutId, position, name, equipment, muscleGroups '
      'FROM $exerciseLogsTable',
      [owner],
    );
    await db.execute(
      'INSERT INTO $sets '
      '(userId, workoutId, logIndex, position, reps, weightKg, completed) '
      'SELECT ?, workoutId, logIndex, position, reps, weightKg, completed '
      'FROM $setsTable',
      [owner],
    );
    await db.execute(
      'INSERT INTO $profile '
      '(userId, name, handle, role, memberSince, isPro, weightKg, heightCm, '
      'bodyFatPct, restingHrBpm, totalWorkouts, totalKcal, totalHours, '
      'streakDays, badgeCount, records, achievements) '
      'SELECT ?, name, handle, role, memberSince, isPro, weightKg, heightCm, '
      'bodyFatPct, restingHrBpm, totalWorkouts, totalKcal, totalHours, '
      'streakDays, badgeCount, records, achievements FROM $profileTable',
      [owner],
    );
    // Columns named rather than selected wholesale, because this table may be
    // the one v2 made, with no owner column, or the one this version makes,
    // which a v1 file gets from the step above before this step rebuilds it.
    await db.execute(
      'INSERT INTO $saved (userId, id, savedAt, payload) '
      'SELECT ?, id, savedAt, payload FROM $savedExercisesTable',
      [owner],
    );

    for (final table in accountScopedTables) {
      await db.execute('DROP TABLE $table');
    }

    await db.execute('ALTER TABLE $workouts RENAME TO $workoutsTable');
    await db.execute('ALTER TABLE $logs RENAME TO $exerciseLogsTable');
    await db.execute('ALTER TABLE $sets RENAME TO $setsTable');
    await db.execute('ALTER TABLE $profile RENAME TO $profileTable');
    await db.execute('ALTER TABLE $saved RENAME TO $savedExercisesTable');

    await db.execute(_workoutsIndexDdl(workoutsTable));
  }
}
