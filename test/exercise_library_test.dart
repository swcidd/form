import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/exercise_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryExercise', () {
    test('reads the canonical shape', () {
      final exercise = LibraryExercise.fromJson(const {
        'id': 'barbell-bench-press',
        'name': 'Barbell Bench Press',
        'aliases': ['flat bench press'],
        'primaryMuscles': ['chest'],
        'secondaryMuscles': ['shoulders', 'triceps'],
        'instructions': ['Lie on the bench.', 'Press the bar.'],
        'equipment': ['barbell', 'bench'],
        'category': 'strength',
        'level': 'intermediate',
        'force': 'push',
        'mechanic': 'compound',
        'description': 'The classic press.',
        'tips': ['Keep the shoulder blades pinned.'],
        'video': 'https://example.com/bench.mp4',
        'images': ['Bench_Press/0.jpg'],
      });

      expect(exercise.id, 'barbell-bench-press');
      expect(exercise.name, 'Barbell Bench Press');
      expect(exercise.aliases, ['flat bench press']);
      expect(exercise.primaryMuscles, ['chest']);
      expect(exercise.secondaryMuscles, ['shoulders', 'triceps']);
      expect(exercise.primaryMuscle, 'chest');
      expect(exercise.secondaryMuscle, 'shoulders');
      expect(exercise.instructions, ['Lie on the bench.', 'Press the bar.']);
      expect(exercise.instructionsText, 'Lie on the bench. Press the bar.');
      expect(exercise.equipment, ['barbell', 'bench']);
      expect(exercise.category, 'strength');
      expect(exercise.level, 'intermediate');
      expect(exercise.force, 'push');
      expect(exercise.mechanic, 'compound');
      expect(exercise.description, 'The classic press.');
      expect(exercise.tips, ['Keep the shoulder blades pinned.']);
      expect(exercise.tipsText, 'Keep the shoulder blades pinned.');
      expect(exercise.video, 'https://example.com/bench.mp4');
      expect(exercise.images, ['Bench_Press/0.jpg']);
    });

    test('round trips every field', () {
      const exercise = LibraryExercise(
        catalogueId: 'barbell-curl',
        name: 'Barbell Curl',
        aliases: ['standing curl'],
        primaryMuscles: ['biceps'],
        secondaryMuscles: ['forearms'],
        instructions: ['Curl the bar slowly.'],
        equipment: ['barbell'],
        category: 'strength',
        level: 'intermediate',
        force: 'pull',
        mechanic: 'isolation',
        description: 'A curl with a bar.',
        tips: ['Keep the elbows fixed.'],
        video: 'https://example.com/curl.mp4',
        images: ['Barbell_Curl/0.jpg'],
      );

      final decoded = LibraryExercise.fromJson(exercise.toJson());

      expect(decoded.id, exercise.id);
      expect(decoded.name, exercise.name);
      expect(decoded.aliases, exercise.aliases);
      expect(decoded.primaryMuscles, exercise.primaryMuscles);
      expect(decoded.secondaryMuscles, exercise.secondaryMuscles);
      expect(decoded.instructions, exercise.instructions);
      expect(decoded.equipment, exercise.equipment);
      expect(decoded.category, exercise.category);
      expect(decoded.level, exercise.level);
      expect(decoded.force, exercise.force);
      expect(decoded.mechanic, exercise.mechanic);
      expect(decoded.description, exercise.description);
      expect(decoded.tips, exercise.tips);
      expect(decoded.video, exercise.video);
      expect(decoded.images, exercise.images);
    });

    test('reads a saved row written before the canonical model', () {
      // The schema has no column per field, so a payload is what an earlier
      // version wrote. Missing or wrongly typed fields must not cost the user
      // their library.
      final exercise = LibraryExercise.fromJson(const {
        'name': 'Barbell Curl',
        'primaryMuscle': 'biceps',
        'secondaryMuscle': 'forearms',
        'instructions': 'Curl the bar.',
        'equipment': <String>['Barbell'],
        'category': 'strength',
        'level': 42,
        'images': 'not a list',
        'tips': 'Keep the elbows fixed.\nSqueeze at the top.',
        'variations': ['Hammer curl'],
      });

      expect(exercise.name, 'Barbell Curl');
      expect(exercise.primaryMuscles, ['biceps']);
      expect(exercise.secondaryMuscles, ['forearms']);
      expect(exercise.instructions, ['Curl the bar.']);
      expect(exercise.equipment, ['Barbell']);
      expect(exercise.level, isNull);
      expect(exercise.force, isNull);
      expect(exercise.mechanic, isNull);
      expect(exercise.images, isEmpty);
      expect(exercise.tips, ['Keep the elbows fixed.', 'Squeeze at the top.']);
      expect(exercise.aliases, ['Hammer curl']);
    });

    test('falls back to the normalised name when a row has no id', () {
      const exercise = LibraryExercise(
        name: '3/4 Sit-Up',
        equipment: ['body only'],
        category: 'strength',
      );

      expect(exercise.id, '34situp');
      expect(exercise.primaryMuscle, '');
      expect(exercise.secondaryMuscle, isNull);
      expect(exercise.tipsText, isNull);
      expect(exercise.variations, isNull);
    });

    test('an empty payload becomes a readable, empty entry', () {
      final exercise = LibraryExercise.fromJson(const {});

      expect(exercise.name, '');
      expect(exercise.id, '');
      expect(exercise.primaryMuscle, '');
      expect(exercise.equipment, isEmpty);
      expect(exercise.images, isEmpty);
    });
  });

  group('ExerciseLibrary.loadAll', () {
    test('loads the single canonical asset', () async {
      final exercises = await ExerciseLibrary.loadAll();

      expect(exercises, hasLength(74));
      expect(exercises.every((e) => e.name.isNotEmpty), isTrue);
      expect(exercises.every((e) => e.id.isNotEmpty), isTrue);
      expect(exercises.every((e) => e.primaryMuscles.isNotEmpty), isTrue);
      expect(exercises.every((e) => e.equipment.isNotEmpty), isTrue);
      expect(exercises.every((e) => e.instructions.isNotEmpty), isTrue);
    });

    test('ships the calisthenics and skill categories', () async {
      final exercises = await ExerciseLibrary.loadAll();
      final categories = exercises.map((e) => e.category).toSet();

      expect(
        categories,
        containsAll(['calisthenics', 'calisthenic_skills', 'plyometrics']),
      );
      expect(exercises.where((e) => e.category == 'calisthenics'), isNotEmpty);
      expect(
        exercises.where((e) => e.category == 'calisthenic_skills'),
        isNotEmpty,
      );
    });

    test('serves one entry per stable id and per normalised name', () async {
      final exercises = await ExerciseLibrary.loadAll();

      expect(exercises.map((e) => e.id).toSet(), hasLength(exercises.length));
      expect(
        exercises.map((e) => LibraryExercise.keyFor(e.name)).toSet(),
        hasLength(exercises.length),
      );
    });

    test('normalises the two source vocabularies', () async {
      final exercises = await ExerciseLibrary.loadAll();
      final muscles = <String>{
        for (final e in exercises) ...[
          ...e.primaryMuscles,
          ...e.secondaryMuscles,
        ],
      };
      final equipment = {for (final e in exercises) ...e.equipment};

      expect(muscles, isNot(contains('abs')));
      expect(muscles, isNot(contains('quadriceps')));
      expect(muscles, contains('abdominals'));
      expect(muscles, contains('quads'));
      expect(equipment, isNot(contains('none')));
      expect(equipment, isNot(contains('kettlebell')));
      expect(equipment, contains('body only'));
      expect(equipment, contains('kettlebells'));
    });

    test('keeps both sources text and media on a matched entry', () async {
      final exercises = await ExerciseLibrary.loadAll();
      final sitUp = exercises.singleWhere((e) => e.name == '3/4 Sit-Up');

      expect(sitUp.id, '3_4_Sit-Up');
      expect(sitUp.primaryMuscles, ['abdominals']);
      expect(sitUp.equipment, ['body only']);
      expect(sitUp.images, ['3_4_Sit-Up/0.jpg', '3_4_Sit-Up/1.jpg']);
      expect(sitUp.description, isNotNull);
      expect(sitUp.video, isNotNull);
      expect(sitUp.level, 'beginner');
      expect(sitUp.force, 'pull');
      expect(sitUp.mechanic, 'compound');
    });

    test(
      'does not invent a level or force for an exercemus-only entry',
      () async {
        final exercises = await ExerciseLibrary.loadAll();
        final crunch = exercises.singleWhere((e) => e.name == 'Machine Crunch');

        expect(crunch.level, isNull);
        expect(crunch.force, isNull);
        expect(crunch.mechanic, isNull);
        expect(crunch.images, isEmpty);
      },
    );
  });
}
