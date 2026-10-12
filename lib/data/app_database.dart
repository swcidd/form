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
  static const int version = 1;

  static const String workoutsTable = 'workouts';
  static const String exerciseLogsTable = 'exercise_logs';
  static const String setsTable = 'sets';
  static const String profileTable = 'profile';

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

    await batch.commit(noResult: true);
  }

  Future<void> _upgrade(Database db, int from, int to) async {
    // Only version 1 exists so far, so there is nothing to migrate from. Future
    // steps go here as `if (from < 2) { ... }`, never as a wholesale recreate:
    // dropping the tables would throw away the user's training history.
  }
}
