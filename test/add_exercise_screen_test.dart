import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plus_one/data/exercise_api_client.dart';
import 'package:plus_one/data/exercise_catalog.dart';
import 'package:plus_one/models/library_exercise.dart';
import 'package:plus_one/screens/add_exercise_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/harness.dart';

/// A fixed three-entry catalogue, built by hand so the assertions are about the
/// screen rather than about whatever the bundled data set happens to hold: a
/// two-word movement with equipment, one whose name carries the equipment, and
/// one that carries none.
const _bench = LibraryExercise(
  name: 'Barbell Bench Press',
  aliases: ['flat bench'],
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

const _pullUp = LibraryExercise(
  name: 'Pull-Up',
  primaryMuscles: ['lats'],
  equipment: ['Body Only'],
  category: 'strength',
);

const _catalogue = [_bench, _curl, _pullUp];

/// A catalogue that answers from the bundled set without touching the network:
/// the wger client is stubbed to fail so the load deterministically falls back.
ExerciseCatalog _catalog([List<LibraryExercise> exercises = _catalogue]) =>
    ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async => http.Response('down', 500)),
      ),
      bundled: () async => exercises,
    );

/// What the picker handed back, and whether it has come back at all.
class _Picked {
  List<LibraryExercise>? value;
  bool done = false;
}

/// Opens [AddExerciseScreen] behind a button so the test can read what the
/// screen popped with — the whole point of the screen is that answer.
Future<_Picked> _openPicker(
  WidgetTester tester, {
  ExerciseCatalog? catalog,
}) async {
  final picked = _Picked();

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                picked.value = await Navigator.of(context)
                    .push<List<LibraryExercise>>(
                      MaterialPageRoute(
                        builder: (_) =>
                            AddExerciseScreen(catalog: catalog ?? _catalog()),
                      ),
                    );
                picked.done = true;
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  setUpAll(useOfflineFonts);

  testWidgets('renders every exercise with its title and tags', (tester) async {
    await _openPicker(tester);

    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.text('EXERCISES'), findsOneWidget);
    expect(find.text('3 exercises'), findsOneWidget);

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Curl'), findsOneWidget);
    expect(find.text('Pull-Up'), findsOneWidget);

    // The tags come from exerciseTags: primary muscle, equipment, then type.
    expect(find.text('CHEST'), findsOneWidget);
    expect(find.text('BARBELL'), findsOneWidget);
    expect(find.text('FREE-WEIGHTS'), findsWidgets);
  });

  testWidgets('narrows the list by name and alias', (tester) async {
    await _openPicker(tester);

    await tester.enterText(find.byType(TextField), 'curl');
    await tester.pump();

    expect(find.text('Dumbbell Curl'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
    expect(find.text('Pull-Up'), findsNothing);
    expect(find.text('1 exercise'), findsOneWidget);
  });

  testWidgets('returns exactly the tapped selection, in tap order', (
    tester,
  ) async {
    final picked = await _openPicker(tester);

    await tester.tap(find.text('Dumbbell Curl'));
    await tester.pump();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(picked.done, isTrue);
    expect(picked.value, [_curl, _bench]);
  });

  testWidgets('a second tap unselects', (tester) async {
    final picked = await _openPicker(tester);

    await tester.tap(find.text('Dumbbell Curl'));
    await tester.pump();
    await tester.tap(find.text('Dumbbell Curl'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(picked.value, isEmpty);
  });

  testWidgets('Cancel returns nothing', (tester) async {
    final picked = await _openPicker(tester);

    await tester.tap(find.text('Dumbbell Curl'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(picked.done, isTrue);
    expect(picked.value, isNull);
  });

  testWidgets('an equipment filter narrows the list', (tester) async {
    await _openPicker(tester);

    await tester.tap(find.text('All Equipment'));
    await tester.pumpAndSettle();

    // The sheet lists the facet's values plus "All".
    expect(find.text('EQUIPMENT'), findsOneWidget);
    await tester.tap(find.text('Dumbbell'));
    await tester.pumpAndSettle();

    // The chosen value is reflected in the button, and the list holds only it.
    expect(find.text('Dumbbell'), findsOneWidget);
    expect(find.text('Dumbbell Curl'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
    expect(find.text('Pull-Up'), findsNothing);
    expect(find.text('1 exercise'), findsOneWidget);
  });

  testWidgets('a muscle filter narrows the list', (tester) async {
    await _openPicker(tester);

    await tester.tap(find.text('All Muscles'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('biceps'));
    await tester.pumpAndSettle();

    expect(find.text('biceps'), findsOneWidget);
    expect(find.text('Dumbbell Curl'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsNothing);
  });

  testWidgets('search with no match shows the empty state', (tester) async {
    await _openPicker(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('Nothing matches'), findsOneWidget);
    expect(find.text('0 exercises'), findsOneWidget);
  });

  testWidgets('lays out on the frame\'s 402x874 without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _openPicker(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Add Exercise'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
