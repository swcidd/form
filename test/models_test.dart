import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/metric.dart';
import 'package:plus_one/models/profile_stats.dart';
import 'package:plus_one/models/workout.dart';

ExerciseLog _log(String name, List<WorkoutSet> sets) => ExerciseLog(
  exercise: Exercise(
    name: name,
    equipment: 'Barbell',
    muscleGroups: const ['Chest'],
  ),
  sets: sets,
);

Workout _workout() => Workout(
  id: 'w1',
  title: 'Upper Body',
  date: DateTime(2026, 10, 6),
  status: WorkoutStatus.planned,
  startTime: '07:15 AM',
  place: 'Outdoor Track',
  durationMin: 45,
  estimatedKcal: 420,
  targetMuscleGroups: const ['Chest', 'Shoulders'],
  equipment: const ['Barbell', 'Dumbbells'],
  logs: [
    _log('Barbell Bench Press', const [
      WorkoutSet(reps: 8, weightKg: 60),
      WorkoutSet(reps: 8, weightKg: 60, completed: true),
    ]),
    _log('Incline Chest Fly', const [WorkoutSet(reps: 12, weightKg: 14)]),
  ],
);

void main() {
  group('Workout', () {
    test('progress counts completed sets, not finished exercises', () {
      final workout = _workout();

      expect(workout.totalSets, 3);
      expect(workout.completedSets, 1);
      expect(workout.setsRemaining, 2);
      expect(workout.progress, closeTo(1 / 3, 0.0001));
      expect(workout.isDone, isFalse);
    });

    test('progress stays zero for a rest day with no sets', () {
      final rest = _workout().copyWith(status: WorkoutStatus.rest, logs: []);

      expect(rest.progress, 0);
      expect(rest.isDone, isFalse);
    });

    test('copyWith keeps fields it was not asked to change', () {
      final workout = _workout();
      final renamed = workout.copyWith(title: 'Push Day');

      expect(renamed.title, 'Push Day');
      expect(renamed.startTime, workout.startTime);
      expect(renamed.place, workout.place);
      expect(renamed.estimatedKcal, workout.estimatedKcal);
      expect(renamed.logs, workout.logs);
    });

    test('JSON round trip preserves every field', () {
      final workout = _workout();
      final restored = Workout.fromJson(
        Map<String, dynamic>.from(workout.toJson()),
      );

      expect(restored, workout);
      expect(restored.date, workout.date);
      expect(restored.status, WorkoutStatus.planned);
    });
  });

  group('ExerciseLog', () {
    test('volume ignores sets the user has not marked done', () {
      final log = _log('Bench Press', const [
        WorkoutSet(reps: 8, weightKg: 60),
        WorkoutSet(reps: 8, weightKg: 60, completed: true),
        WorkoutSet(reps: 6, weightKg: 65, completed: true),
      ]);

      expect(log.volume, closeTo(8 * 60 + 6 * 65, 0.0001));
      expect(log.isFinished, isFalse);

      final finished = log.copyWith(
        sets: log.sets.map((s) => s.copyWith(completed: true)).toList(),
      );
      expect(finished.isFinished, isTrue);
    });

    test('slug is safe to use as a route argument', () {
      const exercise = Exercise(
        name: 'Cable Tricep Pushdown',
        equipment: 'Cable',
        muscleGroups: ['Triceps'],
      );

      expect(exercise.slug, 'cable-tricep-pushdown');
      expect(exercise.slug.contains(' '), isFalse);
    });
  });

  group('Metric', () {
    test('clamps progress when the reading overshoots the target', () {
      const metric = Metric(
        id: 'hydration',
        label: 'Hydration',
        value: 3.5,
        unit: 'L',
        target: 3,
      );

      expect(metric.progress, 1.0);
      expect(metric.hasTarget, isTrue);
    });

    test('omits the bar for figures with no target', () {
      const metric = Metric(
        id: 'heart-rate',
        label: 'Heart Rate',
        value: 72,
        unit: 'bpm',
      );

      expect(metric.hasTarget, isFalse);
      expect(metric.progress, 0);
      expect(metric.displayAbsolute, '72 bpm');
    });

    test('trims trailing zeros from display values', () {
      const calories = Metric(
        id: 'calories',
        label: 'Calories',
        value: 640,
        unit: 'kcal',
        target: 800,
      );

      expect(calories.displayValue, '640');
      expect(calories.displayRange, 'of 800 kcal');
      expect(calories.displayAbsolute, '640/800 kcal');

      const hydration = Metric(
        id: 'hydration',
        label: 'Hydration',
        value: 2.1,
        unit: 'L',
        target: 3,
      );
      expect(hydration.displayValue, '2.1');
      expect(hydration.displayAbsolute, '2.1/3 L');
    });

    test('abbreviates totals from five digits up', () {
      const lifetime = Metric(
        id: 'energy',
        label: 'Total Energy',
        value: 94500,
        unit: 'kcal',
      );
      expect(lifetime.displayValue, '94.5K');

      const round = Metric(
        id: 'steps',
        label: 'Steps',
        value: 10000,
        unit: 'steps',
      );
      expect(round.displayValue, '10K');

      const daily = Metric(
        id: 'steps',
        label: 'Steps',
        value: 8420,
        unit: 'steps',
        target: 10000,
      );
      expect(daily.displayValue, '8420');
      expect(daily.displayAbsolute, '8420/10K steps');
    });
  });

  group('ProfileStats', () {
    test('copyWith does not reset untouched totals', () {
      final stats = ProfileStats.fromJson(_statsJson());
      final renamed = stats.copyWith(name: 'Sam Reyes');

      expect(renamed.name, 'Sam Reyes');
      expect(renamed.totalKcal, stats.totalKcal);
      expect(renamed.records, stats.records);
    });

    test('JSON round trip preserves nested records and badges', () {
      final stats = ProfileStats.fromJson(_statsJson());
      final restored = ProfileStats.fromJson(stats.toJson());

      expect(restored, stats);
      expect(restored.heightImperial, isTrue);
      expect(restored.weightImperial, isTrue);
      expect(restored.records, hasLength(3));
      expect(restored.achievements, hasLength(3));
    });
  });
}

Map<String, dynamic> _statsJson() => {
  'name': 'Alex Mercer',
  'handle': '@alex_lift92',
  'role': 'Athlete',
  'memberSince': 'Jan 2023',
  'isPro': true,
  'weightKg': 74.5,
  'heightCm': 182,
  'heightImperial': true,
  'weightImperial': true,
  'bodyFatPct': 14.2,
  'restingHrBpm': 56,
  'totalWorkouts': 248,
  'totalKcal': 94500,
  'totalHours': 210,
  'streakDays': 14,
  'badgeCount': 18,
  'records': [
    {
      'id': 'BP',
      'category': 'BP',
      'name': 'Bench Press',
      'protocol': '1RM · Chest Day Protocol',
      'value': '100',
      'unit': 'kg',
    },
    {
      'id': '5K',
      'category': '5K',
      'name': '5k Outdoor Run',
      'protocol': 'Pace 4:30/km · Track',
      'value': '22:45',
      'unit': 'min',
    },
    {
      'id': 'DL',
      'category': 'DL',
      'name': 'Deadlift',
      'protocol': 'Conventional Stance',
      'value': '140',
      'unit': 'kg',
    },
  ],
  'achievements': [
    {
      'id': 'runner',
      'title': '10K Runner',
      'subtitle': 'Level III',
      'detail': 'Endurance',
    },
    {
      'id': 'consistency',
      'title': 'Consistency',
      'subtitle': '30-Day Streak',
      'detail': 'Discipline',
    },
    {
      'id': 'lifter',
      'title': 'Heavy Lifter',
      'subtitle': '180kg Pull',
      'detail': 'Strength',
    },
  ],
};
