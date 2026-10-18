import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/exercise_library.dart';
import 'package:plus_one/models/saved_exercise.dart';

LibraryExercise _exercise({String name = 'Barbell Curl'}) => LibraryExercise(
  name: name,
  primaryMuscle: 'biceps',
  secondaryMuscle: 'forearms',
  instructions: 'Curl the bar slowly.',
  equipment: const ['Barbell', 'Curl bar'],
  category: 'strength',
  level: 'intermediate',
  force: 'isolation',
  images: const ['assets/images/free-db/barbell-curl_1.png'],
  tips: 'Keep the elbows fixed.',
  video: 'https://example.com/curl.mp4',
  variations: const ['Incline dumbbell curl', 'Hammer curl'],
);

void main() {
  group('identity', () {
    test('is the normalised name, so spellings cannot split an entry', () {
      expect(LibraryExercise.keyFor('3/4 Sit-Up'), '34situp');
      expect(LibraryExercise.keyFor('3-4 sit up'), '34situp');
      expect(_exercise().id, LibraryExercise.keyFor('Barbell Curl'));
    });
  });

  group('json', () {
    test('round trips every field', () {
      final exercise = _exercise();

      final decoded = LibraryExercise.fromJson(exercise.toJson());

      expect(decoded.name, exercise.name);
      expect(decoded.primaryMuscle, exercise.primaryMuscle);
      expect(decoded.secondaryMuscle, exercise.secondaryMuscle);
      expect(decoded.instructions, exercise.instructions);
      expect(decoded.equipment, exercise.equipment);
      expect(decoded.category, exercise.category);
      expect(decoded.level, exercise.level);
      expect(decoded.force, exercise.force);
      expect(decoded.images, exercise.images);
      expect(decoded.tips, exercise.tips);
      expect(decoded.video, exercise.video);
      expect(decoded.variations, exercise.variations);
    });

    test('reads a saved row written before the code changed', () {
      // The schema has no column per field, so a payload is what an earlier
      // version wrote. Missing or wrongly typed fields must not cost the user
      // their library.
      final exercise = LibraryExercise.fromJson(const {
        'name': 'Barbell Curl',
        'primaryMuscle': 'biceps',
        'instructions': 'Curl the bar.',
        'equipment': <String>['Barbell'],
        'category': 'strength',
        'level': 42,
        'images': 'not a list',
        'tips': null,
        'variations': null,
      });

      expect(exercise.name, 'Barbell Curl');
      expect(exercise.level, 'beginner');
      expect(exercise.force, 'pull');
      expect(exercise.images, isEmpty);
      expect(exercise.secondaryMuscle, isNull);
      expect(exercise.tips, isNull);
      expect(exercise.variations, isNull);
    });

    test('an empty payload becomes a readable, empty entry', () {
      final exercise = LibraryExercise.fromJson(const {});

      expect(exercise.name, '');
      expect(exercise.primaryMuscle, '');
      expect(exercise.equipment, isEmpty);
      expect(exercise.images, isEmpty);
    });
  });

  group('SavedExercise', () {
    test('keeps its identity and the moment it was kept', () {
      final at = DateTime(2026, 10, 18, 9, 30);
      final saved = SavedExercise(exercise: _exercise(), savedAt: at);

      expect(saved.id, LibraryExercise.keyFor('Barbell Curl'));
      expect(saved.savedAt, at);
      expect(saved.exercise.name, 'Barbell Curl');
    });
  });
}
