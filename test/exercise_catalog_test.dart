import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plus_one/data/exercise_api_client.dart';
import 'package:plus_one/data/exercise_catalog.dart';
import 'package:plus_one/exercise_library.dart';

const _bundledSeed = LibraryExercise(
  name: 'Bundled Curl',
  primaryMuscles: ['biceps'],
  instructions: ['Curl the bar.'],
  equipment: ['Barbell'],
  category: 'strength',
);

String _wgerBody() => jsonEncode({
  'count': 1,
  'results': [
    {
      'category': {'name': 'Arms'},
      'translations': [
        {'language': 2, 'name': 'Barbell Curl', 'description': ''},
      ],
    },
  ],
});

ExerciseCatalog _catalogWith(
  http.Client client, {
  List<LibraryExercise>? bundled,
}) => ExerciseCatalog(
  api: ExerciseApiClient(client: client),
  bundled: () async => bundled ?? const [_bundledSeed],
);

void main() {
  // The bundled-asset test below reads through rootBundle, which needs the
  // services binding up before there is an asset bundle to ask.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a reachable wger serves the catalogue from the network', () async {
    final catalog = _catalogWith(
      MockClient((_) async => http.Response(_wgerBody(), 200)),
    );

    final result = await catalog.load();

    expect(result.source, CatalogSource.network);
    expect(result.isOffline, isFalse);
    expect(result.exercises.single.name, 'Barbell Curl');
  });

  test('an unreachable wger falls back to the bundled catalogue', () async {
    final catalog = _catalogWith(
      MockClient((_) async => http.Response('service unavailable', 503)),
    );

    final result = await catalog.load();

    expect(result.source, CatalogSource.bundled);
    expect(result.isOffline, isTrue);
    expect(result.exercises.single.name, 'Bundled Curl');
  });

  test('an empty wger answer counts as unreachable', () async {
    final catalog = _catalogWith(
      MockClient((_) async => http.Response(jsonEncode({'results': []}), 200)),
    );

    final result = await catalog.load();

    expect(result.source, CatalogSource.bundled);
    expect(result.exercises, isNotEmpty);
  });

  test('the default fallback is the real bundled data', () async {
    final catalog = ExerciseCatalog(
      api: ExerciseApiClient(
        client: MockClient((_) async => http.Response('nope', 500)),
      ),
    );

    final result = await catalog.load();

    expect(result.source, CatalogSource.bundled);
    expect(result.exercises, isNotEmpty);
  });

  test(
    'a failure of both sources surfaces instead of an empty library',
    () async {
      final catalog = ExerciseCatalog(
        api: ExerciseApiClient(
          client: MockClient((_) async => http.Response('nope', 500)),
        ),
        bundled: () async => throw StateError('assets missing'),
      );

      expect(catalog.load(), throwsStateError);
    },
  );
}
