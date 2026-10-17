import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plus_one/data/exercise_api_client.dart';
import 'package:plus_one/data/exercise_catalog.dart';
import 'package:plus_one/exercise_library.dart';
import 'package:plus_one/screens/library_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

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

Widget _screen(ExerciseCatalog catalog) => MaterialApp(
  theme: AppTheme.light(),
  home: LibraryScreen(catalog: catalog),
);

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

    await tester.pumpWidget(_screen(catalog));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await settleCatalog(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Barbell Curl'), findsOneWidget);
    // Live data, so no offline notice.
    expect(find.textContaining('Offline'), findsNothing);
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
          primaryMuscle: 'biceps',
          instructions: 'Curl the bar.',
          equipment: ['Barbell'],
          category: 'strength',
        ),
      ],
    );

    await tester.pumpWidget(_screen(catalog));
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

    await tester.pumpWidget(_screen(catalog));
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

    await tester.pumpWidget(_screen(catalog));
    await settleCatalog(tester);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await settleCatalog(tester);

    expect(find.text('Barbell Curl'), findsOneWidget);
    expect(calls, 2);
  });
}
