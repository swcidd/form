import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../exercise_library.dart';
import '../models/exercise.dart';
import '../models/profile_stats.dart';
import '../models/saved_exercise.dart';
import '../models/workout.dart';
import 'app_database.dart';

/// Reads and writes one account's workouts, exercises, sets and profile.
///
/// Writes go through [replaceWorkout] rather than a set of granular verbs so a
/// workout is always persisted as one consistent unit. Ticking a single set
/// rewrites the three rows that belong to it, which is wasteful in principle
/// and irrelevant in practice at this size, and it removes the possibility of
/// a crash half way through leaving a session that mixes old and new.
///
/// Scoped to an account at construction rather than per call: every row in the
/// store belongs to somebody, so a repository *is* "the store as one account
/// sees it", and there is no query here that could forget to say whose. A
/// different account is a different repository over the same database.
///
/// Nothing here knows about widgets. [WorkoutProvider] owns the in-memory
/// state the UI observes; this owns the durable copy.
class WorkoutRepository {
  WorkoutRepository(this._app, {required this.userId});

  final AppDatabase _app;

  /// The account every row this repository reads or writes belongs to.
  final String userId;

  Future<Database> get _db => _app.open();

  // --- Reads ----------------------------------------------------------------

  /// Exercises the user kept, newest first.
  ///
  /// A row whose payload no longer decodes is skipped rather than thrown: one
  /// unreadable entry should cost the user that entry, not their library and
  /// not the launch.
  Future<List<SavedExercise>> loadSavedExercises() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.savedExercisesTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'savedAt DESC',
    );

    final saved = <SavedExercise>[];
    for (final row in rows) {
      final payload = row['payload'];
      if (payload is! String) continue;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) continue;
        final exercise = LibraryExercise.fromJson(decoded);
        // A payload that keys to nothing is not an exercise: it has no
        // identity to match the bookmark against, so it would show as a blank
        // row and share a key with every other nameless entry.
        if (exercise.id.isEmpty) continue;
        saved.add(
          SavedExercise(
            exercise: exercise,
            savedAt: DateTime.fromMillisecondsSinceEpoch(
              row['savedAt']! as int,
            ),
          ),
        );
      } on FormatException catch (error) {
        debugPrint('Skipping an unreadable saved exercise: $error');
      }
    }
    return saved;
  }

  Future<List<Workout>> loadWorkouts() async {
    final db = await _db;
    final workoutRows = await db.query(
      AppDatabase.workoutsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    if (workoutRows.isEmpty) return [];

    // One query for every exercise in every workout, then one for every set,
    // rather than two queries per workout. At a few hundred sessions the naive
    // version issues thousands of round trips; this issues two. The children
    // carry the owner too, so a filter here is a filter and not a join.
    final logRows = await db.query(
      AppDatabase.exerciseLogsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'workoutId ASC, position ASC',
    );
    final setRows = await db.query(
      AppDatabase.setsTable,
      where: 'userId = ?',
      whereArgs: [userId],
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
      where: 'userId = ?',
      whereArgs: [userId],
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
      dateOfBirth: row['dateOfBirth'] is String
          ? DateTime.tryParse(row['dateOfBirth'] as String)
          : null,
      weightKg: (row['weightKg']! as num).toDouble(),
      heightCm: (row['heightCm']! as num).toDouble(),
      heightImperial: (row['heightImperial']! as int) == 1,
      weightImperial: (row['weightImperial']! as int) == 1,
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

  Future<void> saveSavedExercise(SavedExercise saved) async {
    final db = await _db;
    // Replace rather than insert: the key is the exercise and its owner, so
    // keeping something already kept has one row, not two with different
    // timestamps.
    await db.insert(AppDatabase.savedExercisesTable, {
      'userId': userId,
      'id': saved.id,
      'savedAt': saved.savedAt.millisecondsSinceEpoch,
      'payload': jsonEncode(saved.exercise.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSavedExercise(String id) async {
    final db = await _db;
    await db.delete(
      AppDatabase.savedExercisesTable,
      where: 'userId = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  Future<void> replaceWorkout(Workout workout) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Delete-then-insert rather than an upsert per row. The cascade clears
      // the exercises and sets with the workout, and the FK pragma makes that
      // happen; without it this would silently orphan every set. The owner is
      // part of the key, so this cannot reach another account's session.
      await txn.delete(
        AppDatabase.workoutsTable,
        where: 'userId = ? AND id = ?',
        whereArgs: [userId, workout.id],
      );

      await txn.insert(AppDatabase.workoutsTable, _workoutToRow(workout));

      for (var i = 0; i < workout.logs.length; i++) {
        final log = workout.logs[i];
        await txn.insert(AppDatabase.exerciseLogsTable, {
          'userId': userId,
          'workoutId': workout.id,
          'position': i,
          'name': log.exercise.name,
          'equipment': log.exercise.equipment,
          'muscleGroups': jsonEncode(log.exercise.muscleGroups),
        });

        for (var s = 0; s < log.sets.length; s++) {
          final set = log.sets[s];
          await txn.insert(AppDatabase.setsTable, {
            'userId': userId,
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
      where: 'userId = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  Future<void> saveProfile(ProfileStats profile) async {
    final db = await _db;
    // Replace rather than insert-or-update: the row is keyed on the account,
    // so there is never a second profile of theirs to reconcile with.
    await db.delete(
      AppDatabase.profileTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    await db.insert(AppDatabase.profileTable, profileToRow(userId, profile));
  }

  /// The row [saveProfile] writes, shared with sign-up so a new account's
  /// measurements land in one place.
  static Map<String, Object?> profileToRow(
    String userId,
    ProfileStats profile,
  ) => {
    'userId': userId,
    'name': profile.name,
    'handle': profile.handle,
    'role': profile.role,
    'memberSince': profile.memberSince,
    'isPro': profile.isPro ? 1 : 0,
    'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
    'weightKg': profile.weightKg,
    'heightCm': profile.heightCm,
    'heightImperial': profile.heightImperial ? 1 : 0,
    'weightImperial': profile.weightImperial ? 1 : 0,
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
  };

  /// Discards this account's workouts, profile and saved exercises. Used by
  /// tests and by the "start over" action.
  ///
  /// Only theirs: another account on the same device is another repository and
  /// keeps its training. Accounts and the session deliberately stay too —
  /// clearing training is not deleting the account, and an account whose
  /// password went with its workouts would leave nobody a way back in.
  Future<void> clear() async {
    final db = await _db;
    // Children first, from the schema's own list of what has an owner, so a
    // table added later is cleared rather than left behind.
    for (final table in AppDatabase.accountScopedTables) {
      await db.delete(table, where: 'userId = ?', whereArgs: [userId]);
    }
  }

  // --- Mapping --------------------------------------------------------------

  Map<String, Object?> _workoutToRow(Workout workout) => {
    'userId': userId,
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
