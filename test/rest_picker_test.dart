import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/set_logging_screen.dart';
import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/rest_picker_sheet.dart';

import 'support/harness.dart';

/// The rest a session trains with is chosen while it runs and is **not stored**:
/// it belongs to how somebody is training today, not to the plan. The session's
/// *length*, by contrast, is recorded - see session_clock_test.dart.
void main() {
  setUpAll(useOfflineFonts);

  final date = DateTime(2026, 10, 26);

  WorkoutSet set(int reps, double weight, {bool completed = false}) =>
      WorkoutSet(reps: reps, weightKg: weight, completed: completed);

  ExerciseLog log(
    String name,
    List<WorkoutSet> sets, {
    int restSeconds = 120,
  }) => ExerciseLog(
    exercise: Exercise(
      name: name,
      equipment: 'Barbell',
      muscleGroups: const ['Legs'],
    ),
    sets: sets,
    restSeconds: restSeconds,
  );

  Workout session({String id = 'w1'}) => Workout(
    id: id,
    title: 'Lower Body A',
    date: date,
    status: WorkoutStatus.planned,
    durationMin: 0,
    estimatedKcal: 300,
    targetMuscleGroups: const ['Legs'],
    equipment: const ['Barbell'],
    logs: [
      log('Barbell Back Squat', [
        set(8, 40, completed: true),
        set(11, 72.5),
        set(11, 72.5),
      ]),
      log('Romanian Deadlift', [set(10, 70)], restSeconds: 90),
    ],
  );

  group('rest label', () {
    test('reads as a clock, and as Off when there is none', () {
      expect(restLabel(0), 'Off');
      expect(restLabel(10), '0:10');
      expect(restLabel(90), '1:30');
      expect(restLabel(600), '10:00');
    });
  });

  group('the session rest', () {
    test('starts at none and is never written to the plan', () {
      final provider = WorkoutProvider(today: date, workouts: [session()]);

      // Nothing rests until somebody says so, and the choice lives only in
      // this run.
      expect(provider.sessionRest('w1'), 0);
      provider.setSessionRest('w1', 30);
      expect(provider.sessionRest('w1'), 30);

      // The plan is untouched. This is the whole point: choosing a rest does
      // not edit the exercise, so nothing about it reaches the database.
      expect(provider.byId('w1')!.logs[0].restSeconds, 120);
      expect(provider.byId('w1')!.logs[1].restSeconds, 90);
    });

    test('belongs to one session and does not leak into another', () {
      final provider = WorkoutProvider(
        today: date,
        workouts: [
          session(),
          session(id: 'w2'),
        ],
      );

      provider.setSessionRest('w1', 30);

      expect(provider.sessionRest('w1'), 30);
      // w2 was never chosen for, so it still rests at none: the choice belongs
      // to the session it was made in.
      expect(provider.sessionRest('w2'), 0);
    });

    test('zero is a real choice, and means no rest', () {
      final provider = WorkoutProvider(today: date, workouts: [session()]);

      provider.setSessionRest('w1', 0);

      expect(provider.sessionRest('w1'), 0);
    });

    Future<void> pump(WidgetTester tester, WorkoutProvider provider) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider<WorkoutProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: SetLoggingScreen(
              route: RouteSettings(name: SetLoggingScreen.routeFor('w1')),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the wheel changes the session, not the plan', (tester) async {
      final provider = WorkoutProvider(today: date, workouts: [session()]);
      // Chosen, so the wheel opens on it rather than on "Off".
      provider.setSessionRest('w1', 120);
      await pump(tester, provider);

      // Logging a set starts the countdown; the control is on screen either
      // way, so tapping its label opens the wheel.
      await tester.tap(find.text('Log set 02'));
      await tester.pump();
      await tester.tap(find.text('REST'));
      await tester.pumpAndSettle();

      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('Set 2:00'), findsOneWidget);
      await tester.tap(find.text('Set 2:00'));
      await tester.pumpAndSettle();

      // Committed, and the plan still holds what it always held.
      expect(provider.sessionRest('w1'), 120);
      expect(provider.byId('w1')!.logs[0].restSeconds, 120);
    });

    testWidgets('the label opens the wheel before any rest has run', (
      tester,
    ) async {
      final provider = WorkoutProvider(today: date, workouts: [session()]);
      await pump(tester, provider);

      // No set logged, so nothing is resting - but the block is on screen and
      // its label opens the wheel, which is the only way a first rest can ever
      // be planned.
      expect(find.text('REST'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.bySemanticsLabel('Skip rest'), findsNothing);

      await tester.tap(find.text('REST'));
      await tester.pumpAndSettle();

      // The wheel is open, on Off because nothing has been chosen for this
      // session yet.
      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('No rest'), findsOneWidget);

      await tester.tap(find.text('No rest'));
      await tester.pumpAndSettle();

      // Off is the default, so committing it leaves the session resting at
      // none, and the plan is untouched either way.
      expect(provider.sessionRest('w1'), 0);
      expect(provider.byId('w1')!.logs[0].restSeconds, 120);
    });
  });
}
