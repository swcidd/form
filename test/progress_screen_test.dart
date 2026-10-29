import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/progress_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/harness.dart';

/// A fixed "today" so the screen's period windows and history are stable.
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

/// A tall surface lays the whole screen out so lower sections can be reached.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

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

    expect(find.text('NO PROGRESS TO SHOW YET.'), findsOneWidget);
    expect(find.text('ESTIMATED 1-REP MAX'), findsNothing);
    expect(find.text('SESSIONS'), findsNothing);

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

  testWidgets('a finished session shows up in the strength card', (
    tester,
  ) async {
    _useTallSurface(tester);
    await tester.pumpWidget(_app(_oneSession()));
    await tester.pumpAndSettle();

    // 100 kg for 5 reps is an estimated 117 kg single.
    expect(find.text('ESTIMATED 1-REP MAX'), findsOneWidget);
    expect(find.text('117'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);

    expect(find.text('SESSIONS'), findsOneWidget);
    expect(find.text('KG LIFTED'), findsOneWidget);
    expect(find.text('NEW RECORDS'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);

    // The finished session is in the history, with its own volume.
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.textContaining('45 min'), findsOneWidget);
    expect(find.textContaining('500 kg'), findsOneWidget);
  });

  testWidgets('one session has no trend arrow yet', (tester) async {
    await tester.pumpWidget(_app(_oneSession()));
    await tester.pumpAndSettle();

    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('two sessions produce a direction, not a fake comparison', (
    tester,
  ) async {
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
        date: _daysAgo(20),
        logs: [
          _log('Bench Press', [_set(5, 90)]),
        ],
      ),
    ]);

    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    // 117 kg against 105 kg is +11.1% on the estimated single.
    expect(find.text('+11.1% ↗'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
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

    expect(find.text('NO PROGRESS TO SHOW YET.'), findsOneWidget);
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
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Pull Up'), findsNothing);
  });
}
