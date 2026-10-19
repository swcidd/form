import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
  static const int version = 3;

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

    batch.execute('''
      CREATE TABLE $workoutsTable (
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
    ''');

    // Exercises are a child of a workout, keyed by position rather than a
    // surrogate key. The order they were logged in is meaningful and is
    // therefore part of the identity, which keeps a row from drifting if the
    // list is reordered.
    batch.execute('''
      CREATE TABLE $exerciseLogsTable (
        workoutId   TEXT    NOT NULL,
        position    INTEGER NOT NULL,
        name        TEXT    NOT NULL,
        equipment   TEXT    NOT NULL DEFAULT '',
        muscleGroups TEXT   NOT NULL DEFAULT '[]',
        PRIMARY KEY (workoutId, position),
        FOREIGN KEY (workoutId) REFERENCES $workoutsTable (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE $setsTable (
        workoutId TEXT    NOT NULL,
        logIndex  INTEGER NOT NULL,
        position  INTEGER NOT NULL,
        reps      INTEGER NOT NULL DEFAULT 0,
        weightKg  REAL    NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (workoutId, logIndex, position),
        FOREIGN KEY (workoutId, logIndex)
          REFERENCES $exerciseLogsTable (workoutId, position) ON DELETE CASCADE
      )
    ''');

    // One row, keyed on a constant. A table rather than a key-value blob
    // because these are columns the profile screen filters on, and SQLite can
    // index and type-check them.
    batch.execute('''
      CREATE TABLE $profileTable (
        id             INTEGER PRIMARY KEY CHECK (id = 1),
        name           TEXT    NOT NULL DEFAULT '',
        handle         TEXT    NOT NULL DEFAULT '',
        role           TEXT    NOT NULL DEFAULT '',
        memberSince    TEXT    NOT NULL DEFAULT '',
        isPro          INTEGER NOT NULL DEFAULT 0,
        weightKg       REAL    NOT NULL DEFAULT 0,
        heightCm       REAL    NOT NULL DEFAULT 0,
        bodyFatPct     REAL    NOT NULL DEFAULT 0,
        restingHrBpm   INTEGER NOT NULL DEFAULT 0,
        totalWorkouts  INTEGER NOT NULL DEFAULT 0,
        totalKcal      INTEGER NOT NULL DEFAULT 0,
        totalHours     INTEGER NOT NULL DEFAULT 0,
        streakDays     INTEGER NOT NULL DEFAULT 0,
        badgeCount     INTEGER NOT NULL DEFAULT 0,
        records        TEXT    NOT NULL DEFAULT '[]',
        achievements   TEXT    NOT NULL DEFAULT '[]'
      )
    ''');

    // The calendar queries by date on every month render, and the dashboard
    // sorts the recent list by it. Without these the whole workout table is
    // scanned per query.
    batch.execute('CREATE INDEX idx_workouts_date ON $workoutsTable (date)');

    batch.execute(_savedExercisesDdl);
    batch.execute(_accountsDdl);
    batch.execute(_sessionDdl);

    await batch.commit(noResult: true);
  }

  /// The saved-exercises table's DDL, shared by a fresh install and the
  /// migration.
  ///
  /// One payload column rather than a column per field: a saved entry is a
  /// copy of a catalogue record the app cannot ask for again while offline,
  /// and nothing queries inside it — the list reads and deletes whole rows.
  static const String _savedExercisesDdl =
      '''
    CREATE TABLE $savedExercisesTable (
      id      TEXT    PRIMARY KEY,
      savedAt INTEGER NOT NULL,
      payload TEXT    NOT NULL
    )
  ''';

  /// An account that lives on this device.
  ///
  /// Keyed on a generated id rather than the address, because every other table
  /// will attribute its rows to this id, and an address is the thing a person is
  /// most likely to want to change. The email is unique so the same address
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
  /// A table rather than a preference because the session is part of the same
  /// story as the account it points at, and a foreign key here would be wrong:
  /// the device session belongs to no account, and signing out has to be able
  /// to leave the account behind intact.
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
    db.execute(_savedExercisesDdl);
  }

  static void _createAccounts(DatabaseExecutor db) {
    db.execute(_accountsDdl);
    db.execute(_sessionDdl);
  }

  Future<void> _upgrade(Database db, int from, int to) async {
    // v2 adds saved exercises. Added as its own table, never as a recreate:
    // dropping the others would throw away the user's training history to gain
    // one feature.
    if (from < 2) {
      _createSavedExercises(db);
    }

    // v3 adds accounts and the session. Two more new tables for the same
    // reason: the training history predates sign-in and is not sign-in's to
    // throw away. Rows written before this point are the device account's, and
    // the v4 migration is where that becomes explicit.
    if (from < 3) {
      _createAccounts(db);
    }
  }
}
