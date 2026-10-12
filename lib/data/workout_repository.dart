import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/exercise.dart';
import '../models/profile_stats.dart';
import '../models/workout.dart';
import 'app_database.dart';

/// Reads and writes workouts, exercises, sets and the profile.
///
/// Writes go through [replaceWorkout] rather than a set of granular verbs so a
/// workout is always persisted as one consistent unit. Ticking a single set
/// rewrites the three rows that belong to it, which is wasteful in principle
/// and irrelevant in practice at this size, and it removes the possibility of
/// a crash half way through leaving a session that mixes old and new.
///
/// Nothing here knows about widgets. [WorkoutProvider] owns the in-memory
/// state the UI observes; this owns the durable copy.
class WorkoutRepository {
  WorkoutRepository(this._app);

  final AppDatabase _app;

  Future<Database> get _db => _app.open();

  // --- Reads ----------------------------------------------------------------

  Future<List<Workout>> loadWorkouts() async {
    final db = await _db;
    final workoutRows = await db.query(
      AppDatabase.workoutsTable,
      orderBy: 'date ASC',
    );
    if (workoutRows.isEmpty) return [];

    // One query for every exercise in every workout, then one for every set,
    // rather than two queries per workout. At a few hundred sessions the naive
    // version issues thousands of round trips; this issues two.
    final logRows = await db.query(
      AppDatabase.exerciseLogsTable,
      orderBy: 'workoutId ASC, position ASC',
    );
    final setRows = await db.query(
      AppDatabase.setsTable,
      orderBy: 'workoutId ASC, logIndex ASC, position ASC',
    );

    final logsByWorkout = <String, List<ExerciseLog>>{};
    for (final row in logRows) {
      final id = row['workoutId']! as String;
      logsByWorkout
          .putIfAbsent(id, () => [])
          .add(
            ExerciseLog(
              exercise: Exercise(
                name: row['name']! as String,
                equipment: row['equipment']! as String,
                muscleGroups: _decodeStrings(row['muscleGroups']),
              ),
              sets: const [],
            ),
          );
    }

    // Sets arrive grouped and ordered, so appending in a single pass preserves
    // both the exercise order and the set order within each exercise.
    final setsByLog = <String, List<WorkoutSet>>{};
    for (final row in setRows) {
      final key = '${row['workoutId']}#${row['logIndex']}';
      setsByLog
          .putIfAbsent(key, () => [])
          .add(
            WorkoutSet(
              reps: row['reps']! as int,
              weightKg: (row['weightKg']! as num).toDouble(),
              completed: (row['completed']! as int) == 1,
            ),
          );
    }

    final logs = logsByWorkout;
    for (final entry in logs.entries) {
      final ordered = entry.value;
      for (var i = 0; i < ordered.length; i++) {
        final key = '${entry.key}#$i';
        ordered[i] = ordered[i].copyWith(sets: setsByLog[key] ?? const []);
      }
    }

    return [
      for (final row in workoutRows)
        _workoutFromRow(row, logs[row['id']! as String] ?? const []),
    ];
  }

  Future<ProfileStats?> loadProfile() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.profileTable,
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    return ProfileStats(
      name: row['name']! as String,
      handle: row['handle']! as String,
      role: row['role']! as String,
      memberSince: row['memberSince']! as String,
      isPro: (row['isPro']! as int) == 1,
      weightKg: (row['weightKg']! as num).toDouble(),
      heightCm: (row['heightCm']! as num).toDouble(),
      bodyFatPct: (row['bodyFatPct']! as num).toDouble(),
      restingHrBpm: row['restingHrBpm']! as int,
      totalWorkouts: row['totalWorkouts']! as int,
      totalKcal: row['totalKcal']! as int,
      totalHours: row['totalHours']! as int,
      streakDays: row['streakDays']! as int,
      badgeCount: row['badgeCount']! as int,
      records: [
        for (final record in _decodeObjects(row['records']))
          PersonalRecord.fromJson(record),
      ],
      achievements: [
        for (final badge in _decodeObjects(row['achievements']))
          Achievement.fromJson(badge),
      ],
    );
  }

  // --- Writes ---------------------------------------------------------------

  Future<void> replaceWorkout(Workout workout) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Delete-then-insert rather than an upsert per row. The cascade clears
      // the exercises and sets with the workout, and the FK pragma makes that
      // happen; without it this would silently orphan every set.
      await txn.delete(
        AppDatabase.workoutsTable,
        where: 'id = ?',
        whereArgs: [workout.id],
      );

      await txn.insert(AppDatabase.workoutsTable, _workoutToRow(workout));

      for (var i = 0; i < workout.logs.length; i++) {
        final log = workout.logs[i];
        await txn.insert(AppDatabase.exerciseLogsTable, {
          'workoutId': workout.id,
          'position': i,
          'name': log.exercise.name,
          'equipment': log.exercise.equipment,
          'muscleGroups': jsonEncode(log.exercise.muscleGroups),
        });

        for (var s = 0; s < log.sets.length; s++) {
          final set = log.sets[s];
          await txn.insert(AppDatabase.setsTable, {
            'workoutId': workout.id,
            'logIndex': i,
            'position': s,
            'reps': set.reps,
            'weightKg': set.weightKg,
            'completed': set.completed ? 1 : 0,
          });
        }
      }
    });
  }

  Future<void> deleteWorkout(String id) async {
    final db = await _db;
    // The cascade removes the exercises and sets. SQLite only honours it
    // because the connection has foreign keys enabled.
    await db.delete(
      AppDatabase.workoutsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveProfile(ProfileStats profile) async {
    final db = await _db;
    // Replace rather than insert-or-update: the row is keyed on a single
    // constant id, so there is never a second profile to reconcile with.
    await db.delete(AppDatabase.profileTable);
    await db.insert(AppDatabase.profileTable, {
      'id': 1,
      'name': profile.name,
      'handle': profile.handle,
      'role': profile.role,
      'memberSince': profile.memberSince,
      'isPro': profile.isPro ? 1 : 0,
      'weightKg': profile.weightKg,
      'heightCm': profile.heightCm,
      'bodyFatPct': profile.bodyFatPct,
      'restingHrBpm': profile.restingHrBpm,
      'totalWorkouts': profile.totalWorkouts,
      'totalKcal': profile.totalKcal,
      'totalHours': profile.totalHours,
      'streakDays': profile.streakDays,
      'badgeCount': profile.badgeCount,
      'records': jsonEncode([
        for (final record in profile.records) record.toJson(),
      ]),
      'achievements': jsonEncode([
        for (final badge in profile.achievements) badge.toJson(),
      ]),
    });
  }

  /// Discards everything. Used by tests and by a future "clear my data" action.
  Future<void> clear() async {
    final db = await _db;
    await db.delete(AppDatabase.setsTable);
    await db.delete(AppDatabase.exerciseLogsTable);
    await db.delete(AppDatabase.workoutsTable);
    await db.delete(AppDatabase.profileTable);
  }

  // --- Mapping --------------------------------------------------------------

  Map<String, Object?> _workoutToRow(Workout workout) => {
    'id': workout.id,
    'title': workout.title,
    // Stored as epoch milliseconds so date comparisons stay numeric. ISO
    // strings would sort correctly as text but defeat the date index.
    'date': workout.date.millisecondsSinceEpoch,
    'status': workout.status.name,
    'startTime': workout.startTime,
    'place': workout.place,
    'durationMin': workout.durationMin,
    'estimatedKcal': workout.estimatedKcal,
    'targetMuscleGroups': jsonEncode(workout.targetMuscleGroups),
    'equipment': jsonEncode(workout.equipment),
  };

  Workout _workoutFromRow(Map<String, Object?> row, List<ExerciseLog> logs) {
    return Workout(
      id: row['id']! as String,
      title: row['title']! as String,
      date: DateTime.fromMillisecondsSinceEpoch(row['date']! as int),
      status: WorkoutStatus.values.byName(row['status']! as String),
      startTime: row['startTime']! as String,
      place: row['place']! as String,
      durationMin: row['durationMin']! as int,
      estimatedKcal: row['estimatedKcal']! as int,
      targetMuscleGroups: _decodeStrings(row['targetMuscleGroups']),
      equipment: _decodeStrings(row['equipment']),
      logs: logs,
    );
  }

  /// Decodes a JSON list of strings, falling back to empty.
  ///
  /// A corrupt row should degrade one workout rather than crash the app on
  /// launch, so a decode failure is swallowed here rather than thrown.
  static List<String> _decodeStrings(Object? raw) {
    if (raw is! String) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) '$item'];
    } on FormatException {
      return const [];
    }
  }

  static List<Map<String, dynamic>> _decodeObjects(Object? raw) {
    if (raw is! String) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) item,
      ];
    } on FormatException {
      return const [];
    }
  }
}
