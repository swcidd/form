import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/set_logging_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/harness.dart';

/// What the action does once a set is logged.
///
/// Two outcomes, and which one you get depends on whether the exercise you are
/// on still has work left: sets remaining start a rest, and the set that
/// finishes an exercise moves the screen on instead - a rest belongs to the
/// exercise you are still on, not to the one you just left.
void main() {
  setUpAll(useOfflineFonts);

  final date = DateTime(2026, 10, 26);

  WorkoutSet set(int reps, double weight, {bool completed = false}) =>
      WorkoutSet(reps: reps, weightKg: weight, completed: completed);

  ExerciseLog log(String name, List<WorkoutSet> sets) => ExerciseLog(
    exercise: Exercise(
      name: name,
      equipment: 'Barbell',
      muscleGroups: const ['Legs'],
    ),
    sets: sets,
    restSeconds: 120,
  );

  /// One set each, both still to log: finishing the first exercise has to leave
  /// the screen somewhere, and the second is where.
  Workout twoExercises() => Workout(
    id: 'w1',
    title: 'Lower Body A',
    date: date,
    status: WorkoutStatus.planned,
    durationMin: 45,
    estimatedKcal: 300,
    targetMuscleGroups: const ['Legs'],
    equipment: const ['Barbell'],
    logs: [
      log('Barbell Back Squat', [set(8, 90)]),
      log('Romanian Deadlift', [set(10, 70)]),
    ],
  );

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

  testWidgets('the set that finishes an exercise moves on without a rest', (
    tester,
  ) async {
    final provider = WorkoutProvider(today: date, workouts: [twoExercises()]);
    await pump(tester, provider);

    expect(
      find.textContaining(RegExp('back squat', caseSensitive: false)),
      findsWidgets,
    );

    await tester.tap(find.text('Log set 01'));
    await tester.pump();

    // The squat's only set is done, so the screen is on the next exercise...
    expect(
      find.textContaining(RegExp('romanian deadlift', caseSensitive: false)),
      findsWidgets,
    );
    // ...and the countdown did not start, because there is nothing left to
    // rest between.
    expect(find.textContaining('REST /'), findsNothing);
  });

  testWidgets('a set that leaves work still starts the rest', (tester) async {
    final provider = WorkoutProvider(
      today: date,
      workouts: [
        twoExercises().copyWith(
          logs: [
            // Three sets with one done: logging the second leaves a third, so
            // the exercise still has work on it.
            log('Barbell Back Squat', [
              set(8, 90, completed: true),
              set(8, 90),
              set(8, 90),
            ]),
            log('Romanian Deadlift', [set(10, 70)]),
          ],
        ),
      ],
    );
    await pump(tester, provider);

    await tester.tap(find.text('Log set 02'));
    await tester.pump();

    // One set left on the squat, so this is a rest - not a move to the next
    // exercise.
    expect(find.textContaining('REST /'), findsOneWidget);
    expect(
      find.textContaining(RegExp('romanian deadlift', caseSensitive: false)),
      findsNothing,
    );
  });
}
