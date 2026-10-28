import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/set_logging_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/harness.dart';

/// Fixed rather than `DateTime.now()` so nothing under test depends on the day
/// the suite happens to run.
final _date = DateTime(2026, 10, 26);

WorkoutSet _set(int reps, double weight, {bool completed = false}) =>
    WorkoutSet(reps: reps, weightKg: weight, completed: completed);

ExerciseLog _log(String name, List<WorkoutSet> sets, {int restSeconds = 120}) =>
    ExerciseLog(
      exercise: Exercise(
        name: name,
        equipment: 'Barbell',
        muscleGroups: const ['Legs'],
      ),
      sets: sets,
      restSeconds: restSeconds,
    );

/// One exercise with the first set done and the second still to log, which is
/// the state the rest timer and the entry panel both hang off.
Workout _squatSession({List<ExerciseLog>? logs}) => Workout(
  id: 'w1',
  title: 'Lower Body A',
  date: _date,
  status: WorkoutStatus.planned,
  durationMin: 45,
  estimatedKcal: 300,
  targetMuscleGroups: const ['Legs'],
  equipment: const ['Barbell'],
  logs:
      logs ??
      [
        _log('Barbell Back Squat', [
          _set(8, 40, completed: true),
          _set(11, 72.5),
        ]),
      ],
);

WorkoutProvider _provider({List<Workout>? workouts}) =>
    WorkoutProvider(today: _date, workouts: workouts ?? [_squatSession()]);

/// Mounts the screen directly, at the Figma frame's size.
///
/// The default test window is wider and shorter than a phone, which would hide
/// the vertical budget the screen has, so the frame's 402x874 is set explicitly
/// the way the other screen tests do.
Future<void> _pumpScreen(
  WidgetTester tester,
  WorkoutProvider provider, {
  String id = 'w1',
}) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider<WorkoutProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: SetLoggingScreen(
          route: RouteSettings(name: SetLoggingScreen.routeFor(id)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(useOfflineFonts);

  group('rest timer', () {
    testWidgets('appears on the logged set and counts the rest down', (
      tester,
    ) async {
      final provider = _provider();
      await _pumpScreen(tester, provider);

      // Nothing to rest from until a set is logged.
      expect(find.textContaining('REST /'), findsNothing);

      await tester.tap(find.text('Log set 02'));
      await tester.pump();

      // The plan asks for 120s, so the control shows the budget and the clock
      // starts there.
      expect(find.text('REST / 02:00'), findsOneWidget);
      expect(find.text('02:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('01:59'), findsOneWidget);

      // Stop the periodic clock before the test tears the tree down.
      await tester.tap(find.text('Skip'));
      await tester.pump();
    });

    testWidgets('+30s adds half a minute and stretches the budget', (
      tester,
    ) async {
      final provider = _provider();
      await _pumpScreen(tester, provider);

      await tester.tap(find.text('Log set 02'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('01:59'), findsOneWidget);

      await tester.tap(find.text('+30s'));
      await tester.pump();

      // 119s left plus 30 makes 149s, which is now the session's rest budget
      // rather than the plan's 120.
      expect(find.text('02:29'), findsOneWidget);
      expect(find.text('REST / 02:29'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();
    });

    testWidgets('Skip ends the rest and hides the control', (tester) async {
      final provider = _provider();
      await _pumpScreen(tester, provider);

      await tester.tap(find.text('Log set 02'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(find.textContaining('REST /'), findsNothing);
      expect(find.text('01:59'), findsNothing);
    });
  });

  group('set entry', () {
    testWidgets('seeds the steppers from the set about to be logged', (
      tester,
    ) async {
      final provider = _provider();
      await _pumpScreen(tester, provider);

      expect(find.text('LOG SET 02'), findsOneWidget);

      // 72.5 kg and 11 reps are the second, unfinished set. Each shows twice:
      // once in the set row and once in the stepper seeded from that same set,
      // so a stepper seeded from anywhere else would move one of the counts.
      expect(find.text('72.5'), findsNWidgets(2));
      expect(find.text('11'), findsNWidgets(2));
    });

    testWidgets('logging writes the edited weight and reps through the '
        'provider', (tester) async {
      final provider = _provider();
      await _pumpScreen(tester, provider);

      // The weight stepper sits left of the reps stepper, matching the frame.
      await tester.tap(find.byIcon(Icons.add_rounded).at(0));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_rounded).at(0));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_rounded).at(1));
      await tester.pump();

      await tester.tap(find.text('Log set 02'));
      await tester.pump();

      final logged = provider.byId('w1')!.logs.first.sets[1];
      expect(logged.completed, isTrue);
      expect(logged.weightKg, 77.5); // 72.5 + 2.5 + 2.5
      expect(logged.reps, 12); // 11 + 1

      await tester.tap(find.text('Skip'));
      await tester.pump();
    });
  });

  group('empty states', () {
    testWidgets('a session with no exercises says so', (tester) async {
      final provider = _provider(workouts: [_squatSession(logs: const [])]);
      await _pumpScreen(tester, provider);

      expect(find.text('Nothing to log yet'), findsOneWidget);
    });

    testWidgets('a session that is not in the store says so', (tester) async {
      final provider = _provider();
      await _pumpScreen(tester, provider, id: 'ghost');

      expect(find.text('Session not found'), findsOneWidget);
    });
  });
}
