import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/library_exercise.dart';

/// Loads the bundled catalogue.
///
/// One asset, one parse. The merge and the source adapters live in
/// `tool/build_exercises.dart`, so there is no second shape to reconcile at
/// runtime and nothing here can silently drop a field the build script kept.
class ExerciseLibrary {
  const ExerciseLibrary._();

  /// The canonical catalogue, generated from the two upstream data sets.
  static const String catalogAsset = 'assets/data/exercises.json';

  /// The full bundled catalogue, in the build script's deterministic order.
  static Future<List<LibraryExercise>> loadAll() async {
    final raw = await rootBundle.loadString(catalogAsset);
    final decoded = jsonDecode(raw);
    final entries = decoded is Map<String, dynamic>
        ? decoded['exercises']
        : decoded;

    if (entries is! List) {
      throw const FormatException('exercise catalogue has no exercises list');
    }

    return [
      for (final entry in entries)
        if (entry is Map<String, dynamic>) LibraryExercise.fromJson(entry),
    ].where((exercise) => exercise.name.isNotEmpty).toList(growable: false);
  }
}
