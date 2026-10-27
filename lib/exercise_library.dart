import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models/taxonomy.dart' as taxonomy;

/// One entry in the bundled exercise catalogue.
///
/// The two upstream data sets are merged by `tool/build_exercises.dart` into
/// `assets/data/exercises.json`, so this is the only shape the app parses. The
/// fields are the union that survived: stable id, list-valued muscles and
/// equipment, and the text/media that only one source carried. Optional fields
/// stay nullable rather than being filled with invented defaults; the UI
/// decides what a missing level means.
class LibraryExercise {
  const LibraryExercise({
    required this.name,
    this.catalogueId,
    this.aliases = const [],
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.instructions = const [],
    required this.equipment,
    required this.category,
    this.level,
    this.force,
    this.mechanic,
    this.description,
    this.tips = const [],
    this.video,
    this.images = const [],
  });

  /// Human-friendly name (e.g. "Barbell Curl").
  final String name;

  /// Stable catalogue identity, written by the build script. Older saved rows
  /// have no id, so [id] falls back to the normalised name.
  final String? catalogueId;

  /// Other names this exercise is known by.
  final List<String> aliases;

  /// Every primary muscle, in source order.
  final List<String> primaryMuscles;

  /// Every secondary muscle, in source order.
  final List<String> secondaryMuscles;

  /// Instruction lines, kept separate so a card can show a paragraph and a
  /// detail view can keep the list.
  final List<String> instructions;

  /// Equipment needed. Empty is allowed for malformed saved rows, never for a
  /// catalogue entry.
  final List<String> equipment;

  /// One of [ExerciseCategory]'s wire names: strength, cardio, stretching
  /// (Mobility), plyometrics, calisthenics, calisthenic_skills, strongman or
  /// powerlifting. Kept as text so a catalogue row written by an older build
  /// still parses; [type] is the typed view.
  final String category;

  /// beginner | intermediate | expert, or null when the source had no level.
  final String? level;

  /// push | pull | static, or null when the source had no force.
  final String? force;

  /// compound | isolation, or null when the source had no mechanic.
  final String? mechanic;

  /// Short description from exercemus, when present.
  final String? description;

  /// Form cues from exercemus, when present.
  final List<String> tips;

  /// Demonstration video URL, when present.
  final String? video;

  /// Source-relative image paths, when present.
  final List<String> images;

  /// Stable identity. The build script's id wins; a payload written before the
  /// canonical catalogue keeps working through the name-derived fallback.
  String get id => catalogueId ?? keyFor(name);

  /// The typed category, or null when the row carries a value this build does
  /// not know. Unknown stays visible rather than being coerced to Strength.
  taxonomy.ExerciseCategory? get type =>
      taxonomy.ExerciseCategory.tryParse(category);

  /// Display label for [category], falling back to a title-cased version of
  /// the raw value for rows this build has no enum for.
  String get categoryLabel => taxonomy.categoryLabel(category);

  /// Convenience for cards and older callers: the first primary muscle.
  String get primaryMuscle =>
      primaryMuscles.isEmpty ? '' : primaryMuscles.first;

  /// Convenience for older callers: the first secondary muscle.
  String? get secondaryMuscle =>
      secondaryMuscles.isEmpty ? null : secondaryMuscles.first;

  /// Instructions as one block of text, for the places that show a paragraph.
  String get instructionsText => instructions.join(' ');

  /// Tips as one block of text, or null when there are none.
  String? get tipsText => tips.isEmpty ? null : tips.join(' ');

  /// Older name for [aliases], kept so saved payloads can be read.
  List<String>? get variations => aliases.isEmpty ? null : aliases;

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
    'id': id,
    'name': name,
    'aliases': aliases,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'instructions': instructions,
    'equipment': equipment,
    'category': category,
    'level': level,
    'force': force,
    'mechanic': mechanic,
    'description': description,
    'tips': tips,
    'video': video,
    'images': images,
  };

  /// Rebuilds an entry from [toJson]'s output.
  ///
  /// Tolerant field by field: a saved row outlives the code that wrote it, and
  /// an entry missing one field beats a screen that cannot open. Rows written
  /// before the canonical model used singular `primaryMuscle`/`secondaryMuscle`
  /// and string `instructions`/`tips`; those shapes are read here so an update
  /// does not cost the user their saved list.
  factory LibraryExercise.fromJson(Map<String, dynamic> json) {
    final primary = _list(json['primaryMuscles']);
    if (primary.isEmpty) {
      final legacy = _optionalText(json['primaryMuscle']);
      if (legacy != null) primary.add(legacy);
    }

    final secondary = _list(json['secondaryMuscles']);
    if (secondary.isEmpty) {
      final legacy = _optionalText(json['secondaryMuscle']);
      if (legacy != null) secondary.add(legacy);
    }

    return LibraryExercise(
      catalogueId: _optionalText(json['id']),
      name: _text(json['name']),
      aliases: _union(_list(json['aliases']), _list(json['variations'])),
      primaryMuscles: primary,
      secondaryMuscles: secondary,
      instructions: _lines(json['instructions']),
      equipment: _list(json['equipment']),
      category: _text(json['category']),
      level: _optionalText(json['level']),
      force: _optionalText(json['force']),
      mechanic: _optionalText(json['mechanic']),
      description: _optionalText(json['description']),
      tips: _lines(json['tips']),
      video: _optionalText(json['video']),
      images: _list(json['images']),
    );
  }

  static String _text(Object? raw) => raw is String ? raw : '';

  static String? _optionalText(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

  /// A list of non-empty strings. A single string is accepted because older
  /// payloads stored instructions and tips that way; newlines become lines.
  static List<String> _lines(Object? raw) {
    if (raw is String) {
      return [
        for (final line in raw.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ];
    }
    return _list(raw);
  }

  /// A list of non-empty strings, with non-list values treated as empty.
  static List<String> _list(Object? raw) {
    if (raw is! List) return [];
    return [
      for (final item in raw)
        if (item != null && item.toString().trim().isNotEmpty)
          item.toString().trim(),
    ];
  }

  static List<String> _union(List<String> a, List<String> b) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in [...a, ...b]) {
      if (seen.add(value.toLowerCase())) result.add(value);
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryExercise &&
          name == other.name &&
          id == other.id &&
          category == other.category;

  @override
  int get hashCode => Object.hash(name, id, category);

  @override
  String toString() => 'LibraryExercise($name)';
}

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
