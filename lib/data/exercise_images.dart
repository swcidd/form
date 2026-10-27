import '../models/library_exercise.dart';

/// Chooses the photograph a catalogue card shows.
///
/// The upstream catalogue carries image paths that are relative to
/// free-exercise-db and are not bundled with the app, so rendering them as
/// assets is a guaranteed miss. Until the repo ships its own exercise
/// photography, this maps the muscle the exercise trains onto a small,
/// hotlinked Unsplash set. It is deliberately a display concern: the stored
/// catalogue is unchanged, and replacing this class with bundled artwork
/// later touches no data.
///
/// No API key is involved. The URLs are the public Unsplash CDN, with their
/// width and format pinned so a card always asks for the same small image.
abstract final class ExerciseImages {
  static const String _cdn = 'https://images.unsplash.com/';

  static const String _strength =
      '${_cdn}photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=600&q=70';
  static const String _core =
      '${_cdn}photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=600&q=70';
  static const String _pull =
      '${_cdn}photo-1526506118085-60ce8714f8c5?auto=format&fit=crop&w=600&q=70';
  static const String _legs =
      '${_cdn}photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=70';
  static const String _arms =
      '${_cdn}photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=600&q=70';
  static const String _stretching =
      '${_cdn}photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=70';
  static const String _plyometrics =
      '${_cdn}photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=70';

  // The bundled catalogue uses the canonical free-exercise-db names, while
  // wger sends its own label set ("Quadriceps", "Shoulders", ...). Both are
  // accepted here so a live entry does not fall through to the generic card.
  static const Set<String> _coreMuscles = {
    'abdominals',
    'abs',
    'obliques',
    'rectus abdominis',
  };
  static const Set<String> _pushMuscles = {
    'chest',
    'pectorals',
    'shoulders',
    'deltoids',
    'triceps',
  };
  static const Set<String> _pullMuscles = {
    'lats',
    'latissimus dorsi',
    'middle back',
    'lower back',
    'traps',
    'trapezius',
    'rhomboids',
  };
  static const Set<String> _legMuscles = {
    'quads',
    'quadriceps',
    'hamstrings',
    'glutes',
    'gluteus maximus',
    'calves',
    'abductors',
    'adductors',
  };
  static const Set<String> _armMuscles = {'biceps', 'forearms', 'brachialis'};

  /// Used only when an entry has no primary muscle the groups above recognise.
  static const Map<String, String> _categoryFallbacks = {
    'abs': _core,
    'arms': _arms,
    'back': _pull,
    'calves': _legs,
    'chest': _strength,
    'legs': _legs,
    'shoulders': _strength,
  };

  /// The image URL for [exercise], chosen by category first and then by the
  /// first primary muscle this catalogue knows how to group.
  static String forExercise(LibraryExercise exercise) {
    switch (exercise.category.toLowerCase()) {
      case 'stretching':
        return _stretching;
      case 'plyometrics':
        return _plyometrics;
      case 'powerlifting':
      case 'strongman':
        return _legs;
    }

    for (final muscle in exercise.primaryMuscles) {
      final key = muscle.toLowerCase();
      if (_coreMuscles.contains(key)) return _core;
      if (_pushMuscles.contains(key)) return _strength;
      if (_pullMuscles.contains(key)) return _pull;
      if (_legMuscles.contains(key)) return _legs;
      if (_armMuscles.contains(key)) return _arms;
    }

    return _categoryFallbacks[exercise.category.toLowerCase()] ?? _strength;
  }

  /// A bundled asset path if one was saved, otherwise null.
  ///
  /// Saved rows can carry the old free-exercise-db relative paths; those were
  /// never shipped as assets, so only an `assets/` prefix is usable.
  static String? bundledAsset(LibraryExercise exercise) {
    if (exercise.images.isEmpty) return null;
    final path = exercise.images.first;
    return path.startsWith('assets/') ? path : null;
  }
}
