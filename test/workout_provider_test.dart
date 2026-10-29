import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/data/app_database.dart';
import 'package:plus_one/data/workout_repository.dart';
import 'package:plus_one/models/library_exercise.dart';
import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/metric.dart';
import 'package:plus_one/models/saved_exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';

import 'support/fixtures.dart';

void main() {
  // Fixed date keeps streak and consistency assertions stable regardless of
  // when the suite runs.
  final today = DateTime(2026, 10, 6);

  WorkoutProvider build() => seededProvider(today: today);

  WorkoutProvider buildWithPlan() {
    final provider = build();
    final plan = provider.focusWorkout!;
    final logs = List.of(plan.logs);
    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      logs[i] = log.copyWith(
        sets: log.sets.map((s) => s.copyWith(completed: true)).toList(),
      );
    }
    provider.updateWorkout(
      plan.copyWith(logs: logs, status: WorkoutStatus.completed),
    );
    return provider;
  }

  /// A minimal session on [date], for the questions that only care about when
  /// it is and whether it counts as training.
  Workout workoutOn(
    DateTime date, {
    String id = 'session',
    WorkoutStatus status = WorkoutStatus.planned,
  }) => Workout(
    id: id,
    title: 'Session $id',
    date: date,
    status: status,
    durationMin: 45,
    estimatedKcal: 400,
    targetMuscleGroups: const ['Chest'],
    equipment: const [],
    logs: const [],
  );

  group('reads', () {
    test('seeds a resumable plan for today', () {
      final provider = build();

      final plan = provider.focusWorkout;
      expect(plan, isNotNull);
      expect(plan!.date, today);
      expect(plan.status, WorkoutStatus.planned);
      expect(plan.totalSets, 8);
      expect(plan.completedSets, 3);
      expect(plan.setsRemaining, 5);
    });

    test('focus falls forward once today is finished', () {
      final provider = buildWithPlan();

      final focus = provider.focusWorkout;
      expect(focus, isNotNull);
      expect(focus!.date.isAfter(today), isTrue);
    });

    test('workoutsOn only returns that day sessions', () {
      final provider = build();

      expect(provider.workoutsOn(today), hasLength(1));
      expect(
        provider.workoutsOn(today.add(const Duration(days: 100))),
        isEmpty,
      );
    });

    test('byId returns null for an unknown session', () {
      expect(build().byId('nope'), isNull);
    });

    test('the week focus is today\'s plan, not one further out', () {
      final provider = build();

      final next = provider.focusWorkoutThisWeek;
      expect(next, isNotNull);
      expect(next!.id, 'upper-body');
      expect(next.date, today);
    });

    test('the week focus is null when the week has nothing left', () {
      // Three weeks out: `focusWorkout` answers "what comes next" and returns
      // it, but it is not this week's session and the library's week card -
      // labelled THIS WEEK - must not name it as one.
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          Workout(
            id: 'far',
            title: 'Session Three Weeks Out',
            date: today.add(const Duration(days: 21)),
            status: WorkoutStatus.planned,
            durationMin: 45,
            estimatedKcal: 400,
            targetMuscleGroups: const ['Chest'],
            equipment: const [],
            logs: const [],
          ),
        ],
      );

      expect(provider.focusWorkout, isNotNull);
      expect(provider.focusWorkoutThisWeek, isNull);
    });

    test('the week focus skips what is behind and what is not training', () {
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          workoutOn(
            today.add(const Duration(days: -1)),
            status: WorkoutStatus.completed,
          ),
          workoutOn(
            today.add(const Duration(days: 1)),
            status: WorkoutStatus.rest,
          ),
          workoutOn(today.add(const Duration(days: 2)), id: 'later'),
        ],
      );

      // This file's today is a Tuesday, so the week runs Monday to Sunday and
      // +1 and +2 are both inside it. The finished session and the rest day
      // are in the week too, but neither is a session to walk into.
      expect(provider.focusWorkoutThisWeek?.id, 'later');
    });

    test('the week focus is the soonest of several still to do', () {
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          workoutOn(today.add(const Duration(days: 4)), id: 'fourth'),
          workoutOn(today.add(const Duration(days: 2)), id: 'second'),
          workoutOn(today.add(const Duration(days: 3)), id: 'third'),
        ],
      );

      expect(provider.focusWorkoutThisWeek?.id, 'second');
    });

    test('the weekly goal counts finishes, not plans', () {
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          workoutOn(today, status: WorkoutStatus.completed),
          workoutOn(today.add(const Duration(days: 1)), id: 'planned'),
        ],
      );

      // Both are in the week, but only one is work the user has done. The home
      // tile, the profile target and the library's week card all read the
      // second number, so a week of plans cannot read as a week of training.
      expect(provider.workoutsInCurrentWeek, hasLength(2));
      expect(provider.sessionsDoneThisWeek, 1);
    });

    test('previous sets come from the last finished session before it', () {
      ExerciseLog logAt(double weight, {bool completed = true}) => ExerciseLog(
        exercise: const Exercise(
          name: 'Barbell Bench Press',
          equipment: 'Barbell',
          muscleGroups: ['Chest'],
        ),
        sets: [WorkoutSet(reps: 5, weightKg: weight, completed: completed)],
      );

      Workout session(
        String id,
        DateTime date,
        WorkoutStatus status,
        double weight,
      ) => Workout(
        id: id,
        title: 'Push Day',
        date: date,
        status: status,
        durationMin: 45,
        estimatedKcal: 400,
        targetMuscleGroups: const ['Chest'],
        equipment: const [],
        logs: [logAt(weight)],
      );

      final provider = WorkoutProvider(
        today: today,
        workouts: [
          session(
            'old',
            today.subtract(const Duration(days: 7)),
            WorkoutStatus.completed,
            80,
          ),
          session(
            'recent',
            today.subtract(const Duration(days: 2)),
            WorkoutStatus.completed,
            90,
          ),
          // Planned, so it is not something to beat.
          session('planned', today, WorkoutStatus.planned, 120),
        ],
      );

      final previous = provider.previousSetsFor(
        'Barbell Bench Press',
        before: today,
      );
      expect(previous, hasLength(1));
      expect(previous.single.weightKg, 90);
      expect(
        provider.previousSetsFor('Cable Fly', before: today),
        isEmpty,
        reason: 'an exercise nobody has done has nothing to compare with',
      );
    });

    test('a week of plans has nothing done', () {
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          workoutOn(today),
          workoutOn(today.add(const Duration(days: 2)), id: 'later'),
        ],
      );

      expect(provider.sessionsDoneThisWeek, 0);
    });
  });

  group('streak and consistency', () {
    test('streak continues through yesterday when today is still open', () {
      // Seeded completed days are 1, 2 and 3 days back, then a rest day.
      expect(build().streakDays, 3);
    });

    test('completing today extends the streak instead of restarting it', () {
      final provider = build();
      final plan = provider.focusWorkout!;

      // Completing today extends the run rather than restarting it.
      final logs = plan.logs
          .map(
            (l) => l.copyWith(
              sets: l.sets.map((s) => s.copyWith(completed: true)).toList(),
            ),
          )
          .toList();
      provider.updateWorkout(
        plan.copyWith(logs: logs, status: WorkoutStatus.completed),
      );

      expect(provider.streakDays, 4);
    });

    test('consistency counts finished sessions against scheduled ones', () {
      final provider = build();

      // Seed for October 2026: four finished sessions earlier this month,
      // today still open and three sessions scheduled ahead.
      expect(provider.completedThisMonth, 4);
      expect(provider.workoutsThisMonth, 8);
      expect(provider.consistencyPercent, 50);
      expect(provider.consistency, closeTo(0.5, 0.0001));
    });

    test('consistency is zero rather than NaN for an empty month', () {
      final provider = WorkoutProvider(today: today, workouts: const []);

      expect(provider.consistency, 0);
      expect(provider.consistencyPercent, 0);
      expect(provider.streakDays, 0);
    });
  });

  group('mutations', () {
    test('toggleSet flips a single set and notifies once', () {
      final provider = build();
      final plan = provider.focusWorkout!;
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleSet(plan.id, 0, 2);

      final updated = provider.byId(plan.id)!;
      expect(updated.logs[0].sets[2].completed, isTrue);
      expect(updated.completedSets, 4);
      expect(notifications, 1);
    });

    test('finishing the last set closes the workout', () {
      final provider = build();
      final plan = provider.focusWorkout!;

      for (var l = 0; l < plan.logs.length; l++) {
        final sets = plan.logs[l].sets;
        for (var s = 0; s < sets.length; s++) {
          if (!sets[s].completed) provider.toggleSet(plan.id, l, s);
        }
      }

      final done = provider.byId(plan.id)!;
      expect(done.isDone, isTrue);
      expect(done.status, WorkoutStatus.completed);
      expect(done.progress, 1.0);
    });

    test('unchecking the last set reopens the workout', () {
      final provider = build();
      final plan = provider.focusWorkout!;

      for (var l = 0; l < plan.logs.length; l++) {
        final sets = plan.logs[l].sets;
        for (var s = 0; s < sets.length; s++) {
          if (!sets[s].completed) provider.toggleSet(plan.id, l, s);
        }
      }

      final done = provider.byId(plan.id)!;
      final lastLog = done.logs.last;
      provider.toggleSet(
        done.id,
        done.logs.length - 1,
        lastLog.sets.length - 1,
      );

      final reopened = provider.byId(plan.id)!;
      expect(reopened.status, WorkoutStatus.planned);
      expect(reopened.isDone, isFalse);
    });

    test('ignores out-of-range log and set indices', () {
      final provider = build();
      final plan = provider.focusWorkout!;
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleSet(plan.id, 99, 0);
      provider.toggleSet(plan.id, 0, 99);
      provider.toggleSet('missing', 0, 0);

      expect(notifications, 0);
      expect(provider.byId(plan.id), plan);
    });

    test('addWorkout assigns an id when none is given', () {
      final provider = build();
      final before = provider.workouts.length;

      provider.addWorkout(
        Workout(
          id: '',
          title: 'New Session',
          date: today,
          status: WorkoutStatus.planned,
          durationMin: 30,
          estimatedKcal: 200,
          targetMuscleGroups: const ['Core'],
          equipment: const [],
          logs: const [],
        ),
      );

      expect(provider.workouts, hasLength(before + 1));
      expect(
        provider.workouts.firstWhere((w) => w.title == 'New Session').id,
        isNotEmpty,
      );
    });

    test('updateWorkout reports when the id does not exist', () {
      final provider = build();

      final stale = provider.focusWorkout!.copyWith(id: 'ghost');
      expect(provider.updateWorkout(stale), isFalse);
      expect(provider.byId('ghost'), isNull);
    });

    test('deleteWorkout removes only the matching session', () {
      final provider = build();
      final plan = provider.focusWorkout!;
      final before = provider.workouts.length;

      expect(provider.deleteWorkout(plan.id), isTrue);
      expect(provider.workouts, hasLength(before - 1));
      expect(provider.byId(plan.id), isNull);

      expect(provider.deleteWorkout(plan.id), isFalse);
      expect(provider.workouts, hasLength(before - 1));
    });

    test('updateMetric replaces the reading in place', () {
      final provider = build();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.updateMetric('hydration', 2.5);
      expect(provider.metricById('hydration')!.value, 2.5);

      provider.updateMetric('does-not-exist', 1);
      expect(notifications, 1);
    });

    test('updateProfile swaps the stats the profile screen renders', () {
      final provider = build();

      provider.updateProfile(provider.profile.copyWith(name: 'Sam Reyes'));

      expect(provider.profile.name, 'Sam Reyes');
      expect(provider.profile.records, isNotEmpty);
    });
  });

  group('metric helper', () {
    test('copyWith leaves the target alone', () {
      const metric = Metric(
        id: 'steps',
        label: 'Steps',
        value: 100,
        unit: 'steps',
        target: 10000,
      );

      expect(metric.copyWith(value: 250).target, 10000);
      expect(metric.copyWith(value: 250).label, 'Steps');
    });
  });

  group('saved exercises', () {
    const barbellCurl = LibraryExercise(
      name: 'Barbell Curl',
      primaryMuscles: ['biceps'],
      instructions: ['Curl the bar.'],
      equipment: ['Barbell'],
      category: 'strength',
    );
    const inclineCurl = LibraryExercise(
      name: 'Incline Dumbbell Curl',
      primaryMuscles: ['biceps'],
      instructions: ['Curl on an incline.'],
      equipment: ['Dumbbells'],
      category: 'strength',
    );

    test('starts with nothing saved', () {
      final provider = WorkoutProvider(today: today);

      expect(provider.savedExercises, isEmpty);
      expect(provider.isSaved(barbellCurl.id), isFalse);
    });

    test('keeps an exercise, then drops it', () {
      final provider = WorkoutProvider(today: today);

      provider.toggleSavedExercise(barbellCurl, at: today);
      expect(provider.isSaved(barbellCurl.id), isTrue);
      expect(provider.savedExercises.single.exercise.name, 'Barbell Curl');
      expect(provider.savedExercises.single.savedAt, today);

      provider.toggleSavedExercise(barbellCurl, at: today);
      expect(provider.isSaved(barbellCurl.id), isFalse);
      expect(provider.savedExercises, isEmpty);
    });

    test('lists the newest first', () {
      final provider = WorkoutProvider(today: today);

      provider.toggleSavedExercise(barbellCurl, at: today);
      provider.toggleSavedExercise(
        inclineCurl,
        at: today.add(const Duration(minutes: 5)),
      );

      expect(provider.savedExercises.map((saved) => saved.exercise.name), [
        'Incline Dumbbell Curl',
        'Barbell Curl',
      ]);
    });

    test('keeps the store\'s order when the times arrive out of order', () {
      final provider = WorkoutProvider(today: today);

      provider.toggleSavedExercise(inclineCurl, at: today);
      provider.toggleSavedExercise(
        barbellCurl,
        at: today.subtract(const Duration(days: 6)),
      );

      // "Newest first" is the moment it was kept, which is also the order the
      // store reads back on the next launch - not the order the buttons were
      // pressed in.
      expect(provider.savedExercises.map((saved) => saved.exercise.name), [
        'Incline Dumbbell Curl',
        'Barbell Curl',
      ]);
    });

    test('keeping the same exercise twice does not make it newly kept', () {
      final provider = WorkoutProvider(today: today);

      provider.toggleSavedExercise(barbellCurl, at: today);
      // The second call drops it rather than re-inserting, so a bookmark that
      // is on turns off instead of moving the entry to the top.
      provider.toggleSavedExercise(barbellCurl, at: today);

      expect(provider.savedExercises, isEmpty);
    });

    test('two spellings of one exercise are one entry', () {
      final provider = WorkoutProvider(today: today);

      provider.toggleSavedExercise(barbellCurl, at: today);
      provider.toggleSavedExercise(
        const LibraryExercise(
          name: 'barbell  curl',
          primaryMuscles: ['biceps'],
          instructions: ['Curl the bar.'],
          equipment: ['Barbell'],
          category: 'strength',
        ),
        at: today,
      );

      expect(provider.savedExercises, isEmpty);
    });

    test('notifies once per change', () {
      final provider = WorkoutProvider(today: today);
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleSavedExercise(barbellCurl, at: today);
      provider.toggleSavedExercise(barbellCurl, at: today);

      expect(notifications, 2);
    });

    test('an injected provider reads and writes nothing', () {
      final provider = WorkoutProvider(
        today: today,
        saved: [SavedExercise(exercise: barbellCurl, savedAt: today)],
      );

      // The constructor fixtures are the whole world without a repository.
      expect(provider.isSaved(barbellCurl.id), isTrue);
      expect(provider.savedExercises, hasLength(1));
    });
  });

  group('persistence seam', () {
    test('a store that cannot open leaves the app running in memory', () async {
      // This file never installs a sqflite factory, so opening the database
      // fails the way it would on a device whose file is unreadable. The
      // provider runs before the first frame, so it has to survive that and
      // still be usable rather than take the launch down with it.
      final provider = WorkoutProvider(
        today: today,
        repository: WorkoutRepository(AppDatabase(), userId: 'local'),
      );

      await provider.load();

      expect(provider.workouts, isEmpty);
      // Unreadable is still read: the app opens on an empty account rather
      // than on a splash that never leaves.
      expect(provider.isLoaded, isTrue);

      final stored = provider.addWorkout(
        Workout(
          id: '',
          title: 'Test Session',
          date: today,
          status: WorkoutStatus.planned,
          durationMin: 0,
          estimatedKcal: 0,
          targetMuscleGroups: const [],
          equipment: const [],
          logs: const [],
        ),
      );

      expect(provider.byId(stored.id), isNotNull);
    });
  });
}
