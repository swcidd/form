import '../models/exercise.dart';
import '../models/workout.dart';

/// One exercise's best completed set, as the screens that report records need
/// to show it.
class SetRecord {
  const SetRecord({
    required this.exercise,
    required this.weightKg,
    required this.reps,
    required this.date,
  });

  final String exercise;
  final double weightKg;
  final int reps;

  /// The day the set was logged.
  final DateTime date;

  /// Epley's estimate of the single rep that set was worth.
  ///
  /// Sets are compared by this rather than by weight alone, because 100 kg for
  /// 5 reps is a better lift than 105 kg for 1 and comparing loads directly
  /// would report the opposite.
  double get estimatedOneRepMax => weightKg * (1 + reps / 30);

  /// "100 kg × 5", the way a lifter writes a set down.
  String get label => '${_trim(weightKg)} kg × $reps';

  static String _trim(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';
}

/// Statistics derived from the sessions on the device.
///
/// Screens report progress from here rather than from stored totals, because a
/// stored total is a second copy of the truth that nothing keeps up to date.
/// Counting the sessions means the numbers cannot go stale, and a brand new
/// account reads as empty instead of as whatever it was seeded with.
///
/// Only finished sessions count, and inside them only completed sets. A set
/// that was planned but never ticked is work the user has not done; counting it
/// would let a plan nobody performed move every figure on the screen.
class SessionStats {
  SessionStats(Iterable<Workout> workouts, {required DateTime today})
    : _finished = workouts
          .where((workout) => workout.status == WorkoutStatus.completed)
          .toList(growable: false),
      _today = DateTime(today.year, today.month, today.day);

  final List<Workout> _finished;
  final DateTime _today;

  /// True when nothing has ever been finished, so a screen should say so
  /// rather than print zeros as if they were results.
  bool get isEmpty => _finished.isEmpty;

  int get sessions => _finished.length;

  /// Total volume of the completed sets in every finished session.
  double get volumeKg => _volumeOf(_finished);

  /// Every finished session's completed sets, newest first.
  List<_LogEntry> get _entries {
    final entries = <_LogEntry>[
      for (final workout in _finished)
        for (final log in workout.logs)
          if (log.volume > 0) _LogEntry(workout: workout, log: log),
    ]..sort((a, b) => b.workout.date.compareTo(a.workout.date));
    return entries;
  }

  /// Each exercise's best set, heaviest estimate first.
  ///
  /// Bodyweight work is left out rather than ranked: a set worth 0 kg would sit
  /// at the bottom of a list of lifts and read as a failure rather than as a
  /// different kind of exercise.
  List<SetRecord> get records {
    final best = <String, SetRecord>{};

    for (final entry in _entries) {
      final log = entry.log;
      final name = log.exercise.name;

      for (final set in log.sets) {
        if (!set.completed || set.weightKg <= 0) continue;

        final candidate = SetRecord(
          exercise: name,
          weightKg: set.weightKg,
          reps: set.reps,
          date: entry.workout.date,
        );
        final current = best[name];
        if (current == null ||
            candidate.estimatedOneRepMax > current.estimatedOneRepMax) {
          best[name] = candidate;
        }
      }
    }

    return best.values.toList()
      ..sort((a, b) => b.estimatedOneRepMax.compareTo(a.estimatedOneRepMax));
  }

  /// The best set in one session, for the summary's "top set" line.
  SetRecord? topSetIn(Workout workout) {
    SetRecord? best;

    for (final log in workout.logs) {
      for (final set in log.sets) {
        if (!set.completed || set.weightKg <= 0) continue;

        final candidate = SetRecord(
          exercise: log.exercise.name,
          weightKg: set.weightKg,
          reps: set.reps,
          date: workout.date,
        );
        if (best == null ||
            candidate.estimatedOneRepMax > best.estimatedOneRepMax) {
          best = candidate;
        }
      }
    }

    return best;
  }

  /// The same exercise's best set in an earlier finished session, or null when
  /// this is the first time the exercise has been logged.
  ///
  /// The comparison is by estimated 1RM, so a session beats the last one by
  /// doing more work rather than by adding plates and dropping reps.
  SetRecord? previousBestOf(String exercise, {required DateTime before}) {
    SetRecord? best;

    for (final entry in _entries) {
      if (entry.workout.date.isAfter(before) ||
          entry.workout.date.isAtSameMomentAs(before)) {
        continue;
      }
      if (entry.log.exercise.name != exercise) continue;

      for (final set in entry.log.sets) {
        if (!set.completed || set.weightKg <= 0) continue;

        final candidate = SetRecord(
          exercise: exercise,
          weightKg: set.weightKg,
          reps: set.reps,
          date: entry.workout.date,
        );
        if (best == null ||
            candidate.estimatedOneRepMax > best.estimatedOneRepMax) {
          best = candidate;
        }
      }
    }

    return best;
  }

  /// Volume of the most recent finished session with this title before [date],
  /// or null when the title has not been used before.
  ///
  /// Matched on title because that is the only link between two sessions the
  /// app has: the same name means the same routine to the person who typed it.
  double? lastVolumeOf(String title, {required DateTime before}) {
    Workout? last;

    for (final workout in _finished) {
      if (!workout.date.isBefore(before) || workout.title != title) continue;
      if (last == null || workout.date.isAfter(last.date)) last = workout;
    }

    final session = last;
    return session == null ? null : _volumeOf([session]);
  }

  /// Finished sessions, newest first, optionally windowed to the last [days].
  List<Workout> recentSessions({int? days, int? limit}) {
    final sessions = [
      for (final workout in _finished)
        if (days == null || !workout.date.isBefore(_windowStart(days))) workout,
    ]..sort((a, b) => b.date.compareTo(a.date));
    return limit == null || sessions.length <= limit
        ? sessions
        : sessions.sublist(0, limit);
  }

  /// An exercise's best set in each finished session, oldest first.
  ///
  /// One point per session rather than per set, so the trend line answers
  /// "what did this exercise move?" instead of being dominated by whichever
  /// session happened to log the most sets.
  List<SetRecord> bestSeriesFor(String exercise, {int? days}) {
    final points = <SetRecord>[];
    final start = days == null ? null : _windowStart(days);

    for (final workout in _finished) {
      if (start != null && workout.date.isBefore(start)) continue;

      SetRecord? best;
      for (final log in workout.logs) {
        if (log.exercise.name != exercise) continue;
        for (final set in log.sets) {
          if (!set.completed || set.weightKg <= 0) continue;
          final candidate = SetRecord(
            exercise: exercise,
            weightKg: set.weightKg,
            reps: set.reps,
            date: workout.date,
          );
          if (best == null ||
              candidate.estimatedOneRepMax > best.estimatedOneRepMax) {
            best = candidate;
          }
        }
      }
      if (best != null) points.add(best);
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// How many of the exercise records were set inside the last [days], or all
  /// time when [days] is null.
  int recordCountIn(int? days) {
    if (days == null) return records.length;
    final start = _windowStart(days);
    return records.where((record) => !record.date.isBefore(start)).length;
  }

  DateTime _windowStart(int days) => _today.subtract(Duration(days: days - 1));

  /// Volume of the completed sets in the [days] days ending today.
  double volumeIn(int days) => _volumeOf(_inWindow(days));

  /// Sessions finished in the [days] days ending today.
  int sessionsIn(int days) => _inWindow(days).length;

  /// Completed sessions per week over the last four weeks.
  double get sessionsPerWeek => sessionsIn(28) / 4;

  /// How much more was lifted in the last [days] days than in the [days]
  /// before them, or null when the earlier window is empty.
  ///
  /// Null rather than a number so a screen can leave the comparison out: a
  /// first month of training has nothing to be a percentage of, and printing
  /// one anyway would be inventing the baseline.
  double? volumeChangeIn(int days) {
    final earlier = _volumeOf(_inWindow(days, endingBefore: true));
    if (earlier <= 0) return null;

    final recent = volumeIn(days);
    return (recent - earlier) / earlier * 100;
  }

  List<Workout> _inWindow(int days, {bool endingBefore = false}) {
    final end = endingBefore ? _today.subtract(Duration(days: days)) : _today;
    final start = end.subtract(Duration(days: days - 1));

    return [
      for (final workout in _finished)
        if (!workout.date.isBefore(start) && !workout.date.isAfter(end))
          workout,
    ];
  }

  static double _volumeOf(List<Workout> workouts) => workouts.fold(
    0.0,
    (total, workout) =>
        total + workout.logs.fold(0.0, (sum, log) => sum + log.volume),
  );
}

/// One log inside the session it belongs to, so a record can carry the date of
/// the day it was set on.
class _LogEntry {
  const _LogEntry({required this.workout, required this.log});

  final Workout workout;
  final ExerciseLog log;
}
