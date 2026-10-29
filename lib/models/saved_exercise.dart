import 'library_exercise.dart';

/// An exercise the user kept, and when they kept it.
///
/// The collection is ordered newest first — that is the order the saved list
/// shows and the order a restart restores — so the moment is part of the
/// record rather than something worked out later from whatever happens to be
/// in memory.
class SavedExercise {
  const SavedExercise({required this.exercise, required this.savedAt});

  final LibraryExercise exercise;

  /// When the user kept it.
  final DateTime savedAt;

  /// The storage key, taken from the exercise so both agree on identity.
  String get id => exercise.id;
}
