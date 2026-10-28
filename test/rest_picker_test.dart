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

/// Rest is planned per exercise and set from the logging screen, so the value
/// has to outlive the set that prompted it.
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

  Workout session() => Workout(
    id: 'w1',
    title: 'Lower Body A',
    date: date,
    status: WorkoutStatus.planned,
    durationMin: 45,
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

  group('planning a rest', () {
    test('writes it to the exercise and leaves the others alone', () {
      final provider = WorkoutProvider(today: date, workouts: [session()]);

      expect(provider.setRest('w1', 0, 30), isTrue);

      expect(provider.byId('w1')!.logs[0].restSeconds, 30);
      // The second exercise planned its own rest and must keep it.
      expect(provider.byId('w1')!.logs[1].restSeconds, 90);
    });

    test('refuses an exercise that is not there', () {
      final provider = WorkoutProvider(today: date, workouts: [session()]);

      expect(provider.setRest('w1', 9, 30), isFalse);
      expect(provider.setRest('nope', 0, 30), isFalse);
    });

    test('zero means no rest, which is a real choice', () {
      final provider = WorkoutProvider(today: date, workouts: [session()]);

      provider.setRest('w1', 0, 0);

      expect(provider.byId('w1')!.logs[0].restSeconds, 0);
    });

    testWidgets('the number on the rest block opens the wheel', (tester) async {
      final provider = WorkoutProvider(today: date, workouts: [session()]);
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

      // Logging a set starts the rest, which is when the block is on screen.
      await tester.tap(find.text('Log set 02'));
      await tester.pump();
      await tester.tap(find.textContaining('REST /'));
      await tester.pumpAndSettle();

      // The wheel, its title, and the control that commits the choice.
      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('Barbell Back Squat'), findsOneWidget);
      expect(find.text('Set 2:00'), findsOneWidget);

      await tester.tap(find.text('Set 2:00'));
      await tester.pumpAndSettle();

      expect(find.text('Rest'), findsNothing);
      // Committing the value it opened on leaves the plan exactly as it was.
      expect(provider.byId('w1')!.logs[0].restSeconds, 120);
    });
  });
}
