/// The tag vocabulary an exercise row and its detail screen share.
///
/// One place, because the picker row, the detail header and anything else that
/// lists an exercise have to agree on the wording and the order. A row whose
/// second pill reads BARBELL above a detail that reads Dumbbell for the same
/// exercise reads as bad data rather than a rendering slip.
///
/// The order is fixed and comes from the design: primary muscle, equipment,
/// type, movement pattern, skill level. Two of them are derived rather than
/// read, because the catalogue does not carry them directly:
///
///  * **type** - the catalogue's `category` is strength / cardio / stretching /
///    plyometrics / calisthenics / calisthenic_skills / strongman /
///    powerlifting. The design's TYPE pill says CALISTHENICS, FREE-WEIGHTS or
///    MACHINE, which is what the *equipment* tells you, so it is derived from
///    both.
///  * **skill** - only calisthenic skills carry a level. A beginner bench press
///    and a beginner dip are not worth telling apart, and the field is empty on
///    21 of the 74 bundled rows anyway.
library;

import 'library_exercise.dart';

/// Equipment words that lead an exercise name.
///
/// The catalogue bakes the equipment into the name - "Barbell Bench Press",
/// "Dumbbell Bench Press" - so recognising the leading token is the only way to
/// tell that two rows are the same movement.
const List<String> _namePrefixes = [
  'barbell',
  'dumbbell',
  'cable',
  'machine',
  'kettlebell',
  'kettlebells',
  'band',
  'bands',
  'ez-bar',
  'e-z curl bar',
  'smith',
  'lever',
  'sled',
  'hammer',
  'weighted',
  'close-grip',
  'alternating',
  'arnold',
  'seated',
  'standing',
  'incline',
  'decline',
  'flat',
];

/// Reading names for muscles the catalogue spells differently.
const Map<String, String> _muscleLabels = {
  'abdominals': 'CORE',
  'middle back': 'MID BACK',
  'lower back': 'LOWER BACK',
};

/// Reading names for equipment the catalogue spells differently.
const Map<String, String> _equipmentLabels = {
  'body only': 'BODYWEIGHT',
  'kettlebells': 'KETTLEBELL',
  'bands': 'BAND',
  'e-z curl bar': 'EZ BAR',
};

/// Equipment written the way a title reads, for the "(Barbell)" suffix.
const Map<String, String> _equipmentTitles = {
  'body only': 'Bodyweight',
  'e-z curl bar': 'EZ bar',
};

String _upper(String value) => value.trim().toUpperCase();

/// The movement a name describes, with the leading equipment word removed.
///
/// "Barbell Bench Press" becomes "Bench Press"; a name that carries no such
/// word ("Pull-Up") is returned unchanged, which is what tells the caller the
/// exercise has no equipment to name.
String movementName(String name) {
  final lower = name.toLowerCase();
  for (final prefix in _namePrefixes) {
    if (lower.startsWith('$prefix ')) return name.substring(prefix.length + 1);
  }
  return name;
}

/// Equipment as a title reads it: "Barbell", "Dumbbell", "Bodyweight".
String equipmentTitle(String equipment) {
  final label = _equipmentTitles[equipment.toLowerCase()];
  if (label != null) return label;
  final trimmed = equipment.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

/// The exercise's type, derived because the catalogue has no such field.
String exerciseType(LibraryExercise exercise) {
  final category = exercise.category.toLowerCase();
  if (category.contains('calisthenic')) return 'CALISTHENICS';

  final equipment = exercise.equipment.map((e) => e.toLowerCase()).toList();
  if (equipment.any((e) => e == 'machine' || e == 'cable')) return 'MACHINE';
  return 'FREE-WEIGHTS';
}

/// Tag labels in display order, already upper-cased.
///
/// Empty muscles, equipment or force simply drop their pill rather than
/// rendering a placeholder: a tag that says UNKNOWN is worse than no tag.
List<String> exerciseTags(LibraryExercise exercise) {
  final tags = <String>[];

  if (exercise.primaryMuscles.isNotEmpty) {
    final muscle = exercise.primaryMuscles.first.toLowerCase();
    tags.add(_muscleLabels[muscle] ?? _upper(muscle));
  }
  if (exercise.equipment.isNotEmpty) {
    final equipment = exercise.equipment.first.toLowerCase();
    tags.add(_equipmentLabels[equipment] ?? _upper(equipment));
  }
  tags.add(exerciseType(exercise));

  final force = exercise.force;
  if (force != null && force.trim().isNotEmpty) tags.add(_upper(force));

  final level = exercise.level;
  if (exercise.category.toLowerCase() == 'calisthenic_skills' &&
      level != null &&
      level.trim().isNotEmpty) {
    tags.add(_upper(level));
  }

  return tags;
}

/// What a row calls the exercise.
///
/// Equipment is named only when the movement exists with more than one, so
/// "Barbell Bench Press" and "Dumbbell Bench Press" read as Bench Press
/// (Barbell) and Bench Press (Dumbbell), while "Pull-Up" stays plain - there is
/// nothing to tell apart. A name with no equipment word of its own is returned
/// as it is.
String exerciseTitle(
  LibraryExercise exercise,
  List<LibraryExercise> catalogue,
) {
  final movement = movementName(exercise.name);
  if (movement == exercise.name) return exercise.name;

  final variants = <String>{
    for (final other in catalogue)
      if (movementName(other.name) == movement) ...other.equipment,
  };
  if (variants.length < 2) return exercise.name;

  final equipment = exercise.equipment.isEmpty
      ? null
      : exercise.equipment.first;
  // No equipment to name: keep the name as written rather than returning the
  // stripped movement, which would collide with the other variant's title.
  return equipment == null
      ? exercise.name
      : '$movement (${equipmentTitle(equipment)})';
}
