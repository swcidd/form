import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:plus_one/data/exercise_api_client.dart';

/// One entry in the shape wger.de actually serves, trimmed to the fields the
/// client reads (checked against the live API's `/api/v2/exerciseinfo/`).
Map<String, Object?> wgerEntry({
  int language = 2,
  String name = '2 Handed Kettlebell Swing',
}) => {
  'id': 9,
  'category': {'id': 10, 'name': 'Abs'},
  'muscles': [
    {'id': 11, 'name': 'Biceps femoris', 'name_en': 'Hamstrings'},
    {'id': 8, 'name': 'Gluteus maximus', 'name_en': 'Glutes'},
  ],
  'muscles_secondary': [
    {'id': 6, 'name': 'Rectus abdominis', 'name_en': 'Abs'},
  ],
  'equipment': [
    {'id': 10, 'name': 'Kettlebell'},
  ],
  'translations': [
    {
      'id': 345,
      'language': language,
      'name': name,
      'description': '<p>Two Handed Russian Style Kettlebell swing</p>\n',
    },
  ],
};

ExerciseApiClient clientReturning(String body, {int status = 200}) =>
    ExerciseApiClient(
      client: MockClient((_) async => http.Response(body, status)),
    );

void main() {
  test('maps a wger entry onto the library model', () async {
    final client = ExerciseApiClient(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v2/exerciseinfo/');
        expect(request.url.queryParameters['language'], '2');
        expect(request.url.queryParameters['limit'], '3');
        return http.Response(
          jsonEncode({
            'count': 1,
            'results': [wgerEntry()],
          }),
          200,
        );
      }),
    );

    final exercises = await client.fetchExercises(limit: 3);

    expect(exercises, hasLength(1));
    final exercise = exercises.single;
    expect(exercise.id, 'wger-9');
    expect(exercise.name, '2 Handed Kettlebell Swing');
    expect(exercise.category, 'Abs');
    // English muscle names win over the Latin ones.
    expect(exercise.primaryMuscles, ['Hamstrings', 'Glutes']);
    expect(exercise.secondaryMuscles, ['Abs']);
    expect(exercise.equipment, ['Kettlebell']);
    // The card shows plain text, so the HTML tags cannot survive parsing.
    expect(exercise.instructions, [
      'Two Handed Russian Style Kettlebell swing',
    ]);
  });

  test('falls back to the first translation when English is missing', () async {
    final client = clientReturning(
      jsonEncode({
        'results': [wgerEntry(language: 1, name: 'Kettlebell-Schwung')],
      }),
    );

    final exercises = await client.fetchExercises();

    expect(exercises.single.name, 'Kettlebell-Schwung');
  });

  test('skips entries with no usable translation', () async {
    final client = clientReturning(
      jsonEncode({
        'count': 3,
        'results': [
          wgerEntry(),
          {
            'category': {'name': 'Chest'},
            'translations': [
              {'language': 2, 'name': '   ', 'description': ''},
            ],
          },
          {
            'category': {'name': 'Chest'},
          },
        ],
      }),
    );

    final exercises = await client.fetchExercises();

    expect(exercises, hasLength(1));
  });

  test('an HTTP error is an ExerciseApiException, not a crash', () async {
    final client = clientReturning('rate limited', status: 429);

    expect(client.fetchExercises(), throwsA(isA<ExerciseApiException>()));
  });

  test('a malformed body is an ExerciseApiException', () async {
    final client = clientReturning('<html>not json</html>');

    expect(client.fetchExercises(), throwsA(isA<ExerciseApiException>()));
  });

  test('a body without a results list is an ExerciseApiException', () async {
    final client = clientReturning(jsonEncode({'count': 0}));

    expect(client.fetchExercises(), throwsA(isA<ExerciseApiException>()));
  });
}
