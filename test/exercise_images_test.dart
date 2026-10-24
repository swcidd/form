import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/data/exercise_images.dart';
import 'package:plus_one/exercise_library.dart';

LibraryExercise _exercise({
  String category = 'strength',
  List<String> primary = const [],
  List<String> images = const [],
}) => LibraryExercise(
  name: 'Test exercise',
  primaryMuscles: primary,
  equipment: const ['body only'],
  category: category,
  images: images,
);

void main() {
  group('ExerciseImages.forExercise', () {
    test('uses the stretching photograph regardless of muscle', () {
      final url = ExerciseImages.forExercise(
        _exercise(category: 'stretching', primary: const ['chest']),
      );

      expect(url, contains('photo-1544367567-0f2fcb009e0b'));
      expect(url, startsWith('https://images.unsplash.com/'));
      expect(url, contains('auto=format'));
      expect(url, contains('w=600'));
    });

    test('maps the primary muscle onto its group', () {
      expect(
        ExerciseImages.forExercise(_exercise(primary: const ['abdominals'])),
        contains('photo-1571019613454-1cb2f99b2d8b'),
      );
      expect(
        ExerciseImages.forExercise(_exercise(primary: const ['chest'])),
        contains('photo-1534438327276-14e5300c3a48'),
      );
      expect(
        ExerciseImages.forExercise(_exercise(primary: const ['lats'])),
        contains('photo-1526506118085-60ce8714f8c5'),
      );
      expect(
        ExerciseImages.forExercise(_exercise(primary: const ['quads'])),
        contains('photo-1574680096145-d05b474e2155'),
      );
      expect(
        ExerciseImages.forExercise(_exercise(primary: const ['biceps'])),
        contains('photo-1581009146145-b5ef050c2e1e'),
      );
    });

    test('handles the capitalised muscles the live API sends', () {
      final url = ExerciseImages.forExercise(
        _exercise(primary: const ['Hamstrings', 'Glutes']),
      );

      expect(url, contains('photo-1574680096145-d05b474e2155'));
    });

    test('handles wger muscle labels', () {
      expect(
        ExerciseImages.forExercise(_exercise(primary: const ['Quadriceps'])),
        contains('photo-1574680096145-d05b474e2155'),
      );
      expect(
        ExerciseImages.forExercise(_exercise(primary: const ['Shoulders'])),
        contains('photo-1534438327276-14e5300c3a48'),
      );
    });

    test('falls back to the category when no muscle is listed', () {
      expect(
        ExerciseImages.forExercise(_exercise(category: 'Arms')),
        contains('photo-1581009146145-b5ef050c2e1e'),
      );
      expect(
        ExerciseImages.forExercise(_exercise(category: 'Back')),
        contains('photo-1526506118085-60ce8714f8c5'),
      );
    });

    test('prefers a recognised muscle over a broad category', () {
      final url = ExerciseImages.forExercise(
        _exercise(category: 'Abs', primary: const ['Glutes']),
      );

      expect(url, contains('photo-1574680096145-d05b474e2155'));
    });

    test('falls back to the strength photograph for an unknown group', () {
      final url = ExerciseImages.forExercise(
        _exercise(primary: const ['rotator cuff']),
      );

      expect(url, contains('photo-1534438327276-14e5300c3a48'));
    });

    test('uses the plyometrics photograph by category', () {
      final url = ExerciseImages.forExercise(
        _exercise(category: 'plyometrics', primary: const ['quads']),
      );

      expect(url, contains('photo-1518611012118-696072aa579a'));
    });
  });

  group('ExerciseImages.bundledAsset', () {
    test('ignores the relative paths the source catalogue carries', () {
      final exercise = _exercise(images: const ['3_4_Sit-Up/0.jpg']);

      expect(ExerciseImages.bundledAsset(exercise), isNull);
    });

    test('keeps a real bundled asset path', () {
      final exercise = _exercise(
        images: const ['assets/images/free-db/barbell-curl_1.png'],
      );

      expect(
        ExerciseImages.bundledAsset(exercise),
        'assets/images/free-db/barbell-curl_1.png',
      );
    });

    test('returns null when the entry has no images', () {
      expect(ExerciseImages.bundledAsset(_exercise()), isNull);
    });
  });
}
