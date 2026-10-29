import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/taxonomy.dart';
import 'package:plus_one/models/workout.dart';

/// `copyWith`'s three classification fields take `null` as "clear this".
///
/// The alternative - `null` meaning "leave it alone" - makes a value impossible
/// to remove. That is not hypothetical: it is why the edit and the save screens
/// both ended up rebuilding the whole record by hand, and why either rebuild
/// would silently drop any field the model gained later.
void main() {
  Workout session() => Workout(
    id: 'w1',
    title: 'Lower Body A',
    date: DateTime(2026, 10, 27),
    status: WorkoutStatus.planned,
    durationMin: 55,
    estimatedKcal: 0,
    targetMuscleGroups: const [],
    equipment: const [],
    logs: const [],
    modality: Modality.strength,
    split: WorkoutSplit.lower,
    goal: TrainingGoal.hypertrophy,
  );

  test('omitting a classification keeps it', () {
    final renamed = session().copyWith(title: 'Leg Day');

    expect(renamed.title, 'Leg Day');
    expect(renamed.modality, Modality.strength);
    expect(renamed.split, WorkoutSplit.lower);
    expect(renamed.goal, TrainingGoal.hypertrophy);
  });

  test('passing null clears one classification and leaves the others', () {
    final cleared = session().copyWith(split: null);

    expect(cleared.split, isNull);
    expect(cleared.modality, Modality.strength);
    expect(cleared.goal, TrainingGoal.hypertrophy);
  });

  test('all three can be cleared at once', () {
    final bare = session().copyWith(modality: null, split: null, goal: null);

    expect(bare.modality, isNull);
    expect(bare.split, isNull);
    expect(bare.goal, isNull);
  });

  test('setting a classification that was unset works', () {
    final bare = session().copyWith(modality: null);
    final set = bare.copyWith(modality: Modality.cardio);

    expect(set.modality, Modality.cardio);
    expect(set.split, WorkoutSplit.lower);
  });
}
