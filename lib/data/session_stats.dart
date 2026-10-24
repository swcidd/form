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

/// One week in an exercise's estimated-1RM series.
///
/// [estimatedOneRepMax] is null when the exercise was not trained that week.
/// A missing week is not zero: no session means nothing is known, and drawing
/// it at the baseline would invent a drop that never happened.
class OneRepMaxWeek {
  const OneRepMaxWeek({required this.weekStart, this.estimatedOneRepMax});

  /// Monday that starts the week, at local midnight.
  final DateTime weekStart;

  /// Best estimate logged in the week, or null when it was not trained.
  final double? estimatedOneRepMax;
}

/// Four weeks of one exercise's estimated 1RM, newest week last.
class ExerciseOneRepMaxTrend {
  const ExerciseOneRepMaxTrend({required this.exercise, required this.weeks});

  final String exercise;
  final List<OneRepMaxWeek> weeks;

  /// The weeks that actually contain a completed weighted set.
  Iterable<OneRepMaxWeek> get observed =>
      weeks.where((week) => week.estimatedOneRepMax != null);

  /// The newest observed estimate. Null when the exercise has no recent work.
  double? get latest {
    for (final week in weeks.reversed) {
      final value = week.estimatedOneRepMax;
      if (value != null) return value;
    }
    return null;
  }

  /// Change from the first observed week to the newest one.
  ///
  /// Null until there are two points to compare, so the card can leave the
  /// percentage off instead of claiming progress from one session.
  double? get changePercent {
    final points = observed.toList(growable: false);
    if (points.length < 2) return null;

    final first = points.first.estimatedOneRepMax!;
    final last = points.last.estimatedOneRepMax!;
    if (first <= 0) return null;
    return (last - first) / first * 100;
  }
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

  /// Estimated 1RM for every exercise trained in the last four weeks.
  ///
  /// Each week is a calendar week starting Monday. The series uses the best
  /// completed set of each week, because a 1RM estimate is about the ceiling
  /// reached, not the average set. Exercises are ordered by their latest
  /// estimate so the strongest current lift is the obvious default.
  List<ExerciseOneRepMaxTrend> get oneRepMaxTrends {
    final starts = _weekStarts(4);
    final series = <String, List<double?>>{};

    for (final entry in _entries) {
      final name = entry.log.exercise.name;
      final weekIndex = _weekIndexFor(entry.workout.date, starts);
      if (weekIndex == null) continue;

      for (final set in entry.log.sets) {
        if (!set.completed || set.weightKg <= 0) continue;

        final estimate = set.weightKg * (1 + set.reps / 30);
        final values = series.putIfAbsent(
          name,
          () => List<double?>.filled(starts.length, null),
        );
        final current = values[weekIndex];
        if (current == null || estimate > current) {
          values[weekIndex] = estimate;
        }
      }
    }

    final trends = [
      for (final entry in series.entries)
        ExerciseOneRepMaxTrend(
          exercise: entry.key,
          weeks: [
            for (var index = 0; index < starts.length; index++)
              OneRepMaxWeek(
                weekStart: starts[index],
                estimatedOneRepMax: entry.value[index],
              ),
          ],
        ),
    ];

    trends.sort((a, b) {
      final latest = a.latest ?? 0;
      final other = b.latest ?? 0;
      final byLatest = other.compareTo(latest);
      return byLatest != 0 ? byLatest : a.exercise.compareTo(b.exercise);
    });
    return trends;
  }

  /// Monday starts for the [count] weeks ending with the current week.
  List<DateTime> _weekStarts(int count) {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    return [
      for (var index = count - 1; index >= 0; index--)
        monday.subtract(Duration(days: index * 7)),
    ];
  }

  /// The week bucket containing [date], or null when it falls outside.
  static int? _weekIndexFor(DateTime date, List<DateTime> starts) {
    for (var index = 0; index < starts.length; index++) {
      final start = starts[index];
      final next = start.add(const Duration(days: 7));
      if (!date.isBefore(start) && date.isBefore(next)) return index;
    }
    return null;
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
