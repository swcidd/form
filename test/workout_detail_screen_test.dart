import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/library_exercise.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/add_exercise_screen.dart';
import 'package:plus_one/screens/edit_workout_screen.dart';
import 'package:plus_one/screens/workout_detail_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

/// The session screen is how a user reaches everything else about a workout:
/// the picker that fills its line-up, the editor, the log, and — through the
/// toolbar's overflow — its deletion. These tests hold the screen to the two
/// Figma frames it now follows: the filled session, with both actions, and the
/// empty one, where the line-up becomes a framed block and the band drops to
/// Add Exercise alone.

final _today = DateTime(2026, 10, 17);

/// Two catalogue entries the picker can hand back. Named apart from the seed
/// data so an assertion here can never be satisfied by a fixture elsewhere.
const _bench = LibraryExercise(
  name: 'Barbell Bench Press',
  primaryMuscles: ['chest'],
  equipment: ['Barbell'],
  category: 'strength',
);

const _curl = LibraryExercise(
  name: 'Dumbbell Curl',
  primaryMuscles: ['biceps'],
  equipment: ['Dumbbell'],
  category: 'strength',
);

Workout _lowerBody({String id = 'w1', List<ExerciseLog> logs = const []}) =>
    Workout(
      id: id,
      title: 'Lower Body A',
      date: _today,
      status: WorkoutStatus.planned,
      durationMin: 55,
      estimatedKcal: 420,
      targetMuscleGroups: const ['Quads', 'Glutes'],
      equipment: const ['Barbell'],
      logs: logs,
    );

ExerciseLog _log(String name) => ExerciseLog(
  exercise: Exercise(
    name: name,
    equipment: 'Barbell',
    muscleGroups: const ['Quads'],
  ),
  sets: const [WorkoutSet(reps: 5, weightKg: 100)],
);

/// The named routes the screen asked the navigator for, in order.
class _Pushed {
  final names = <String>[];
}

/// The detail screen behind a navigator that answers the two routes its actions
/// push: the picker (stubbed, so no catalogue load and the exact return value
/// is under the test's control) and the editor. The real picker's own behaviour
/// has its own suite; what this one checks is that the screen pushes the right
/// name and writes what comes back.
Widget _app(
  WorkoutProvider provider, {
  required String id,
  List<LibraryExercise>? picked,
  _Pushed? pushed,
}) {
  return ChangeNotifierProvider<WorkoutProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: WorkoutDetailScreen(
        route: RouteSettings(name: WorkoutDetailScreen.routeFor(id)),
      ),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        pushed?.names.add(name);
        if (name.startsWith(AddExerciseScreen.routeName)) {
          return MaterialPageRoute<List<LibraryExercise>>(
            settings: settings,
            builder: (_) => _StubPicker(result: picked),
          );
        }
        if (name.startsWith(EditWorkoutScreen.routeName)) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('edit route')),
          );
        }
        return null;
      },
    ),
  );
}

/// Stands in for the picker: one tap hands [result] back, and a null result is
/// the back gesture's answer.
class _StubPicker extends StatelessWidget {
  const _StubPicker({required this.result});

  final List<LibraryExercise>? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(result),
          child: const Text('Hand back'),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(useOfflineFonts);

  testWidgets('shows the session it was given', (tester) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(_app(provider, id: workout.id));
    await tester.pump();

    expect(find.text(workout.title.toUpperCase()), findsOneWidget);
    expect(find.text('THE LINEUP'), findsOneWidget);
    // The plan's own focus, and none of the canned Lower Body session that
    // used to be built for every id.
    expect(find.text('CHEST / SHOULDERS'), findsOneWidget);
    expect(find.textContaining('LOWER BODY'), findsNothing);
    expect(find.textContaining('Barbell back squat'), findsNothing);
    // Edit is no longer hidden behind the toolbar overflow: the frame puts it
    // in the line-up header, so it is on screen.
    expect(find.text('Edit workout'), findsOneWidget);
  });

  testWidgets('an id that is not in the store says so', (tester) async {
    final provider = seededProvider();

    await tester.pumpWidget(_app(provider, id: 'deleted-session'));
    await tester.pump();

    expect(find.text('Session not found'), findsOneWidget);
    expect(find.text('THE LINEUP'), findsNothing);
  });

  testWidgets('a filled session shows both actions over its rows', (
    tester,
  ) async {
    final provider = WorkoutProvider(
      today: _today,
      workouts: [
        _lowerBody(logs: [_log('Back Squat')]),
      ],
    );

    await tester.pumpWidget(_app(provider, id: 'w1'));
    await tester.pump();

    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('NOTHING LINED UP YET'), findsNothing);
  });

  testWidgets('a session with no exercises shows the empty line-up', (
    tester,
  ) async {
    final provider = WorkoutProvider(today: _today, workouts: [_lowerBody()]);

    await tester.pumpWidget(_app(provider, id: 'w1'));
    await tester.pump();

    expect(find.text('NOTHING LINED UP YET'), findsOneWidget);
    expect(find.textContaining('no exercises yet'), findsOneWidget);
    // The band drops to Add Exercise alone: there is nothing yet to start.
    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
    // The session is still editable from the empty state.
    expect(find.text('Edit workout'), findsOneWidget);
  });

  testWidgets('Add Exercise appends the picked exercises through the store', (
    tester,
  ) async {
    final provider = WorkoutProvider(today: _today, workouts: [_lowerBody()]);
    final pushed = _Pushed();

    await tester.pumpWidget(
      _app(provider, id: 'w1', picked: [_bench, _curl], pushed: pushed),
    );
    await tester.pump();

    await tester.tap(find.text('Add Exercise'));
    await tester.pumpAndSettle();

    // The action opens the picker by its route name.
    expect(pushed.names, contains(AddExerciseScreen.routeName));

    await tester.tap(find.text('Hand back'));
    await tester.pumpAndSettle();

    final saved = provider.byId('w1')!;
    expect(saved.logs.map((log) => log.exercise.name).toList(), [
      'Barbell Bench Press',
      'Dumbbell Curl',
    ]);
    // Mapped the way the new-workout dialog maps one: equipment from the first
    // entry, muscles from the primaries, and no invented sets.
    expect(saved.logs.first.exercise.equipment, 'Barbell');
    expect(saved.logs.first.exercise.muscleGroups, ['chest']);
    expect(saved.logs.every((log) => log.sets.isEmpty), isTrue);

    // The line-up is filled now, so the empty block is gone and Start is back.
    expect(find.text('NOTHING LINED UP YET'), findsNothing);
    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('backing out of the picker changes nothing', (tester) async {
    final provider = WorkoutProvider(today: _today, workouts: [_lowerBody()]);

    // A null result is the back gesture's answer, not an empty selection.
    await tester.pumpWidget(_app(provider, id: 'w1', picked: null));
    await tester.pump();

    await tester.tap(find.text('Add Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hand back'));
    await tester.pumpAndSettle();

    expect(provider.byId('w1')!.logs, isEmpty);
    expect(find.text('NOTHING LINED UP YET'), findsOneWidget);
  });

  testWidgets('Edit workout pushes the edit route', (tester) async {
    final provider = WorkoutProvider(today: _today, workouts: [_lowerBody()]);
    final pushed = _Pushed();

    await tester.pumpWidget(_app(provider, id: 'w1', pushed: pushed));
    await tester.pump();

    await tester.tap(find.text('Edit workout'));
    await tester.pumpAndSettle();

    expect(pushed.names, contains(EditWorkoutScreen.routeFor('w1')));
    expect(find.text('edit route'), findsOneWidget);
  });

  testWidgets('delete reaches the store only after confirmation', (
    tester,
  ) async {
    final provider = WorkoutProvider(today: _today, workouts: [_lowerBody()]);

    await tester.pumpWidget(_app(provider, id: 'w1'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete session'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(provider.byId('w1'), isNull);
  });

  testWidgets('cancelling the delete leaves the session', (tester) async {
    final provider = WorkoutProvider(today: _today, workouts: [_lowerBody()]);

    await tester.pumpWidget(_app(provider, id: 'w1'));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(provider.byId('w1'), isNotNull);
  });
}
