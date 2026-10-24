import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/data/exercise_api_client.dart';
import 'package:plus_one/data/exercise_catalog.dart';
import 'package:plus_one/exercise_library.dart';
import 'package:plus_one/main.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/library_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

String _wgerBody() => jsonEncode({
  'count': 1,
  'results': [
    {
      'category': {'name': 'Arms'},
      'muscles': [
        {'name': 'Biceps brachii', 'name_en': 'Biceps'},
      ],
      'equipment': [
        {'name': 'Barbell'},
      ],
      'translations': [
        {'language': 2, 'name': 'Barbell Curl', 'description': ''},
      ],
    },
  ],
});

/// The screen under the app's own routes, so a tap that navigates does not
/// pass here and fail in the application.
Widget _screen({ExerciseCatalog? catalog, WorkoutProvider? provider}) =>
    ChangeNotifierProvider<WorkoutProvider>.value(
      value: provider ?? WorkoutProvider(),
      child: MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: PlusOneApp.routeFor,
        home: LibraryScreen(catalog: catalog),
      ),
    );

/// A fixed Sunday, so the week boundary in the assertions is arithmetic rather
/// than whatever day the suite happens to run on.
final DateTime _today = DateTime(2026, 10, 18);

/// Opens the catalogue's pill. The exercise grid lives behind it in the design
/// rather than on the first screen, so every catalogue assertion starts here.
Future<void> openDiscover(WidgetTester tester) async {
  await tester.tap(find.text('Discover'));
  await tester.pump();
}

/// Waits out the screen's real-I/O hops (the HTTP probe, asset loading),
/// which the fake clock cannot advance: each iteration pumps the fake clock
/// and, while the spinner still runs, grants real time for the I/O to land.
Future<void> settleCatalog(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.any(find.byType(CircularProgressIndicator))) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
  }
}

void main() {
  setUpAll(useOfflineFonts);

  group('a new account', () {
    testWidgets(
      'is offered a first session instead of someone else\'s program',
      (tester) async {
        await tester.pumpWidget(_screen());

        expect(find.text('THE TRAINING LIBRARY'), findsOneWidget);
        expect(find.text('MAKE YOUR FIRST MOVE.'), findsOneWidget);
        expect(
          find.text(
            'No workouts yet. Start with the basics,\n'
            "then build a library that's yours.",
          ),
          findsOneWidget,
        );
        expect(find.text('Explore exercises'), findsOneWidget);

        // The frame this screen replaces opened on "FOUNDATION / 08 · WEEK 04 OF
        // 08 · 50%" with a rotation nobody had. None of that may come back.
        expect(find.textContaining('FOUNDATION'), findsNothing);
        expect(find.textContaining('WEEK 04'), findsNothing);
        expect(find.text('MY ROTATION'), findsNothing);
      },
    );

    testWidgets('has nothing saved yet, and says so', (tester) async {
      await tester.pumpWidget(_screen());

      await tester.tap(find.text('Saved'));
      await tester.pump();

      expect(find.text('NOTHING SAVED YET.'), findsOneWidget);
      expect(find.textContaining('Discover'), findsWidgets);
    });
  });

  group('with sessions behind it', () {
    testWidgets('counts the week and the rotation from them', (tester) async {
      await tester.pumpWidget(_screen(provider: seededProvider(today: _today)));

      // 18 Oct 2026 is a Sunday, so the week runs Mon 12 → Sun 18: the five
      // finished sessions at offsets 1, 2, 3, 5 and 6, plus today's plan.
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('5 of 4 sessions done'), findsOneWidget);
      expect(find.text('WEEK OF OCT 12'), findsOneWidget);

      // The routines repeat, so the list is grouped by title: the five
      // templates plus the two sessions planned for later in the week.
      expect(find.text('MY ROTATION'), findsOneWidget);
      expect(find.text('7 workouts'), findsOneWidget);
      expect(find.text('NEXT SESSION'), findsOneWidget);
      expect(find.text('LAST TRAINED OCT 17'), findsOneWidget);
    });

    testWidgets('narrows the rotation with the search field', (tester) async {
      await tester.pumpWidget(_screen(provider: seededProvider(today: _today)));

      await tester.enterText(find.byType(TextField), 'leg');
      await tester.pump();

      expect(find.text('LEG DAY'), findsOneWidget);
      expect(find.text('LEG DAY & MOBILITY'), findsOneWidget);
      expect(find.text('PUSH DAY'), findsNothing);
      expect(find.text('2 workouts'), findsOneWidget);
    });
  });

  testWidgets('shows the loading state, then the live wger results', (
    tester,
  ) async {
    final catalog = ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return http.Response(_wgerBody(), 200);
        }),
      ),
      bundled: () async => const [],
    );

    await tester.pumpWidget(_screen(catalog: catalog));
    await openDiscover(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await settleCatalog(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Barbell Curl'), findsOneWidget);
    // Live data, so no offline notice.
    expect(find.textContaining('Offline'), findsNothing);
    // The card photography is sourced, and the screen says so.
    expect(find.textContaining('Unsplash'), findsOneWidget);
    // And no mock iOS status bar — that chrome belongs to the OS.
    expect(find.text('9:41'), findsNothing);
  });

  testWidgets('a failed wger shows the offline banner over the bundled sets', (
    tester,
  ) async {
    final catalog = ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async => http.Response('down', 500)),
      ),
      bundled: () async => const [
        LibraryExercise(
          name: 'Bundled Curl',
          primaryMuscles: ['biceps'],
          instructions: ['Curl the bar.'],
          equipment: ['Barbell'],
          category: 'strength',
        ),
      ],
    );

    await tester.pumpWidget(_screen(catalog: catalog));
    await openDiscover(tester);
    await settleCatalog(tester);

    expect(find.textContaining('Offline catalogue'), findsOneWidget);
    expect(find.text('Bundled Curl'), findsOneWidget);
  });

  testWidgets('total failure offers a retry instead of an empty page', (
    tester,
  ) async {
    final catalog = ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async => http.Response('down', 500)),
      ),
      bundled: () async => throw StateError('assets missing'),
    );

    await tester.pumpWidget(_screen(catalog: catalog));
    await openDiscover(tester);
    await settleCatalog(tester);

    expect(find.text('Could not load the exercise library.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('retry re-runs the load', (tester) async {
    var calls = 0;
    final catalog = ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async {
          calls++;
          if (calls == 1) return http.Response('down', 500);
          return http.Response(_wgerBody(), 200);
        }),
      ),
      bundled: () async => throw StateError('assets missing'),
    );

    await tester.pumpWidget(_screen(catalog: catalog));
    await openDiscover(tester);
    await settleCatalog(tester);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await settleCatalog(tester);

    expect(find.text('Barbell Curl'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('the search field narrows the catalogue too', (tester) async {
    final catalog = ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async => http.Response(_wgerBody(), 200)),
      ),
      bundled: () async => const [],
    );

    await tester.pumpWidget(_screen(catalog: catalog));
    await openDiscover(tester);
    await settleCatalog(tester);

    await tester.enterText(find.byType(TextField), 'triceps');
    await tester.pump();
    expect(find.textContaining('No exercises match'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'curl');
    await tester.pump();
    expect(find.text('Barbell Curl'), findsOneWidget);
  });

  group('a narrow screen', () {
    const longEntry = LibraryExercise(
      name: 'Standing Hamstring Stretch With A Very Long Name',
      primaryMuscles: ['Hamstrings'],
      instructions: ['Reach for the toes.'],
      equipment: [],
      category: 'stretching',
      tips: ['Breathe out as you fold, and keep the back flat.'],
    );

    testWidgets('lays every tab out on a 320dp phone', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _screen(
          provider: seededProvider(today: _today),
          catalog: ExerciseCatalog(
            api: ExerciseApiClient(
              client: MockClient((_) async => http.Response('down', 500)),
            ),
            bundled: () async => const [longEntry],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'My workouts');

      await openDiscover(tester);
      await settleCatalog(tester);
      await tester.pump();
      // A catalogue card is an image, a title, a muscle and up to two lines of
      // tips. On a 320dp phone it is handed about 104dp of width, and the text
      // has to give up lines rather than run past the bottom of the card.
      expect(tester.takeException(), isNull, reason: 'Discover');

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Saved');
    });
  });

  group('the week card', () {
    testWidgets('names this week, not a session weeks out', (tester) async {
      final far = Workout(
        id: 'far',
        title: 'Session Three Weeks Out',
        date: _today.add(const Duration(days: 21)),
        status: WorkoutStatus.planned,
        durationMin: 45,
        estimatedKcal: 400,
        targetMuscleGroups: const ['Chest'],
        equipment: const [],
        logs: const [],
      );

      await tester.pumpWidget(
        _screen(
          provider: WorkoutProvider(today: _today, workouts: [far]),
        ),
      );
      await tester.pumpAndSettle();

      // The panel is labelled THIS WEEK, so it cannot answer with a plan from
      // three weeks out; the rotation is where that session belongs.
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('NOTHING PLANNED'), findsOneWidget);
      expect(find.text('0 of 4 sessions done'), findsOneWidget);
      expect(find.text('SESSION THREE WEEKS OUT'), findsOneWidget);
      expect(find.text('NEXT SESSION'), findsOneWidget);
    });
  });

  group('a sparse session', () {
    testWidgets('leaves no blank meta line', (tester) async {
      final bare = Workout(
        id: 'bare',
        title: 'Bare Session',
        date: _today,
        status: WorkoutStatus.planned,
        durationMin: 0,
        estimatedKcal: 0,
        targetMuscleGroups: const [],
        equipment: const [],
        logs: const [],
      );

      await tester.pumpWidget(
        _screen(
          provider: WorkoutProvider(today: _today, workouts: [bare]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BARE SESSION'), findsWidgets);
      // No duration, no muscles, no logged sets: an empty meta line would
      // still take a line's height and leave a gap under the title. The search
      // field's own editable text is empty too, hence the Text-specific finder.
      expect(
        find.byWidgetPredicate((widget) => widget is Text && widget.data == ''),
        findsNothing,
      );
    });
  });
  group('saved exercises', () {
    const barbellCurl = LibraryExercise(
      name: 'Barbell Curl',
      primaryMuscles: ['biceps'],
      instructions: ['Curl the bar.'],
      equipment: ['Barbell'],
      category: 'strength',
    );

    ExerciseCatalog catalog() => ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async => http.Response('down', 500)),
      ),
      bundled: () async => const [barbellCurl],
    );

    testWidgets('keeping one in Discover puts it in Saved', (tester) async {
      final provider = WorkoutProvider();

      await tester.pumpWidget(_screen(catalog: catalog(), provider: provider));
      await openDiscover(tester);
      await settleCatalog(tester);

      expect(find.byTooltip('Save this exercise'), findsOneWidget);
      await tester.tap(find.byTooltip('Save this exercise'));
      await tester.pump();

      expect(provider.isSaved(barbellCurl.id), isTrue);
      expect(find.byTooltip('Remove from saved'), findsOneWidget);

      // The saved list is the stored copy, so it renders whether or not the
      // catalogue could be reached again.
      await tester.tap(find.text('Saved'));
      await tester.pump();

      expect(find.text('SAVED EXERCISES'), findsOneWidget);
      expect(find.text('1 exercise'), findsOneWidget);
      expect(find.text('Barbell Curl'), findsOneWidget);
      expect(find.textContaining('biceps · saved'), findsOneWidget);
    });

    testWidgets('removing it from Saved leaves the empty state', (
      tester,
    ) async {
      final provider = WorkoutProvider();

      await tester.pumpWidget(_screen(catalog: catalog(), provider: provider));
      await openDiscover(tester);
      await settleCatalog(tester);
      await tester.tap(find.byTooltip('Save this exercise'));
      await tester.pump();
      await tester.tap(find.text('Saved'));
      await tester.pump();

      await tester.tap(find.byTooltip('Remove from saved'));
      await tester.pump();

      expect(provider.savedExercises, isEmpty);
      expect(find.text('NOTHING SAVED YET.'), findsOneWidget);
    });

    testWidgets('the search field narrows the saved list', (tester) async {
      final provider = WorkoutProvider();

      await tester.pumpWidget(_screen(catalog: catalog(), provider: provider));
      await openDiscover(tester);
      await settleCatalog(tester);
      await tester.tap(find.byTooltip('Save this exercise'));
      await tester.pump();
      await tester.tap(find.text('Saved'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'deadlift');
      await tester.pump();

      expect(find.textContaining('No saved exercises match'), findsOneWidget);

      // The row shows the muscle it trains, so the field finds it by that too,
      // the way the catalogue does.
      await tester.enterText(find.byType(TextField), 'biceps');
      await tester.pump();

      expect(find.text('Barbell Curl'), findsOneWidget);
      expect(find.textContaining('No saved exercises match'), findsNothing);
    });
  });
}
