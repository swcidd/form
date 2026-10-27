import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/taxonomy.dart';
import 'package:plus_one/models/workout.dart';

void main() {
  group('ExerciseCategory', () {
    test('parses every wire name it ships', () {
      for (final category in ExerciseCategory.values) {
        expect(ExerciseCategory.tryParse(category.wire), category);
      }
    });

    test('tolerates the older spellings', () {
      expect(
        ExerciseCategory.tryParse('stretching'),
        ExerciseCategory.mobility,
      );
      expect(ExerciseCategory.tryParse('mobility'), ExerciseCategory.mobility);
      expect(
        ExerciseCategory.tryParse('calisthenics-skills'),
        ExerciseCategory.calisthenicSkills,
      );
      expect(
        ExerciseCategory.tryParse('plyometric'),
        ExerciseCategory.plyometrics,
      );
    });

    test('unknown and empty values stay unclassified', () {
      expect(ExerciseCategory.tryParse(null), isNull);
      expect(ExerciseCategory.tryParse('  '), isNull);
      expect(ExerciseCategory.tryParse('yoga'), isNull);
    });

    test('the new disciplines are calisthenic branches', () {
      expect(ExerciseCategory.calisthenics.isCalisthenic, isTrue);
      expect(ExerciseCategory.calisthenicSkills.isCalisthenic, isTrue);
      expect(ExerciseCategory.strength.isCalisthenic, isFalse);
    });
  });

  group('Modality', () {
    test('exposes the three added disciplines', () {
      final labels = Modality.values.map((m) => m.label);

      expect(
        labels,
        containsAll(['Calisthenics', 'Calisthenic skills', 'Plyometrics']),
      );
    });

    test('groups the matching exercise categories', () {
      expect(
        Modality.calisthenics.categories,
        contains(ExerciseCategory.calisthenics),
      );
      expect(
        Modality.calisthenicSkills.categories,
        contains(ExerciseCategory.calisthenicSkills),
      );
      expect(
        Modality.plyometrics.categories,
        contains(ExerciseCategory.plyometrics),
      );
    });

    test('round trips through the wire name', () {
      for (final modality in Modality.values) {
        expect(Modality.tryParse(modality.wire), modality);
      }
      expect(Modality.tryParse('hiit'), Modality.circuitHiit);
      expect(Modality.tryParse('warm-up'), Modality.mobilityWarmUp);
    });
  });

  group('Equipment', () {
    test('maps catalogue spellings to the filter vocabulary', () {
      expect(Equipment.fromCatalogue('body only'), Equipment.bodyweight);
      expect(Equipment.fromCatalogue('none'), Equipment.bodyweight);
      expect(Equipment.fromCatalogue('kettlebells'), Equipment.dumbbell);
      expect(Equipment.fromCatalogue('bench'), Equipment.machine);
      expect(Equipment.fromCatalogue('bands'), Equipment.other);
      expect(equipmentLabel('body only'), 'Bodyweight');
    });
  });

  group('DurationBand', () {
    test('bands minutes at the boundaries', () {
      expect(DurationBand.fromMinutes(30), DurationBand.short);
      expect(DurationBand.fromMinutes(45), DurationBand.medium);
      expect(DurationBand.fromMinutes(61), DurationBand.long);
    });
  });

  group('Workout classification', () {
    Workout workout({Modality? modality, int minutes = 45}) => Workout(
      id: 'w1',
      title: 'Skill practice',
      date: DateTime(2026, 10, 6),
      status: WorkoutStatus.planned,
      durationMin: minutes,
      estimatedKcal: 0,
      targetMuscleGroups: const [],
      equipment: const [],
      logs: const [],
      modality: modality,
    );

    test('duration band is derived, not stored', () {
      expect(workout(minutes: 20).durationBand, DurationBand.short);
      expect(workout(minutes: 45).durationBand, DurationBand.medium);
      expect(workout(minutes: 90).durationBand, DurationBand.long);
    });

    test('classification survives a JSON round trip', () {
      final original = workout(modality: Modality.calisthenics).copyWith(
        split: WorkoutSplit.pull,
        goal: TrainingGoal.strength,
        kind: WorkoutKind.routine,
      );

      final restored = Workout.fromJson(
        Map<String, dynamic>.from(original.toJson()),
      );

      expect(restored, original);
      expect(restored.modality, Modality.calisthenics);
      expect(restored.split, WorkoutSplit.pull);
      expect(restored.goal, TrainingGoal.strength);
      expect(restored.kind, WorkoutKind.routine);
    });

    test('unclassified sessions stay null rather than defaulted', () {
      final restored = Workout.fromJson(
        Map<String, dynamic>.from(workout().toJson()),
      );

      expect(restored.modality, isNull);
      expect(restored.split, isNull);
      expect(restored.goal, isNull);
      expect(restored.kind, WorkoutKind.session);
    });

    test('the later lifecycle states exist alongside rest days', () {
      expect(WorkoutStatus.values, contains(WorkoutStatus.inProgress));
      expect(WorkoutStatus.values, contains(WorkoutStatus.skipped));
      expect(WorkoutStatus.values, contains(WorkoutStatus.rest));
      expect(WorkoutStatus.inProgress.label, 'In progress');
      expect(WorkoutStatus.skipped.label, 'Skipped');
    });
  });
}
