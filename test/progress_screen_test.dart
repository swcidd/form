import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/progress_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/harness.dart';

/// A fixed "today" for the same reason the fixtures take one: the screen
/// windows its figures by date, so the assertions need a fixed calendar.
final _today = DateTime(2026, 10, 17);

DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

Widget _app(WorkoutProvider provider) =>
    ChangeNotifierProvider<WorkoutProvider>.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light(), home: const ProgressScreen()),
    );

WorkoutSet _set(int reps, double kg) =>
    WorkoutSet(reps: reps, weightKg: kg, completed: true);

ExerciseLog _log(String name, List<WorkoutSet> sets, {double kg = 0}) =>
    ExerciseLog(
      exercise: Exercise(
        name: name,
        equipment: kg == 0 ? 'Bodyweight' : 'Barbell',
        muscleGroups: const ['Chest'],
      ),
      sets: sets,
    );

Workout _session({
  required String id,
  required DateTime date,
  required List<ExerciseLog> logs,
  WorkoutStatus status = WorkoutStatus.completed,
}) => Workout(
  id: id,
  title: 'Push Day',
  date: date,
  status: status,
  durationMin: 45,
  estimatedKcal: 300,
  targetMuscleGroups: const ['Chest'],
  equipment: const ['Barbell'],
  logs: logs,
);

WorkoutProvider _provider(List<Workout> workouts) =>
    WorkoutProvider(today: _today, workouts: workouts);

/// The records list sits below three cards, which a phone-sized surface never
/// gets to: a `ListView` only builds what fits. A tall surface lays the whole
/// screen out so the lower sections can be asserted on.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// One finished session of bench press: 5 reps at 100 kg.
WorkoutProvider _oneSession() => _provider([
  _session(
    id: 'a',
    date: _daysAgo(10),
    logs: [
      _log('Bench Press', [_set(5, 100)]),
    ],
  ),
]);

void main() {
  setUpAll(useOfflineFonts);

  testWidgets('an empty account reads as empty, not as a scoreboard', (
    tester,
  ) async {
    await tester.pumpWidget(_app(WorkoutProvider(today: _today)));
    await tester.pumpAndSettle();

    expect(find.text('No progress to show yet'), findsOneWidget);
    expect(find.text('Estimated 1RM'), findsNothing);
    expect(find.text('Frequency'), findsNothing);

    // The figures the screen used to print for every account regardless of
    // what was in the log.
    for (final ghost in [
      '102.5 kg',
      '48,200 kg',
      'Oct 5, 2024',
      'Sep 28, 2024',
      'Oct 12, 2024',
    ]) {
      expect(find.textContaining(ghost), findsNothing, reason: ghost);
    }
  });

  testWidgets('a finished session shows up in the headline numbers', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(_app(_oneSession()));
    await tester.pumpAndSettle();

    // 100 kg for 5 reps is an estimated 117 kg single.
    expect(find.text('Estimated 1RM'), findsOneWidget);
    expect(find.text('117 kg'), findsOneWidget);
    // Once as the exercise the estimate belongs to, once in the record list.
    expect(find.text('Bench Press'), findsNWidgets(2));

    expect(find.text('Volume (30 days)'), findsOneWidget);
    expect(find.text('500 kg'), findsOneWidget);

    expect(find.text('Frequency'), findsOneWidget);
    expect(find.text('0.3'), findsOneWidget);
    expect(find.textContaining('Target:'), findsOneWidget);

    // The set that earned the record, on the day it was logged.
    expect(find.text('100 kg × 5'), findsOneWidget);
    expect(find.text(DateFormat('MMM d').format(_daysAgo(10))), findsOneWidget);
  });

  testWidgets('no comparison is printed without an earlier window', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_oneSession()));
    await tester.pumpAndSettle();

    // Nothing was lifted in the 30 days before this one, so there is no
    // baseline - the card says the volume and stops.
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('volume is compared with the window before it', (tester) async {
    final provider = _provider([
      _session(
        id: 'recent',
        date: _daysAgo(10),
        logs: [
          _log('Bench Press', [_set(5, 100)]),
        ],
      ),
      _session(
        id: 'older',
        date: _daysAgo(40),
        logs: [
          _log('Bench Press', [_set(5, 90)]),
        ],
      ),
    ]);

    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('+11%'), findsOneWidget);
    expect(find.text('500 kg'), findsOneWidget);
  });

  testWidgets('a plan that was never finished does not count', (tester) async {
    final provider = _provider([
      _session(
        id: 'plan',
        date: _today,
        status: WorkoutStatus.planned,
        logs: [
          _log('Bench Press', [_set(5, 200)]),
        ],
      ),
    ]);

    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    expect(find.text('No progress to show yet'), findsOneWidget);
    expect(find.textContaining('200'), findsNothing);
  });

  testWidgets('bodyweight work is not ranked as a record', (tester) async {
    _useTallSurface(tester);
    final provider = _provider([
      _session(
        id: 'a',
        date: _daysAgo(3),
        logs: [
          _log('Pull Up', [_set(8, 0)], kg: 0),
          _log('Bench Press', [_set(5, 60)]),
        ],
      ),
    ]);

    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    // The bodyweight set is not offered as a record; the weighted one is.
    expect(find.text('Bench Press'), findsNWidgets(2));
    expect(find.text('Pull Up'), findsNothing);
  });
}
