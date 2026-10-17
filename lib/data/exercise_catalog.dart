import '../exercise_library.dart';
import 'exercise_api_client.dart';

/// Where the catalogue on screen came from.
enum CatalogSource {
  /// Live results from the wger REST API.
  network,

  /// The data sets that ship with the app, used when wger cannot answer.
  bundled,
}

/// One load of the exercise catalogue.
class ExerciseCatalogResult {
  const ExerciseCatalogResult({required this.exercises, required this.source});

  final List<LibraryExercise> exercises;
  final CatalogSource source;

  /// True when this is the offline fallback rather than live data.
  bool get isOffline => source == CatalogSource.bundled;
}

/// Loads the exercise catalogue: wger first, bundled assets as the fallback.
///
/// Sits between the screen and its two sources so the "online, else offline"
/// policy is stated once, testable on its own, and the screen keeps a single
/// code path whatever answered.
class ExerciseCatalog {
  ExerciseCatalog({
    ExerciseApiClient? api,
    Future<List<LibraryExercise>> Function()? bundled,
  }) : _api = api ?? ExerciseApiClient(),
       _bundled = bundled ?? ExerciseLibrary.loadAll;

  final ExerciseApiClient _api;
  final Future<List<LibraryExercise>> Function() _bundled;

  /// Network first; falls back to the bundled sets when wger cannot answer.
  ///
  /// An empty network answer counts as "cannot answer" - an empty library
  /// helps nobody. Only a failure of *both* sources propagates, and the
  /// screen renders that as its error state with a retry.
  Future<ExerciseCatalogResult> load() async {
    try {
      final exercises = await _api.fetchExercises();
      if (exercises.isNotEmpty) {
        return ExerciseCatalogResult(
          exercises: exercises,
          source: CatalogSource.network,
        );
      }
    } on ExerciseApiException {
      // Fall through to the bundled catalogue.
    }

    return ExerciseCatalogResult(
      exercises: await _bundled(),
      source: CatalogSource.bundled,
    );
  }
}
