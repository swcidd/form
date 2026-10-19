import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/workout_repository.dart';
import '../exercise_library.dart';
import '../models/exercise.dart';
import '../models/metric.dart';
import '../models/profile_stats.dart';
import '../models/saved_exercise.dart';
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
///
/// With a [repository] the memory copy becomes a cache: [load] fills it from
/// the store before the first frame and every mutation that touches a workout
/// writes it back, so a restart shows the same account. Without one - the
/// default in tests and in an injected app - nothing is read or written and
/// the constructor fixtures are the whole world. Weekly goal and metrics stay
/// in memory either way; the schema has no column for them yet. Saved exercises
/// are kept too, because the wger page they came from is one request away.
class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider({
    DateTime? today,
    List<Workout>? workouts,
    List<Metric>? metrics,
    List<SavedExercise>? saved,
    ProfileStats? profile,
    this.repository,
  }) : _today = _dayOnly(today ?? DateTime.now()),
       // Copies are deliberate: callers often hand over const or
       // unmodifiable fixtures, and this class has to stay free to reorder
       // and replace entries in place.
       _workouts = List.of(workouts ?? const []),
       _metrics = List.of(metrics ?? const []),
       _saved = List.of(saved ?? const []),
       _profile = profile ?? ProfileStats.empty() {
    _sort();
  }

  final DateTime _today;
  final List<Workout> _workouts;
  final List<Metric> _metrics;
  final List<SavedExercise> _saved;
  ProfileStats _profile;

  /// The durable copy, or null when this provider is memory-only.
  final WorkoutRepository? repository;
  int _nextId = 0;
  int _weeklyGoal = 4;
  bool _loaded = false;

  /// Whether this provider's copy of the account is complete.
  ///
  /// False from construction until [load] has finished, which is what the gate
  /// holds the app window on: a store that has not read yet reads as an empty
  /// account, and showing it would put a true-looking "0 sessions this week" in
  /// front of somebody who has twenty.
  ///
  /// True from the start without a [repository]: with nothing to read there is
  /// nothing to wait for, and a provider a test handed fixtures means them to be
  /// the account.
  bool get isLoaded => repository == null || _loaded;

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // --- Persistence -----------------------------------------------------------

  /// Fills the in-memory copy from the store.
  ///
  /// A no-op without a repository, so an injected provider stays exactly the
  /// fixtures the caller passed. Failures are logged and swallowed: a device
  /// that cannot open its database should still show a working, empty app
  /// rather than crash on launch.
  Future<void> load() async {
    final store = repository;
    if (store == null) return;

    try {
      final stored = await store.loadWorkouts();
      final profile = await store.loadProfile();

      _workouts
        ..clear()
        ..addAll(stored);
      _sort();
      if (profile != null) _profile = profile;
      _saved
        ..clear()
        ..addAll(await store.loadSavedExercises());
      _advanceNextId();
    } catch (error) {
      debugPrint('Could not read the store, starting empty: $error');
    }

    // Loaded either way, and on purpose. A store that could not be read is an
    // empty account rather than an app that never opens - the same reason the
    // failure above is swallowed instead of thrown.
    _loaded = true;
    notifyListeners();
  }

  /// Moves the id counter past anything the store already handed out, so a
  /// session added after a restart cannot reuse an id the calendar is showing.
  void _advanceNextId() {
    for (final workout in _workouts) {
      final match = RegExp(r'^w(\d+)$').firstMatch(workout.id);
      if (match == null) continue;
      final value = int.parse(match.group(1)!);
      if (value >= _nextId) _nextId = value + 1;
    }
  }

  /// Writes one workout through, deliberately not awaited.
  ///
  /// The UI has already been told the mutation happened; blocking the tap on a
  /// disk round trip would make set ticks stutter for no visible gain. A failed
  /// write is logged rather than thrown, because there is no recovery the user
  /// could act on mid-session.
  Future<void> _persistWorkout(Workout workout) async {
    try {
      await repository?.replaceWorkout(workout);
    } catch (error) {
      debugPrint('Could not save ${workout.id}: $error');
    }
  }

  Future<void> _persistDelete(String id) async {
    try {
      await repository?.deleteWorkout(id);
    } catch (error) {
      debugPrint('Could not delete $id: $error');
    }
  }

  Future<void> _persistProfile(ProfileStats profile) async {
    try {
      await repository?.saveProfile(profile);
    } catch (error) {
      debugPrint('Could not save the profile: $error');
    }
  }

  Future<void> _persistSavedExercise(SavedExercise saved) async {
    try {
      await repository?.saveSavedExercise(saved);
    } catch (error) {
      debugPrint('Could not save the exercise: $error');
    }
  }

  Future<void> _forgetSavedExercise(String id) async {
    try {
      await repository?.deleteSavedExercise(id);
    } catch (error) {
      debugPrint('Could not forget the exercise: $error');
    }
  }

  // --- Reads -----------------------------------------------------------------

  DateTime get today => _today;

  List<Workout> get workouts => List.unmodifiable(_workouts);

  List<Metric> get metrics => List.unmodifiable(_metrics);

  /// Exercises the user kept, newest first.
  List<SavedExercise> get savedExercises => List.unmodifiable(_saved);

  bool isSaved(String exerciseId) =>
      _saved.any((saved) => saved.id == exerciseId);

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

  bool _hasCompletedOn(DateTime date) =>
      workoutsOn(date)
          .any((workout) => workout.status == WorkoutStatus.completed);

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

  /// Sessions dated inside the current week, planned and completed alike,
  /// because the library lists the week and needs the next one still to do.
  ///
  /// This is not the number the weekly goal is measured against - that is
  /// [sessionsDoneThisWeek].
  ///
  /// Bounded at both ends: the window is the seven days from [weekStart], not
  /// "Monday and everything after". Without the upper bound a plan made for
  /// next month counts toward this week, which would report training nobody
  /// has done yet as progress against the goal.
  ///
  /// Exposed as the list rather than only as a count because the library shows
  /// the week's sessions and the dashboard counts them: two definitions of
  /// where the week starts is how the tile and the list end up disagreeing.
  List<Workout> get workoutsInCurrentWeek {
    final end = weekStart.add(const Duration(days: 7));
    return [
      for (final workout in _workouts)
        if (!_dayOnly(workout.date).isBefore(weekStart) &&
            _dayOnly(workout.date).isBefore(end))
          workout,
    ];
  }

  /// The session being walked into, inside the current week.
  ///
  /// [focusWorkout] answers "what comes next" across the whole account, which
  /// is a different question: a plan three weeks out is not this week's work,
  /// and a panel labelled with the week must not name it as if it were. The
  /// window rule stays here, next to the list it bounds, so the two cannot
  /// drift. Null means the week has nothing left to do.
  Workout? get focusWorkoutThisWeek {
    for (final workout in workoutsInCurrentWeek) {
      if (workout.status != WorkoutStatus.planned) continue;
      if (_dayOnly(workout.date).isBefore(_today)) continue;
      return workout;
    }
    // The list arrives in date order, so the first match is the soonest.
    return null;
  }

  /// How many of the week's sessions are finished.
  ///
  /// The number the weekly goal is measured against, and the only one that means
  /// progress: a session still sitting on the calendar is work the user has not
  /// done. Every screen counting toward the goal reads this one, so the home
  /// tile, the profile's target and the library's week card cannot disagree.
  /// They did: the tile counted plans and the card counted finishes, so a week
  /// holding four plans and no training read "4/4" on one screen and "0 of 4"
  /// on another.
  int get sessionsDoneThisWeek => workoutsInCurrentWeek
      .where((workout) => workout.status == WorkoutStatus.completed)
      .length;

  /// The sets the user logged for [exercise] the last time they trained it.
  ///
  /// Only finished sessions count, and only those before [before]: the logging
  /// screen compares the session in front of it with the work that came before
  /// it, not with itself. Only completed sets are returned, because a set that
  /// was planned and never done is not a number to beat.
  ///
  /// Empty means the exercise is new, which is a different sentence on screen
  /// from a previous weight of zero.
  List<WorkoutSet> previousSetsFor(
    String exercise, {
    required DateTime before,
  }) {
    final key = LibraryExercise.keyFor(exercise);
    final cutoff = _dayOnly(before);
    ExerciseLog? latest;
    var latestDay = cutoff;

    for (final workout in _workouts) {
      if (workout.status != WorkoutStatus.completed) continue;
      final day = _dayOnly(workout.date);
      if (!day.isBefore(cutoff)) continue;
      if (latest != null && !day.isAfter(latestDay)) continue;
      for (final log in workout.logs) {
        if (LibraryExercise.keyFor(log.exercise.name) != key) continue;
        final done = log.sets.where((set) => set.completed).toList();
        if (done.isEmpty) continue;
        latest = log;
        latestDay = day;
      }
    }

    return latest?.sets.where((set) => set.completed).toList() ?? const [];
  }

  /// Sessions the user is aiming for each week.
  ///
  /// Lives beside the counter it is measured against so the dashboard tile and
  /// the profile setting cannot show different targets. Four is the default a
  /// lifter training four days a week would want, and it is a starting point
  /// rather than advice — the value is editable from the profile screen.
  int get weeklyGoal => _weeklyGoal;

  /// Accepted range for [setWeeklyGoal], exposed so the control that edits it
  /// cannot offer a step this store will refuse.
  static const int weeklyGoalMin = 1;
  static const int weeklyGoalMax = 14;

  bool setWeeklyGoal(int value) {
    if (value < weeklyGoalMin ||
        value > weeklyGoalMax ||
        value == _weeklyGoal) {
      return false;
    }
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

  /// Keeps [exercise] in the saved list, or drops it if it is already there.
  ///
  /// One verb because the UI has one control: a bookmark that is either on or
  /// off. An entry already kept drops rather than re-inserting, which keeps the
  /// order honest - "newest first" is the order things were kept, and keeping
  /// something again does not make it newly kept.
  void toggleSavedExercise(LibraryExercise exercise, {DateTime? at}) {
    final existing = _saved.indexWhere((saved) => saved.id == exercise.id);
    if (existing >= 0) {
      final entry = _saved.removeAt(existing);
      unawaited(_forgetSavedExercise(entry.id));
      notifyListeners();
      return;
    }

    final entry = SavedExercise(
      exercise: exercise,
      savedAt: at ?? DateTime.now(),
    );
    // Kept in the store's own order - the moment it was kept, newest first -
    // so the list cannot reorder itself across a restart when a caller hands
    // over a time rather than letting the clock be the clock.
    final position = _saved.indexWhere(
      (saved) => !saved.savedAt.isAfter(entry.savedAt),
    );
    _saved.insert(position < 0 ? _saved.length : position, entry);
    unawaited(_persistSavedExercise(entry));
    notifyListeners();
  }

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
    unawaited(_persistWorkout(stored));
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
    unawaited(_persistWorkout(workout));
    notifyListeners();
    return true;
  }

  bool deleteWorkout(String id) {
    final before = _workouts.length;
    _workouts.removeWhere((w) => w.id == id);
    final deleted = _workouts.length != before;
    if (deleted) {
      unawaited(_persistDelete(id));
      notifyListeners();
    }
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
    unawaited(_persistProfile(profile));
    notifyListeners();
  }

  void _sort() {
    _workouts.sort((a, b) => a.date.compareTo(b.date));
  }
}
