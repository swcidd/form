import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Library exercise catalog — merged from two open-source data sets.
///
/// Completely independent of the core [Exercise] model.  Display-only;
/// if the user saves a workout that references it, a real [Exercise] is
/// created from the workout's logged sets.
class LibraryExercise {
  const LibraryExercise({
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscle,
    required this.instructions,
    required this.equipment,
    required this.category,
    this.level = 'beginner',
    this.force = 'pull',
    this.images = const [],
    this.tips,
    this.video,
    this.variations,
  });

  /// Human-friendly name (e.g. "Barbell Curl")
  final String name;

  /// Primary muscle group (e.g. "biceps")
  final String primaryMuscle;

  /// Optional secondary muscle group
  final String? secondaryMuscle;

  /// Instructions text (single string, instructions joined with spaces)
  final String instructions;

  /// Equipment needed (list of strings)
  final List<String> equipment;

  /// Category: strength, stretching, plyometrics, strongman, etc.
  final String category;

  /// Difficulty level: beginner | intermediate | expert
  final String level;

  /// Movement type: pull | push | static | compound | isolation
  final String force;

  /// Bundled image paths (free-exercise-db).  May be empty if only
  /// available via exercemus URLs.
  final List<String> images;

  /// Optional tips text
  final String? tips;

  /// Optional video URL
  final String? video;

  /// Optional variation names
  final List<String>? variations;

  /// Stable identity for an entry.
  ///
  /// The catalogue is keyed by name because that is the only field both
  /// sources agree on, normalised so "3/4 Sit-Up" and "3-4 sit up" are one
  /// exercise. Keeping an entry needs the same key to find it again after a
  /// restart, so the normalisation lives on the entry rather than in whichever
  /// loader happened to build it.
  String get id => keyFor(name);

  /// The key two spellings of the same exercise share.
  static String keyFor(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '');

  /// This entry as plain JSON, for the saved-exercises table.
  ///
  /// Every field, not just the ones the card draws: a saved entry is a copy of
  /// something the catalogue may not be able to hand back - the wger page it
  /// came from is one request away and the app may well be offline - so what
  /// is stored has to stand on its own.
  Map<String, Object?> toJson() => {
    'name': name,
    'primaryMuscle': primaryMuscle,
    'secondaryMuscle': secondaryMuscle,
    'instructions': instructions,
    'equipment': equipment,
    'category': category,
    'level': level,
    'force': force,
    'images': images,
    'tips': tips,
    'video': video,
    'variations': variations,
  };

  /// Rebuilds an entry from [toJson]'s output.
  ///
  /// Tolerant field by field: a saved row outlives the code that wrote it, and
  /// an entry missing one field beats a screen that cannot open.
  static LibraryExercise fromJson(Map<String, dynamic> json) {
    return LibraryExercise(
      name: _text(json['name']),
      primaryMuscle: _text(json['primaryMuscle']),
      secondaryMuscle: _optionalText(json['secondaryMuscle']),
      instructions: _text(json['instructions']),
      equipment: _textList(json['equipment']),
      category: _text(json['category']),
      level: _optionalText(json['level']) ?? 'beginner',
      force: _optionalText(json['force']) ?? 'pull',
      images: _textList(json['images']),
      tips: _optionalText(json['tips']),
      video: _optionalText(json['video']),
      variations: json['variations'] == null
          ? null
          : _textList(json['variations']),
    );
  }

  static String _text(Object? raw) => raw is String ? raw : '';

  static String? _optionalText(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;

  static List<String> _textList(Object? raw) =>
      raw is List ? [for (final item in raw) '$item'] : const [];

  /// Parse from exercemus JSON object.
  static LibraryExercise fromExercemus(Map<String, dynamic> map) {
    // Muscles are lists in exercemus; the catalog uses the first entry.
    final primary = _firstNonEmpty(map['primary_muscles'] as List<dynamic>?);
    final secondary = _firstNonEmpty(
      map['secondary_muscles'] as List<dynamic>?,
    );
    final tips = _joinInstructions(
      map['tips'] as List<dynamic>?,
      separator: '\n',
    );

    return LibraryExercise(
      name: map['name'] as String? ?? '',
      primaryMuscle: primary ?? 'unknown',
      secondaryMuscle: secondary,
      instructions: _joinInstructions(map['instructions'] as List<dynamic>?),
      equipment: _equipment(map['equipment']),
      category: (map['category'] as String?) ?? 'strength',
      level: 'beginner', // exercemus has no level field
      force: 'pull', // no force field either
      images: const [], // no bundled images in exercemus
      tips: tips.isEmpty ? null : tips,
      video: map['video'] as String?,
      variations: _variations(map),
    );
  }

  /// Parse from free-exercise-db JSON object.
  static LibraryExercise fromFreeDb(Map<String, dynamic> map) {
    final primary = _firstNonEmpty(map['primaryMuscles'] as List<dynamic>?);
    final secondary = _firstNonEmpty(map['secondaryMuscles'] as List<dynamic>?);

    return LibraryExercise(
      name: map['name'] as String? ?? '',
      primaryMuscle: primary ?? 'unknown',
      secondaryMuscle: secondary,
      instructions: _joinInstructions(map['instructions'] as List<dynamic>?),
      // free-exercise-db stores equipment as a single string.
      equipment: _equipment(map['equipment']),
      category: (map['category'] as String?) ?? 'strength',
      level: (map['level'] as String?) ?? 'beginner',
      force: (map['force'] as String?) ?? 'pull',
      images: _strings(map['images']),
    );
  }

  /// First non-empty string of a JSON string list, or null when there is none.
  static String? _firstNonEmpty(List<dynamic>? nodes) {
    if (nodes == null) return null;
    for (final node in nodes) {
      final text = node.toString();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// All non-empty strings of a JSON list, in order.
  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final node in raw)
        if (node.toString().isNotEmpty) node.toString(),
    ];
  }

  /// Equipment is a list in exercemus but a bare string in free-exercise-db.
  static List<String> _equipment(Object? raw) {
    if (raw is String) return raw.isEmpty ? const [] : [raw];
    return _strings(raw);
  }

  /// Join instruction or tip lines into one block of text.
  static String _joinInstructions(
    List<dynamic>? list, {
    String separator = ' ',
  }) {
    if (list == null || list.isEmpty) return '';
    return [
      for (final line in list)
        if (line.toString().isNotEmpty) line.toString(),
    ].join(separator);
  }

  /// Variation names; exercemus uses both spellings across its entries.
  static List<String>? _variations(Map<String, dynamic> map) {
    final nodes =
        (map['variation_on'] ?? map['variations_on']) as List<dynamic>?;
    if (nodes == null || nodes.isEmpty) return null;
    return _strings(nodes);
  }
}

/// Loads and merges the bundled data sets into one catalog.
///
/// The UI talks to [loadAll] only, and so will the API client's offline
/// fallback: keeping the merge here rather than in a build script means the
/// assets stay the untouched open-source downloads and the screen has a
/// single code path.
class ExerciseLibrary {
  const ExerciseLibrary._();

  /// exercemus (CC BY-SA) — text metadata and variations.
  static const String exercemusAsset = 'assets/data/exercemus.json';

  /// free-exercise-db (public domain) — images, level and force.
  static const String freeDbAsset = 'assets/data/free-exercise-db.json';

  /// The full bundled catalog, merged and de-duplicated by name.
  static Future<List<LibraryExercise>> loadAll() async {
    final raw = await Future.wait([
      rootBundle.loadString(exercemusAsset),
      rootBundle.loadString(freeDbAsset),
    ]);
    final exercemus =
        ((jsonDecode(raw[0]) as Map<String, dynamic>)['exercises']
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final freeDb = (jsonDecode(raw[1]) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return merge(exercemus: exercemus, freeDb: freeDb);
  }

  /// Merges both sets by normalized name.
  ///
  /// exercemus wins on text metadata; free-exercise-db fills in what it
  /// lacks (images, level, force).  Names that only one source carries pass
  /// through untouched, so the catalog is the union of both.
  static List<LibraryExercise> merge({
    required List<Map<String, dynamic>> exercemus,
    required List<Map<String, dynamic>> freeDb,
  }) {
    final merged = <String, LibraryExercise>{};
    for (final map in exercemus) {
      final exercise = LibraryExercise.fromExercemus(map);
      // No name, no identity: the catalogue merges by name and the cards show
      // it, so an entry that keys to nothing is nothing to show. The wger
      // client drops its nameless entries for the same reason.
      if (exercise.id.isEmpty) continue;
      merged[_key(exercise.name)] = exercise;
    }
    for (final map in freeDb) {
      final fromDb = LibraryExercise.fromFreeDb(map);
      if (fromDb.id.isEmpty) continue;
      final key = _key(fromDb.name);
      final existing = merged[key];
      merged[key] = existing == null
          ? fromDb
          : _combine(text: existing, media: fromDb);
    }
    return List.unmodifiable(merged.values);
  }

  /// One entry from both sources: text from [text], media from [media].
  static LibraryExercise _combine({
    required LibraryExercise text,
    required LibraryExercise media,
  }) {
    return LibraryExercise(
      name: text.name,
      primaryMuscle: text.primaryMuscle,
      secondaryMuscle: text.secondaryMuscle ?? media.secondaryMuscle,
      instructions: text.instructions.isNotEmpty
          ? text.instructions
          : media.instructions,
      equipment: text.equipment.isNotEmpty ? text.equipment : media.equipment,
      category: text.category,
      level: media.level,
      force: media.force,
      images: media.images,
      tips: text.tips,
      video: text.video,
      variations: text.variations,
    );
  }

  /// "3/4 Sit-Up" and "3-4 sit up" are the same exercise.
  static String _key(String name) => LibraryExercise.keyFor(name);
}
