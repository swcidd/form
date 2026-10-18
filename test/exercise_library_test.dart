import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/exercise_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryExercise.fromExercemus', () {
    test('reads muscles, equipment, instructions and variations', () {
      final exercise = LibraryExercise.fromExercemus({
        'name': 'Barbell Bench Press',
        'category': 'strength',
        'primary_muscles': ['chest'],
        'secondary_muscles': ['shoulders', 'triceps'],
        'equipment': ['barbell', 'bench'],
        'instructions': ['Lie on the bench.', 'Press the bar.'],
        'variation_on': ['flat bench press'],
      });

      expect(exercise.name, 'Barbell Bench Press');
      expect(exercise.primaryMuscle, 'chest');
      expect(exercise.secondaryMuscle, 'shoulders');
      expect(exercise.equipment, ['barbell', 'bench']);
      expect(exercise.instructions, 'Lie on the bench. Press the bar.');
      expect(exercise.variations, ['flat bench press']);
      expect(exercise.tips, isNull);
      expect(exercise.video, isNull);
    });

    test('falls back for missing data instead of throwing', () {
      final exercise = LibraryExercise.fromExercemus({'name': 'Bare'});

      expect(exercise.primaryMuscle, 'unknown');
      expect(exercise.secondaryMuscle, isNull);
      expect(exercise.instructions, '');
      expect(exercise.equipment, isEmpty);
      expect(exercise.images, isEmpty);
      expect(exercise.level, 'beginner');
    });

    test('keeps tips and video when present', () {
      final exercise = LibraryExercise.fromExercemus({
        'name': 'Curl',
        'tips': ['Keep the elbows still.', 'Squeeze at the top.'],
        'video': 'https://example.com/curl.mp4',
      });

      expect(exercise.tips, 'Keep the elbows still.\nSqueeze at the top.');
      expect(exercise.video, 'https://example.com/curl.mp4');
    });

    test('accepts the variations_on spelling some entries use', () {
      final exercise = LibraryExercise.fromExercemus({
        'name': 'Incline Bench Press',
        'variations_on': ['flat bench press'],
      });

      expect(exercise.variations, ['flat bench press']);
    });
  });

  group('LibraryExercise.fromFreeDb', () {
    test('reads the bare-string equipment the data set really uses', () {
      final exercise = LibraryExercise.fromFreeDb({
        'name': '3/4 Sit-Up',
        'force': 'pull',
        'level': 'beginner',
        'equipment': 'body only',
        'primaryMuscles': ['abdominals'],
        'secondaryMuscles': <String>[],
        'instructions': ['Sit up.'],
        'category': 'strength',
        'images': ['3_4_Sit-Up/0.jpg'],
      });

      expect(exercise.equipment, ['body only']);
      expect(exercise.primaryMuscle, 'abdominals');
      expect(exercise.secondaryMuscle, isNull);
      expect(exercise.level, 'beginner');
      expect(exercise.force, 'pull');
      expect(exercise.images, ['3_4_Sit-Up/0.jpg']);
    });

    test('also accepts a list of equipment values', () {
      final exercise = LibraryExercise.fromFreeDb({
        'name': 'Bench Press',
        'equipment': ['barbell', 'bench'],
      });

      expect(exercise.equipment, ['barbell', 'bench']);
    });
  });

  group('ExerciseLibrary.merge', () {
    test('keeps exercemus text and takes media from free-exercise-db', () {
      final merged = ExerciseLibrary.merge(
        exercemus: [
          {
            'name': 'Barbell Bench Press',
            'category': 'strength',
            'primary_muscles': ['chest'],
            'equipment': ['barbell'],
            'instructions': ['From exercemus.'],
            'variation_on': ['flat bench press'],
          },
        ],
        freeDb: [
          {
            'name': 'Barbell Bench Press',
            'level': 'intermediate',
            'force': 'push',
            'equipment': 'barbell',
            'images': ['Barbell_Bench_Press/0.jpg'],
            'instructions': ['From free-exercise-db.'],
          },
        ],
      );

      expect(merged, hasLength(1));
      final exercise = merged.single;
      expect(exercise.instructions, 'From exercemus.');
      expect(exercise.variations, ['flat bench press']);
      expect(exercise.level, 'intermediate');
      expect(exercise.force, 'push');
      expect(exercise.images, ['Barbell_Bench_Press/0.jpg']);
    });

    test('matches names across punctuation and case', () {
      final merged = ExerciseLibrary.merge(
        exercemus: [
          {
            'name': '3/4 Sit-Up',
            'primary_muscles': ['abdominals'],
          },
        ],
        freeDb: [
          {'name': '3-4 sit up', 'level': 'expert'},
        ],
      );

      expect(merged, hasLength(1));
      expect(merged.single.name, '3/4 Sit-Up');
      expect(merged.single.level, 'expert');
    });

    test('keeps entries only one source has', () {
      final merged = ExerciseLibrary.merge(
        exercemus: [
          {'name': 'Only Exercemus'},
        ],
        freeDb: [
          {'name': 'Only Free Db'},
        ],
      );

      expect(merged, hasLength(2));
      expect(
        merged.map((e) => e.name),
        containsAll(['Only Exercemus', 'Only Free Db']),
      );
    });

    test('drops an entry with no name from either source', () {
      final merged = ExerciseLibrary.merge(
        exercemus: [
          {
            'name': '',
            'primary_muscles': ['chest'],
          },
          {'name': 'Named'},
        ],
        freeDb: [
          {'name': '   ', 'level': 'expert'},
        ],
      );

      // A nameless entry has no key to merge on and nothing to show in a card,
      // so two of them would collide on the empty name rather than be two
      // exercises. The wger client drops its own for the same reason.
      expect(merged, hasLength(1));
      expect(merged.single.name, 'Named');
    });
  });

  group('ExerciseLibrary.loadAll', () {
    test('parses the bundled assets and merges them', () async {
      final exercises = await ExerciseLibrary.loadAll();

      expect(exercises, isNotEmpty);
      expect(exercises.length, greaterThan(50));
      expect(exercises.every((e) => e.name.isNotEmpty), isTrue);
      expect(
        exercises.map((e) => e.name.toLowerCase()),
        contains('3/4 sit-up'),
      );
    });

    test('serves one entry per normalized name', () async {
      final exercises = await ExerciseLibrary.loadAll();
      final keys = [
        for (final e in exercises)
          e.name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ''),
      ];

      expect(keys.length, keys.toSet().length);
    });
  });
}
