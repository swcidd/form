import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../models/metric.dart';
import '../models/profile_stats.dart';
import '../models/workout.dart';

/// Single source of truth for workout state.
///
/// Screens read through getters and mutate through the small verb set below,
/// so there is one place where a change is decided and exactly one
/// `notifyListeners` per change. Nothing here knows about widgets, which
/// keeps the API swap later confined to the constructors.
///
/// Starts empty. A new account has no sessions and no profile, and every
/// screen is expected to render that honestly rather than the provider
/// inventing sample content behind the user's back. Tests pass fixtures in
/// through the constructor instead of relying on a default they cannot see.
class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider({
    DateTime? today,
    List<Workout>? workouts,
    List<Metric>? metrics,
    ProfileStats? profile,
  }) : _today = _dayOnly(today ?? DateTime.now()),
       // Copies are deliberate: callers often hand over const or
       // unmodifiable fixtures, and this class has to stay free to reorder
       // and replace entries in place.
       _workouts = List.of(workouts ?? const []),
       _metrics = List.of(metrics ?? const []),
       _profile = profile ?? ProfileStats.empty() {
    _sort();
  }

  final DateTime _today;
  final List<Workout> _workouts;
  final List<Metric> _metrics;
  ProfileStats _profile;
  int _nextId = 0;
  int _weeklyGoal = 4;

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // --- Reads -----------------------------------------------------------------

  DateTime get today => _today;

  List<Workout> get workouts => List.unmodifiable(_workouts);

  List<Metric> get metrics => List.unmodifiable(_metrics);

  ProfileStats get profile => _profile;

  /// The session the dashboard should push the user toward: today's plan if
  /// it exists, otherwise the next one on the calendar.
  Workout? get focusWorkout {
    final todayWorkouts = workoutsOn(_today);
    for (final workout in todayWorkouts) {
      if (workout.status == WorkoutStatus.planned) return workout;
    }
    for (final workout in _workouts) {
      if (workout.date.isAfter(_today) &&
          workout.status == WorkoutStatus.planned) {
        return workout;
      }
    }
    return null;
  }

  List<Workout> workoutsOn(DateTime date) {
    final day = _dayOnly(date);
    return _workouts
        .where((workout) => _dayOnly(workout.date) == day)
        .toList(growable: false);
  }

  Workout? byId(String id) {
    for (final workout in _workouts) {
      if (workout.id == id) return workout;
    }
    return null;
  }

  /// Days in a row with at least one finished session, counting back from
  /// today. Today may still be empty, so the count starts from yesterday in
  /// that case rather than reporting a broken streak before the user trains.
  int get streakDays {
    var cursor = _today;
    if (!_hasCompletedOn(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (_hasCompletedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool _hasCompletedOn(DateTime date) => workoutsOn(
    date,
  ).any((workout) => workout.status == WorkoutStatus.completed);

  int get workoutsThisMonth => _workouts
      .where((w) => w.date.month == _today.month && w.date.year == _today.year)
      .length;

  int get completedThisMonth => _workouts
      .where(
        (w) =>
            w.date.month == _today.month &&
            w.date.year == _today.year &&
            w.status == WorkoutStatus.completed,
      )
      .length;

  /// Monday of the week containing today.
  ///
  /// Anchoring the week to Monday keeps "4 of 8 sessions" showing the same
  /// seven days whether the app is opened on a Sunday or a Tuesday. Using the
  /// rolling last-seven-days window instead would slide the goal boundary
  /// every time the user opened the app.
  DateTime get weekStart {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    return _dayOnly(monday);
  }

  /// Sessions dated inside the current week, planned and completed alike, so a
  /// scheduled session already counts toward the weekly target.
  int get workoutsThisWeek =>
      _workouts.where((w) => !_dayOnly(w.date).isBefore(weekStart)).length;

  /// Sessions the user is aiming for each week.
  ///
  /// Lives beside the counter it is measured against so the dashboard tile and
  /// the profile setting cannot show different targets. Four is the default a
  /// lifter training four days a week would want, and it is a starting point
  /// rather than advice — the value is editable from the profile screen.
  int get weeklyGoal => _weeklyGoal;

  bool setWeeklyGoal(int value) {
    if (value < 1 || value > 14 || value == _weeklyGoal) return false;
    _weeklyGoal = value;
    notifyListeners();
    return true;
  }

  /// Share of this month's sessions actually finished, 0.0-1.0. Splits out
  /// as its own getter because the calendar and the profile both show it and
  /// should never disagree.
  double get consistency {
    final scheduled = workoutsThisMonth;
    if (scheduled == 0) return 0;
    return completedThisMonth / scheduled;
  }

  int get consistencyPercent => (consistency * 100).round();

  Metric? metricById(String id) {
    for (final metric in _metrics) {
      if (metric.id == id) return metric;
    }
    return null;
  }

  // --- Writes ----------------------------------------------------------------

  /// Adds a workout, assigning an id when the caller did not pick one, and
  /// returns the stored copy.
  ///
  /// Returns the workout rather than nothing so a caller that created it can
  /// navigate to it afterwards. The id is assigned here, so the caller has no
  /// way to know it beforehand, and looking the workout up again afterwards
  /// would have to guess at which one is new.
  Workout addWorkout(Workout workout) {
    final id = workout.id.isEmpty ? 'w${_nextId++}' : workout.id;
    final stored = workout.id.isEmpty ? workout.copyWith(id: id) : workout;
    _workouts.add(stored);
    _sort();
    notifyListeners();
    return stored;
  }

  /// Replaces the workout with the same id. Returns false when nothing
  /// matched, so callers can surface "not found" instead of silently
  /// appearing to save.
  bool updateWorkout(Workout workout) {
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index == -1) return false;
    _workouts[index] = workout;
    _sort();
    notifyListeners();
    return true;
  }

  bool deleteWorkout(String id) {
    final before = _workouts.length;
    _workouts.removeWhere((w) => w.id == id);
    final deleted = _workouts.length != before;
    if (deleted) notifyListeners();
    return deleted;
  }

  /// Flips one set and re-derives the session status.
  ///
  /// Marking the last set done completes the workout, because a user who
  /// finished every set should not have to press a second button to close
  /// the session. Un-checking it reopens the workout just as silently.
  void toggleSet(String workoutId, int logIndex, int setIndex) {
    final workout = byId(workoutId);
    if (workout == null) return;
    if (logIndex < 0 || logIndex >= workout.logs.length) return;

    final log = workout.logs[logIndex];
    if (setIndex < 0 || setIndex >= log.sets.length) return;

    final sets = List.of(log.sets);
    sets[setIndex] = sets[setIndex].copyWith(
      completed: !sets[setIndex].completed,
    );

    final logs = List.of(workout.logs);
    logs[logIndex] = log.copyWith(sets: sets);

    final allDone = logs.every((l) => l.isFinished);
    final updated = workout.copyWith(
      logs: logs,
      status: allDone ? WorkoutStatus.completed : WorkoutStatus.planned,
    );

    updateWorkout(updated);
  }

  /// Appends a set to one exercise so the user can add volume mid-session
  /// without the screen having to rebuild the whole workout itself.
  bool addSet(
    String workoutId,
    int logIndex, {
    int reps = 8,
    double weightKg = 0,
  }) {
    return _mapLogs(workoutId, (logs) {
      if (logIndex < 0 || logIndex >= logs.length) return null;
      final updated = List.of(logs);
      updated[logIndex] = updated[logIndex].copyWith(
        sets: [
          ...updated[logIndex].sets,
          WorkoutSet(reps: reps, weightKg: weightKg),
        ],
      );
      return updated;
    });
  }

  /// Removes a set. Refuses to empty an exercise entirely, because an
  /// exercise with no sets cannot report progress and would silently drop
  /// out of the volume total.
  bool removeSet(String workoutId, int logIndex, int setIndex) {
    return _mapLogs(workoutId, (logs) {
      if (logIndex < 0 || logIndex >= logs.length) return null;
      final current = logs[logIndex];
      if (current.sets.length <= 1) return null;
      if (setIndex < 0 || setIndex >= current.sets.length) return null;

      final sets = List.of(current.sets)..removeAt(setIndex);
      final updated = List.of(logs);
      updated[logIndex] = current.copyWith(sets: sets);
      return updated;
    });
  }

  bool addExercise(String workoutId, ExerciseLog log) {
    return _mapLogs(workoutId, (logs) => [...logs, log]);
  }

  bool removeExercise(String workoutId, int logIndex) {
    return _mapLogs(workoutId, (logs) {
      if (logIndex < 0 || logIndex >= logs.length) return null;
      if (logs.length <= 1) return null;
      return [...logs]..removeAt(logIndex);
    });
  }

  /// Closes a session in one action, the way a user actually finishes one.
  void completeWorkout(String id) {
    final workout = byId(id);
    if (workout == null) return;
    updateWorkout(
      workout.copyWith(
        logs: [
          for (final log in workout.logs)
            log.copyWith(
              sets: [for (final set in log.sets) set.copyWith(completed: true)],
            ),
        ],
        status: WorkoutStatus.completed,
      ),
    );
  }

  /// Reopens a session for another round.
  ///
  /// Sets are cleared rather than left ticked, so the reopened workout
  /// cannot report 100% complete the moment it exists again.
  void reopenWorkout(String id) {
    final workout = byId(id);
    if (workout == null) return;
    updateWorkout(
      workout.copyWith(
        logs: [
          for (final log in workout.logs)
            log.copyWith(
              sets: [
                for (final set in log.sets) set.copyWith(completed: false),
              ],
            ),
        ],
        status: WorkoutStatus.planned,
      ),
    );
  }

  void updateMetric(String id, double value) {
    final index = _metrics.indexWhere((m) => m.id == id);
    if (index == -1) return;
    _metrics[index] = _metrics[index].copyWith(value: value);
    notifyListeners();
  }

  /// Edits the daily goal behind a metric. Separate from the reading
  /// because a target is a preference the user sets, while the value is
  /// something the day produced.
  bool updateMetricTarget(String id, double target) {
    final index = _metrics.indexWhere((m) => m.id == id);
    if (index == -1) return false;
    _metrics[index] = _metrics[index].copyWith(target: target);
    notifyListeners();
    return true;
  }

  /// Shared plumbing for every mutation that rewrites a workout's logs.
  ///
  /// Returns null from [transform] to signal "leave it alone"; that becomes
  /// a false here so callers can tell a rejected edit from a saved one.
  bool _mapLogs(
    String workoutId,
    List<ExerciseLog>? Function(List<ExerciseLog> logs) transform,
  ) {
    final workout = byId(workoutId);
    if (workout == null) return false;
    final logs = transform(workout.logs);
    if (logs == null) return false;
    return updateWorkout(workout.copyWith(logs: logs));
  }

  void updateProfile(ProfileStats profile) {
    _profile = profile;
    notifyListeners();
  }

  void _sort() {
    _workouts.sort((a, b) => a.date.compareTo(b.date));
  }
}
