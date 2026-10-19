import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/set_logging_screen.dart';
import 'package:plus_one/screens/workout_detail_screen.dart';
import 'package:plus_one/screens/workout_summary_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

Widget _withProvider(WorkoutProvider provider, Widget screen) =>
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light(), home: screen),
    );

/// A fixed "today" for the session built in the record test.
final _today = DateTime(2026, 10, 17);

final _bench = Exercise(
  name: 'Bench Press',
  equipment: 'Barbell',
  muscleGroups: const ['Chest'],
);

Workout _pushDay({
  required String id,
  required DateTime date,
  required WorkoutStatus status,
  required double weightKg,
}) => Workout(
  id: id,
  title: 'Push Day',
  date: date,
  status: status,
  durationMin: 40,
  estimatedKcal: 300,
  targetMuscleGroups: const ['Chest'],
  equipment: const ['Barbell'],
  logs: [
    ExerciseLog(
      exercise: _bench,
      sets: [WorkoutSet(reps: 5, weightKg: weightKg, completed: true)],
    ),
  ],
);

/// These screens sat behind navigation with no test ever rendering them, which
/// is how the library screen once kept a crash it could not show. Plain pumps
/// (no settle) in case the rest timer keeps a periodic clock running.
void main() {
  setUpAll(useOfflineFonts);

  testWidgets('set logging renders its session without mock chrome', (
    tester,
  ) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(
      _withProvider(
        provider,
        SetLoggingScreen(
          route: RouteSettings(name: SetLoggingScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Session not found'), findsNothing);
    // The fake iOS status bar is gone; the real one comes from the OS.
    expect(find.text('9:41'), findsNothing);
  });

  testWidgets('set logging reports the sets that are done, not a clock', (
    tester,
  ) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(
      _withProvider(
        provider,
        SetLoggingScreen(
          route: RouteSettings(name: SetLoggingScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    // The toolbar used to read "12:34" for every session, from nowhere.
    expect(find.text('12:34'), findsNothing);
    expect(
      find.text('${workout.completedSets} / ${workout.totalSets} sets'),
      findsOneWidget,
    );
  });

  testWidgets('the logging screen shows what the last session did', (
    tester,
  ) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(
      _withProvider(
        provider,
        SetLoggingScreen(
          route: RouteSettings(name: SetLoggingScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    // The seeded history holds the same exercise yesterday at 40 kg, so the
    // header names it and the PREVIOUS column fills in instead of a dash.
    expect(find.text('No previous data'), findsNothing);
    expect(find.text('Last time: 40.0 kg × 10'), findsOneWidget);
    expect(find.text('40.0 × 10'), findsWidgets);
  });

  testWidgets('the summary renders its session without mock chrome', (
    tester,
  ) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(
      _withProvider(
        provider,
        WorkoutSummaryScreen(
          route: RouteSettings(name: WorkoutSummaryScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Session not found'), findsNothing);
    expect(find.text('9:41'), findsNothing);
  });

  testWidgets('the summary counts the session it was given', (tester) async {
    final seeded = seededProvider();
    final workout = seeded.focusWorkout!;

    // Only this session, with no history behind it: the figures below are about
    // the session's own sets, and the record claim has its own test.
    final provider = WorkoutProvider(today: workout.date, workouts: [workout]);

    await tester.pumpWidget(
      _withProvider(
        provider,
        WorkoutSummaryScreen(
          route: RouteSettings(name: WorkoutSummaryScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    // 8x60 + 8x60 + 12x14, the completed sets of the seeded plan.
    expect(find.text('1128'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);

    final headline =
        '${DateFormat('EEE, MMM d').format(workout.date).toUpperCase()} / '
        '${workout.title}';
    expect(find.text(headline), findsOneWidget);

    // The invented date, duration and percentage are gone, and the session
    // has no earlier namesake, so there is nothing to compare it with.
    expect(find.textContaining('MON, OCT 12'), findsNothing);
    expect(find.textContaining('52:18'), findsNothing);
    expect(find.textContaining('vs. last session'), findsNothing);
    expect(find.text('NEW PERSONAL RECORD'), findsNothing);
  });

  testWidgets('a session that beat the last one claims the record', (
    tester,
  ) async {
    final provider = WorkoutProvider(
      today: _today,
      workouts: [
        _pushDay(
          id: 'old',
          date: _today.subtract(const Duration(days: 10)),
          status: WorkoutStatus.completed,
          weightKg: 90,
        ),
        _pushDay(
          id: 'now',
          date: _today,
          status: WorkoutStatus.planned,
          weightKg: 100,
        ),
      ],
    );

    await tester.pumpWidget(
      _withProvider(
        provider,
        WorkoutSummaryScreen(
          route: RouteSettings(name: WorkoutSummaryScreen.routeFor('now')),
        ),
      ),
    );
    await tester.pump();

    // The card names both the set that was lifted and the one it beat, so the
    // claim can be checked against the log.
    expect(find.text('NEW PERSONAL RECORD'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('kg × 5'), findsOneWidget);
    expect(find.text('90 kg × 5'), findsOneWidget);
    expect(
      find.text(
        'previous best · '
        '${DateFormat('MMM d').format(_today.subtract(const Duration(days: 10)))}',
      ),
      findsOneWidget,
    );

    // 500 kg this time against the 450 kg of the last Push Day.
    expect(find.text('+11%'), findsOneWidget);
    expect(find.text('vs. last session'), findsOneWidget);
  });

  testWidgets('the detail screen shows the session it was given', (
    tester,
  ) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(
      _withProvider(
        provider,
        WorkoutDetailScreen(
          route: RouteSettings(name: WorkoutDetailScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(workout.title), findsOneWidget);
    expect(find.text('THE LINEUP'), findsOneWidget);
    // The plan's own focus, and none of the canned Lower Body session that
    // used to be built for every id.
    expect(find.text('CHEST / SHOULDERS'), findsOneWidget);
    expect(find.textContaining('LOWER BODY'), findsNothing);
    expect(find.textContaining('Barbell back squat'), findsNothing);
    expect(find.textContaining('Edit workout'), findsNothing);
  });

  testWidgets('an id that is not in the store says so', (tester) async {
    final provider = seededProvider();

    await tester.pumpWidget(
      _withProvider(
        provider,
        WorkoutDetailScreen(
          route: const RouteSettings(name: '/workout-detail/deleted-session'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Session not found'), findsOneWidget);
    expect(find.text('THE LINEUP'), findsNothing);
  });

  testWidgets('a session with no exercises says that instead', (tester) async {
    final provider = WorkoutProvider(
      today: _today,
      workouts: [
        Workout(
          id: 'fresh',
          title: 'Leg Day',
          date: _today,
          status: WorkoutStatus.planned,
          durationMin: 0,
          estimatedKcal: 0,
          targetMuscleGroups: const [],
          equipment: const [],
          logs: const [],
        ),
      ],
    );

    await tester.pumpWidget(
      _withProvider(
        provider,
        WorkoutDetailScreen(
          route: RouteSettings(name: WorkoutDetailScreen.routeFor('fresh')),
        ),
      ),
    );
    await tester.pump();

    // A session created a moment ago has nothing planned on it, so the screen
    // says that rather than showing a line-up it does not have.
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('THE LINEUP'), findsNothing);
    expect(find.textContaining('no exercises yet'), findsOneWidget);
    // Nothing to focus on yet, so the section is left out rather than empty.
    expect(find.text("TODAY'S FOCUS"), findsNothing);
  });
}
