import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plus_one/data/exercise_api_client.dart';
import 'package:plus_one/data/exercise_catalog.dart';
import 'package:plus_one/models/library_exercise.dart';
import 'package:plus_one/screens/exercise_detail_screen.dart';
import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/empty_state.dart';

import 'support/harness.dart';

/// A fully-populated entry, paired with a second barbell/dumbbell variant so
/// [exerciseTitle] has something to disambiguate and the toolbar name and the
/// headline read differently.
const _barbellBench = LibraryExercise(
  name: 'Barbell Bench Press',
  primaryMuscles: ['chest', 'triceps'],
  secondaryMuscles: ['shoulders'],
  instructions: [
    'Lie on the bench.',
    'Lower the bar to your chest.',
    'Press it back up.',
  ],
  equipment: ['Barbell'],
  category: 'strength',
  level: 'intermediate',
  force: 'push',
  mechanic: 'compound',
  description: 'The classic horizontal press.',
  tips: ['Keep your shoulders packed.', 'Drive through your feet.'],
);

const _dumbbellBench = LibraryExercise(
  name: 'Dumbbell Bench Press',
  primaryMuscles: ['chest'],
  equipment: ['Dumbbell'],
  category: 'strength',
);

/// The other end of the range: a muscle, a name and nothing else to render.
const _deadBug = LibraryExercise(
  name: 'Dead Bug',
  primaryMuscles: ['abdominals'],
  equipment: ['body only'],
  category: 'strength',
);

/// A catalogue that answers from the bundled fixture, never the network.
ExerciseCatalog _catalog(List<LibraryExercise> exercises) => ExerciseCatalog(
  api: ExerciseApiClient(
    client: MockClient((_) async => http.Response('down', 500)),
  ),
  bundled: () async => exercises,
);

/// A catalogue that cannot answer at all: wger down and the assets missing.
ExerciseCatalog _failingCatalog() => ExerciseCatalog(
  api: ExerciseApiClient(
    client: MockClient((_) async => http.Response('down', 500)),
  ),
  bundled: () async => throw StateError('assets missing'),
);

Widget _screen(ExerciseCatalog catalog, String slug) => MaterialApp(
  theme: AppTheme.light(),
  home: ExerciseDetailScreen(
    route: RouteSettings(name: ExerciseDetailScreen.routeFor(slug)),
    catalog: catalog,
  ),
);

/// Pumps the fake clock until the catalogue has resolved and its spinner is
/// gone. The load is microtask-only, but one pump is not always enough for the
/// FutureBuilder to have seen the result.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.any(find.byType(CircularProgressIndicator))) return;
  }
}

void main() {
  setUpAll(useOfflineFonts);

  testWidgets('a fully-populated exercise renders every section', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(
        _catalog(const [_barbellBench, _dumbbellBench]),
        'barbell-bench-press',
      ),
    );
    await _settle(tester);

    // Toolbar carries the raw name; the headline carries the disambiguated
    // title the shared vocabulary produces.
    expect(find.text('BARBELL BENCH PRESS'), findsOneWidget);
    expect(find.text('Bench Press (Barbell)'), findsOneWidget);

    // Tags, in the order exerciseTags fixes.
    expect(find.text('CHEST'), findsOneWidget);
    expect(find.text('BARBELL'), findsOneWidget);
    expect(find.text('FREE-WEIGHTS'), findsOneWidget);
    expect(find.text('PUSH'), findsOneWidget);

    expect(find.text('The classic horizontal press.'), findsOneWidget);

    expect(find.text('PRIMARY MUSCLES'), findsOneWidget);
    expect(find.textContaining('Chest'), findsWidgets);
    expect(find.textContaining('Triceps'), findsWidgets);
    expect(find.text('SECONDARY MUSCLES'), findsOneWidget);
    expect(find.text('Shoulders'), findsOneWidget);

    expect(find.text('HOW TO'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Lie on the bench.'), findsOneWidget);
    expect(find.text('Press it back up.'), findsOneWidget);

    expect(find.text('FORM CUES'), findsOneWidget);
    expect(find.text('Keep your shoulders packed.'), findsOneWidget);

    expect(find.text('DETAILS'), findsOneWidget);
    expect(find.text('MECHANIC'), findsOneWidget);
    expect(find.text('Compound'), findsOneWidget);
    expect(find.text('FORCE'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
  });

  testWidgets('a minimal exercise omits the sections it has nothing for', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(_catalog(const [_deadBug]), 'dead-bug'));
    await _settle(tester);

    expect(find.text('DEAD BUG'), findsOneWidget);
    expect(find.text('Dead Bug'), findsOneWidget);
    expect(find.text('CORE'), findsOneWidget);
    expect(find.text('BODYWEIGHT'), findsOneWidget);

    expect(find.text('PRIMARY MUSCLES'), findsOneWidget);
    expect(find.text('Abdominals'), findsOneWidget);

    // No instructions, no tips, no secondary muscles, no mechanic or force and
    // no description: the headings must not appear over empty space.
    expect(find.text('HOW TO'), findsNothing);
    expect(find.text('FORM CUES'), findsNothing);
    expect(find.text('SECONDARY MUSCLES'), findsNothing);
    expect(find.text('DETAILS'), findsNothing);
    expect(find.text('MECHANIC'), findsNothing);
    expect(find.text('FORCE'), findsNothing);
  });

  testWidgets('an unknown slug lands on the empty state', (tester) async {
    await tester.pumpWidget(
      _screen(
        _catalog(const [_barbellBench, _dumbbellBench]),
        'not-an-exercise',
      ),
    );
    await _settle(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Exercise not found'), findsOneWidget);
    expect(find.text('Go back'), findsOneWidget);
    expect(find.text('Bench Press (Barbell)'), findsNothing);
  });

  testWidgets('a catalogue that cannot load lands on the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(_failingCatalog(), 'barbell-bench-press'));
    await _settle(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Could not load this exercise'), findsOneWidget);
    expect(find.text('Go back'), findsOneWidget);
  });

  testWidgets('the back chevron pops the screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExerciseDetailScreen(
                      route: RouteSettings(
                        name: ExerciseDetailScreen.routeFor('dead-bug'),
                      ),
                      catalog: _catalog(const [_deadBug]),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('DEAD BUG'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('DEAD BUG'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('fits a 320dp phone without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _screen(
        _catalog(const [_barbellBench, _dumbbellBench]),
        'barbell-bench-press',
      ),
    );
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });
}
