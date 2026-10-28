import 'package:equatable/equatable.dart';

import 'library_exercise.dart';

/// One logged set: reps performed at a given weight.
class WorkoutSet extends Equatable {
  const WorkoutSet({
    required this.reps,
    required this.weightKg,
    this.completed = false,
  });

  final int reps;
  final double weightKg;
  final bool completed;

  /// Work done in this set, used for session volume totals.
  double get volume => reps * weightKg;

  WorkoutSet copyWith({int? reps, double? weightKg, bool? completed}) {
    return WorkoutSet(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      completed: completed ?? this.completed,
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      reps: (json['reps'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'reps': reps,
    'weightKg': weightKg,
    'completed': completed,
  };

  @override
  List<Object?> get props => [reps, weightKg, completed];
}

/// An exercise as it exists in the library, independent of any workout.
class Exercise extends Equatable {
  const Exercise({
    required this.name,
    required this.equipment,
    required this.muscleGroups,
  });

  final String name;
  final String equipment;
  final List<String> muscleGroups;

  /// Short handle used as a route argument: spaces would need escaping in
  /// a path, so identifiers stay slug-like.
  String get slug => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] as String,
      equipment: json['equipment'] as String,
      muscleGroups: (json['muscleGroups'] as List<dynamic>)
          .cast<String>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'equipment': equipment,
    'muscleGroups': muscleGroups,
  };

  @override
  List<Object?> get props => [name, equipment, muscleGroups];
}

/// An exercise together with the sets performed in one workout.
class ExerciseLog extends Equatable {
  /// A planned entry for an exercise picked from the catalogue.
  ///
  /// One definition, because the workout flow and the session screen both turn
  /// a catalogue entry into a log, and two hand-written copies of this are two
  /// places to drift apart.
  ///
  /// No sets are invented: the exercise lands with everything the logging
  /// screen already knows how to fill in, rather than opening on numbers
  /// nobody chose.
  factory ExerciseLog.planned(LibraryExercise library) {
    return ExerciseLog(
      exercise: Exercise(
        name: library.name,
        // The catalogue allows an empty equipment list on a malformed saved
        // row; a blank label beats a made-up one.
        equipment: library.equipment.isEmpty ? '' : library.equipment.first,
        muscleGroups: library.primaryMuscles,
      ),
      sets: const [],
    );
  }

  const ExerciseLog({
    required this.exercise,
    required this.sets,
    this.restSeconds = 120,
  });

  final Exercise exercise;
  final List<WorkoutSet> sets;

  /// What the plan asks for between sets. Displayed, never edited: the design's
  /// rest field is part of the plan, and nothing in the app writes it yet.
  final int restSeconds;

  int get totalSets => sets.length;

  int get completedSets => sets.where((s) => s.completed).length;

  bool get isFinished => totalSets > 0 && completedSets == totalSets;

  /// Sum of reps x weight across completed sets only, so a half-finished
  /// exercise does not report volume the user has not lifted yet.
  double get volume =>
      sets.where((s) => s.completed).fold(0.0, (sum, s) => sum + s.volume);

  /// Display string like "4 sets × 6–8 reps"
  String get setScheme {
    if (sets.isEmpty) return '0';
    final first = sets.first;
    final last = sets.last;
    if (first.reps == last.reps && first.weightKg == last.weightKg) {
      return '${first.reps} reps';
    }
    return '${first.reps}–${last.reps} reps';
  }

  /// Heaviest weight in the scheme
  String get heaviestWeight {
    if (sets.isEmpty) return '0';
    return sets
        .map((s) => s.weightKg.toInt())
        .reduce((a, b) => a > b ? a : b)
        .toString();
  }

  ExerciseLog copyWith({
    Exercise? exercise,
    List<WorkoutSet>? sets,
    int? restSeconds,
  }) {
    return ExerciseLog(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      sets: (json['sets'] as List<dynamic>)
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 120,
    );
  }

  Map<String, dynamic> toJson() => {
    'exercise': exercise.toJson(),
    'sets': sets.map((s) => s.toJson()).toList(),
    'restSeconds': restSeconds,
  };

  @override
  List<Object?> get props => [exercise, sets, restSeconds];
}
