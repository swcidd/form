/// Demo content for the prototype.
///
/// Split out of the provider so state logic stays readable and the fixtures
/// can be swapped for API responses without touching any of it. All dates are
/// relative to "today" so the calendar and dashboard always have content
/// instead of expiring a month after the file was written.
library;

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/metric.dart';
import 'package:plus_one/models/profile_stats.dart';
import 'package:plus_one/models/workout.dart';

DateTime _onDay(DateTime today, int offset) {
  final base = DateTime(today.year, today.month, today.day);
  return base.add(Duration(days: offset));
}

Exercise _ex(String name, String equipment, List<String> muscles) =>
    Exercise(name: name, equipment: equipment, muscleGroups: muscles);

WorkoutSet _set(int reps, double weight, {bool completed = false}) =>
    WorkoutSet(reps: reps, weightKg: weight, completed: completed);

/// The session shown on the dashboard.
///
/// Three of eight sets are already marked done so the UI renders a
/// half-finished state on first launch, which is the state with the most to
/// prove: partial progress, a resumable action and a live bar.
Workout upperBodyPlan(DateTime today) {
  return Workout(
    id: 'upper-body',
    title: 'Upper Body Hypertrophy & Core',
    date: _onDay(today, 0),
    status: WorkoutStatus.planned,
    startTime: '06:00 PM',
    place: 'Strength Studio B',
    durationMin: 45,
    estimatedKcal: 420,
    targetMuscleGroups: const ['Chest', 'Shoulders', 'Triceps'],
    equipment: const ['Dumbbells (10-20kg)', 'Adjustable Bench'],
    logs: [
      ExerciseLog(
        exercise: _ex('Barbell Bench Press', 'Barbell', const ['Chest']),
        sets: [
          _set(8, 60, completed: true),
          _set(8, 60, completed: true),
          _set(8, 65),
          _set(6, 65),
        ],
      ),
      ExerciseLog(
        exercise: _ex('Incline Chest Fly', 'Dumbbells', const ['Chest']),
        sets: [_set(12, 14, completed: true), _set(12, 14)],
      ),
      ExerciseLog(
        exercise: _ex('Cable Tricep Pushdown', 'Cable', const ['Triceps']),
        sets: [_set(12, 25)],
      ),
      ExerciseLog(
        exercise: _ex('Hanging Leg Raise', 'Bodyweight', const ['Core']),
        sets: [_set(15, 0)],
      ),
    ],
  );
}

Workout _emptyLogWorkout({
  required String id,
  required String title,
  required DateTime date,
  required WorkoutStatus status,
  required String startTime,
  required String place,
  required int durationMin,
  required int estimatedKcal,
  required List<String> targetMuscleGroups,
  List<ExerciseLog> logs = const [],
}) {
  return Workout(
    id: id,
    title: title,
    date: date,
    status: status,
    startTime: startTime,
    place: place,
    durationMin: durationMin,
    estimatedKcal: estimatedKcal,
    targetMuscleGroups: targetMuscleGroups,
    equipment: const [],
    logs: logs,
  );
}

/// The exercises a session of each kind actually holds.
///
/// Fixtures read like a training log rather than "Push Day Movement 4", which
/// matters in the two places these sessions are looked at by eye: a screenshot
/// and a demo. Sessions longer than the list cycle through it.
const _exercisesFor = <String, List<String>>{
  'Push Day': [
    'Barbell Bench Press',
    'Incline Dumbbell Press',
    'Seated Cable Fly',
    'Overhead Press',
    'Lateral Raise',
    'Triceps Pushdown',
    'Dips',
    'Cable Crunch',
  ],
  'Pull Day': [
    'Deadlift',
    'Pull-Up',
    'Barbell Row',
    'Seated Cable Row',
    'Face Pull',
    'Barbell Curl',
    'Hammer Curl',
    'Barbell Shrug',
    'Hanging Leg Raise',
  ],
  'Leg Day': [
    'Barbell Back Squat',
    'Romanian Deadlift',
    'Leg Press',
    'Walking Lunge',
    'Leg Extension',
    'Leg Curl',
    'Standing Calf Raise',
    'Hip Thrust',
    'Ab Wheel Rollout',
    'Back Extension',
  ],
  'HIIT Cardio': [
    'Assault Bike Sprint',
    'Kettlebell Swing',
    'Burpee',
    'Box Jump',
  ],
  'Lower Body & Mobility': [
    'Goblet Squat',
    'Glute Bridge',
    'Hip Hinge Drill',
    'Cossack Squat',
    'Bulgarian Split Squat',
    'Bird Dog',
    'Side Plank',
    'Hamstring Stretch',
  ],
};

/// Rotating completed sessions behind the calendar.
///
/// Counts are drawn from real training patterns rather than round numbers so
/// the streak and consistency figures the provider computes look like
/// somebody's actual month.
List<Workout> pastSessions(DateTime today) {
  final template = <({String title, List<String> muscles, int kcal, int sets})>[
    (title: 'Push Day', muscles: ['Chest', 'Shoulders'], kcal: 380, sets: 8),
    (title: 'Pull Day', muscles: ['Back', 'Biceps'], kcal: 360, sets: 9),
    (title: 'Leg Day', muscles: ['Quads', 'Hamstrings'], kcal: 440, sets: 10),
    (title: 'HIIT Cardio', muscles: ['Full Body'], kcal: 310, sets: 4),
    (
      title: 'Lower Body & Mobility',
      muscles: ['Glutes', 'Core'],
      kcal: 400,
      sets: 8,
    ),
  ];

  const places = ['Strength Studio B', 'Outdoor Track', 'Main Gym Floor'];

  // Days back from today that hold a finished session. The gap days are rest
  // days, which is what makes the consistency figure below non-trivial.
  const completedOffsets = [
    1,
    2,
    3,
    5,
    6,
    7,
    8,
    10,
    11,
    12,
    13,
    15,
    16,
    17,
    19,
  ];

  final sessions = <Workout>[];
  for (var i = 0; i < completedOffsets.length; i++) {
    final spec = template[i % template.length];
    final day = _onDay(today, -completedOffsets[i]);
    sessions.add(
      _emptyLogWorkout(
        id: 'past-$i',
        title: spec.title,
        date: day,
        status: WorkoutStatus.completed,
        startTime: i.isEven ? '07:15 AM' : '06:00 PM',
        place: places[i % places.length],
        durationMin: 30 + (i % 4) * 5,
        estimatedKcal: spec.kcal,
        targetMuscleGroups: spec.muscles,
        logs: [
          for (var s = 0; s < spec.sets; s++)
            ExerciseLog(
              exercise: _ex(
                _exercisesFor[spec.title]![s %
                    _exercisesFor[spec.title]!.length],
                'Barbell',
                spec.muscles,
              ),
              sets: [_set(10, 40, completed: true)],
            ),
        ],
      ),
    );
  }
  return sessions;
}

/// Sessions scheduled after today, so the calendar has a future to plan into.
List<Workout> futureSessions(DateTime today) {
  return [
    _emptyLogWorkout(
      id: 'future-legs',
      title: 'Leg Day & Mobility',
      date: _onDay(today, 2),
      status: WorkoutStatus.planned,
      startTime: '06:00 PM',
      place: 'Strength Studio B',
      durationMin: 45,
      estimatedKcal: 400,
      targetMuscleGroups: const ['Quads', 'Hamstrings'],
    ),
    _emptyLogWorkout(
      id: 'future-hiit',
      title: 'HIIT Cardio',
      date: _onDay(today, 4),
      status: WorkoutStatus.planned,
      startTime: '07:15 AM',
      place: 'Outdoor Track',
      durationMin: 32,
      estimatedKcal: 310,
      targetMuscleGroups: const ['Full Body'],
    ),
    _emptyLogWorkout(
      id: 'future-rest',
      title: 'Rest & Recovery Log',
      date: _onDay(today, 5),
      status: WorkoutStatus.rest,
      startTime: '10:30 PM',
      place: '',
      durationMin: 15,
      estimatedKcal: 0,
      targetMuscleGroups: const [],
    ),
  ];
}

List<Workout> seedWorkouts(DateTime today) => [
  upperBodyPlan(today),
  ...pastSessions(today),
  ...futureSessions(today),
];

/// Daily readings.
///
/// These describe what the body did, which a workout log cannot know, so
/// they are seeded as editable state rather than derived from sessions.
List<Metric> seedMetrics() => const [
  Metric(
    id: 'calories',
    label: 'Calories',
    value: 640,
    unit: 'kcal',
    target: 800,
  ),
  Metric(
    id: 'active-minutes',
    label: 'Active Time',
    value: 45,
    unit: 'min',
    target: 60,
  ),
  Metric(
    id: 'steps',
    label: 'Steps',
    value: 8420,
    unit: 'steps',
    target: 10000,
  ),
  Metric(id: 'heart-rate', label: 'Heart Rate', value: 72, unit: 'bpm'),
  Metric(id: 'hydration', label: 'Hydration', value: 2.1, unit: 'L', target: 3),
  Metric(id: 'sleep', label: 'Sleep Score', value: 84, unit: '/100'),
  Metric(id: 'distance', label: 'Distance', value: 6.2, unit: 'km'),
];

ProfileStats seedProfile() => const ProfileStats(
  name: 'Alex Mercer',
  handle: '@alex_lift92',
  role: 'Athlete',
  memberSince: 'Jan 2023',
  isPro: true,
  weightKg: 74.5,
  heightCm: 182,
  bodyFatPct: 14.2,
  restingHrBpm: 56,
  totalWorkouts: 248,
  totalKcal: 94500,
  totalHours: 210,
  streakDays: 14,
  badgeCount: 18,
  records: [
    PersonalRecord(
      id: 'BP',
      category: 'BP',
      name: 'Bench Press',
      protocol: '1RM · Chest Day Protocol',
      value: '100',
      unit: 'kg',
    ),
    PersonalRecord(
      id: '5K',
      category: '5K',
      name: '5k Outdoor Run',
      protocol: 'Pace 4:30/km · Track',
      value: '22:45',
      unit: 'min',
    ),
    PersonalRecord(
      id: 'DL',
      category: 'DL',
      name: 'Deadlift',
      protocol: 'Conventional Stance',
      value: '140',
      unit: 'kg',
    ),
  ],
  achievements: [
    Achievement(
      id: 'runner',
      title: '10K Runner',
      subtitle: 'Level III',
      detail: 'Endurance',
    ),
    Achievement(
      id: 'consistency',
      title: 'Consistency',
      subtitle: '30-Day Streak',
      detail: 'Discipline',
    ),
    Achievement(
      id: 'lifter',
      title: 'Heavy Lifter',
      subtitle: '180kg Pull',
      detail: 'Strength',
    ),
  ],
);
