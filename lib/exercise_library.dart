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

  /// Parse from exercemus JSON object.
  static LibraryExercise fromExercemus(Map<String, dynamic> map) {
    // Primary muscle is a list<string> in exercemus; take the first element
    final primaryNodes = map['primary_muscles'] as List<dynamic>?;

    final primary =
        primaryNodes?.any((e) => e.toString().isNotEmpty) == true
            ? primaryNodes?.firstWhere((e) => e.toString().isNotEmpty)?.toString() ??
                ''
            : '';

    final secondaryNodes = map['secondary_muscles'] as List<dynamic>?;
    final secondary =
        secondaryNodes?.any((e) => e.toString().isNotEmpty) == true
            ? secondaryNodes?.firstWhere((e) => e.toString().isNotEmpty)?.toString()
            : null;

    final instructions = _joinInstructions(map['instructions']);
    final tips = map['tips'] != null
        ? (map['tips'] as List<dynamic>).join('\n')
        : null;
    final category = (map['category'] as String?) ?? 'strength';
    final name = map['name'] as String? ?? '';

    // equipment: exercemus stores as list of display strings
    final equipmentNodes = map['equipment'] as List<dynamic>?;
    final equipment = equipmentNodes
            ?.where((e) => e.toString().isNotEmpty)
            .map((e) => e.toString())
            .toList() ??
        [];

    return LibraryExercise(
      name: name,
      primaryMuscle: primary.isNotEmpty ? primary : 'unknown',
      secondaryMuscle: secondary,
      instructions: instructions,
      equipment: equipment,
      category: category,
      level: 'beginner', // exercemus has no level field
      force: 'pull', // default
      images: [], // no bundled images in exercemus
      tips: tips.isNotEmpty ? tips : null,
      video: null,
      variations: _variations(map),
    );
  }

  /// Parse from free-exercise-db JSON object.
  static LibraryExercise fromFreeDb(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? '';
    // Primary muscle
    final primaryNodes = map['primaryMuscles'] as List<dynamic>?;
    final primary =
        primaryNodes?.any((e) => e.toString().isNotEmpty) == true
            ? primaryNodes?.firstWhere((e) => e.toString().isNotEmpty)?.toString() ??
                ''
            : '';

    final secondaryNodes = map['secondaryMuscles'] as List<dynamic>?;
    final secondaryMuscle =
        secondaryNodes?.any((e) => e.toString().isNotEmpty) == true
            ? secondaryNodes?.firstWhere((e) => e.toString().isNotEmpty)?.toString()
            : null;

    final instructions = _joinInstructions(map['instructions']);
    // Equipment
    final equipmentNodes = map['equipment'] as List<dynamic>?;
    final equipment = equipmentNodes
            ?.where((e) => e.toString().isNotEmpty)
            .map((e) => e.toString())
            .toList() ??
        [];
    final category = (map['category'] as String?) ?? 'strength';
    final level = (map['level'] as String?) ?? 'beginner';
    final force = (map['force'] as String?) ?? 'pull';
    // Images
    final imagesNodes = map['images'] as List<dynamic>?;
    final images = imagesNodes
            ?.where((e) => e.toString().isNotEmpty)
            .map((e) => e.toString())
            .toList() ??
        [];

    return LibraryExercise(
      name: name,
      primaryMuscle: primaryMuscle,
      secondaryMuscle: secondaryMuscle,
      instructions: instructions,
      equipment: equipment,
      category: category,
      level: level,
      force: force,
      images: images,
    );
  }

  /// Join a list of instruction strings into one paragraph.
  static String _joinInstructions(List<dynamic>? list) {
    if (list == null || list.isEmpty) return '';
    return list.map((line) => line.toString()).join(' ');
  }

  static List<String>? _variations(Map<String, dynamic> map) {
    final nodes = map['variations_on'] as List<dynamic>?;
    return nodes?.isNotEmpty == true ? nodes.map((e) => e.toString()).toList() : null;
  }
}