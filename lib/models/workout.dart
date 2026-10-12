import 'package:equatable/equatable.dart';

import 'exercise.dart';

/// Lifecycle of a workout once it exists on the calendar.
enum WorkoutStatus { planned, completed, rest }

/// A single training session.
class Workout extends Equatable {
  const Workout({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.durationMin,
    required this.estimatedKcal,
    required this.targetMuscleGroups,
    required this.equipment,
    required this.logs,
    this.startTime = '',
    this.place = '',
    this.hasNewPR = false,
  });

  final String id;
  final String title;
  final DateTime date;
  final WorkoutStatus status;

  /// Wall-clock label as shown on the card ("07:15 AM"). Kept as text
  /// rather than a TimeOfDay so it round-trips through JSON untouched.
  final String startTime;

  /// Where the session happens, optional for rest days.
  final String place;

  /// Planning estimate shown before the session, actual time once done.
  final int durationMin;
  final int estimatedKcal;
  final List<String> targetMuscleGroups;
  final List<String> equipment;
  final List<ExerciseLog> logs;
  final bool hasNewPR;

  int get totalSets => logs.fold(0, (sum, log) => sum + log.totalSets);

  int get totalReps => logs.fold(
    0,
    (sum, log) => sum + log.sets.fold(0, (s, set) => s + set.reps),
  );

  int get completedSets => logs.fold(0, (sum, log) => sum + log.completedSets);

  /// 0.0-1.0, driven by sets actually marked done rather than exercises
  /// finished, so a user mid-set sees the bar move.
  double get progress => totalSets == 0 ? 0 : completedSets / totalSets;

  /// Sets left, which is what the dashboard shows as "5/8 LEFT".
  int get setsRemaining => totalSets - completedSets;

  bool get isDone => completedSets == totalSets && totalSets > 0;

  Workout copyWith({
    String? id,
    String? title,
    DateTime? date,
    WorkoutStatus? status,
    String? startTime,
    String? place,
    int? durationMin,
    int? estimatedKcal,
    List<String>? targetMuscleGroups,
    List<String>? equipment,
    List<ExerciseLog>? logs,
    bool? hasNewPR,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      place: place ?? this.place,
      durationMin: durationMin ?? this.durationMin,
      estimatedKcal: estimatedKcal ?? this.estimatedKcal,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      equipment: equipment ?? this.equipment,
      logs: logs ?? this.logs,
      hasNewPR: hasNewPR ?? this.hasNewPR,
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      status: WorkoutStatus.values.byName(json['status'] as String),
      startTime: json['startTime'] as String? ?? '',
      place: json['place'] as String? ?? '',
      durationMin: (json['durationMin'] as num).toInt(),
      estimatedKcal: (json['estimatedKcal'] as num).toInt(),
      targetMuscleGroups: (json['targetMuscleGroups'] as List<dynamic>)
          .cast<String>()
          .toList(),
      equipment: (json['equipment'] as List<dynamic>).cast<String>().toList(),
      logs: (json['logs'] as List<dynamic>)
          .map((l) => ExerciseLog.fromJson(l as Map<String, dynamic>))
          .toList(),
      hasNewPR: json['hasNewPR'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'status': status.name,
    'startTime': startTime,
    'place': place,
    'durationMin': durationMin,
    'estimatedKcal': estimatedKcal,
    'targetMuscleGroups': targetMuscleGroups,
    'equipment': equipment,
    'logs': logs.map((l) => l.toJson()).toList(),
    'hasNewPR': hasNewPR,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    date,
    status,
    startTime,
    place,
    durationMin,
    estimatedKcal,
    targetMuscleGroups,
    equipment,
    logs,
    hasNewPR,
  ];
}
