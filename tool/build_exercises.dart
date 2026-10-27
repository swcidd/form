// Builds the one canonical exercise catalogue the app ships.
//
// The two upstream data sets describe the same exercises in different words:
// free-exercise-db has stable ids, images, level and force; exercemus has
// descriptions, videos and the occasional variation. Keeping both shapes at
// runtime made every screen depend on a merge whose losses were invisible.
// This script performs the merge once, normalises the vocabularies, and writes
// assets/data/exercises.json. Run it from the repository root:
//
//   dart run tool/build_exercises.dart
//
// The raw downloads stay in tool/exercise_sources/ so the catalogue can be
// rebuilt and audited without shipping either source in the APK.

import 'dart:convert';
import 'dart:io';

const String _sourceDir = 'tool/exercise_sources';
const String _outputPath = 'assets/data/exercises.json';

const List<Map<String, String>> _sources = [
  {
    'name': 'free-exercise-db',
    'url': 'https://github.com/yuhonas/free-exercise-db',
    'license': 'The Unlicense (public domain)',
  },
  {
    'name': 'exercemus/exercises',
    'url': 'https://github.com/exercemus/exercises',
    'license': 'MIT, © 2022 exercemus',
  },
];

/// The vocabularies the catalogue is allowed to contain. Keeping them here
/// rather than in the model means a typo in an upstream file fails the build
/// instead of becoming a filter that silently matches nothing.
const Set<String> _muscles = {
  'abdominals',
  'abductors',
  'adductors',
  'biceps',
  'brachialis',
  'calves',
  'chest',
  'forearms',
  'glutes',
  'hamstrings',
  'lats',
  'lower back',
  'middle back',
  'quads',
  'shoulders',
  'traps',
  'triceps',
};

const Set<String> _equipment = {
  'bands',
  'barbell',
  'bench',
  'body only',
  'cable',
  'dumbbell',
  'exercise ball',
  'foam roll',
  'kettlebells',
  'machine',
  'medicine ball',
  'other',
};

const Set<String> _levels = {'beginner', 'intermediate', 'expert'};
const Set<String> _forces = {'pull', 'push', 'static'};
const Set<String> _mechanics = {'compound', 'isolation'};
const Set<String> _categories = {
  'calisthenics',
  'calisthenic_skills',
  'cardio',
  'mobility',
  'plyometrics',
  'powerlifting',
  'strength',
  'stretching',
  'strongman',
};

/// Upstream spellings that all mean the same thing.
const Map<String, String> _muscleAliases = {
  'abs': 'abdominals',
  'quadriceps': 'quads',
};

const Map<String, String> _equipmentAliases = {
  'none': 'body only',
  'kettlebell': 'kettlebells',
};

void main() {
  final freeDb = _readList('$_sourceDir/free-exercise-db.json');
  final exercemus = _readMap('$_sourceDir/exercemus.json')['exercises'];

  if (exercemus is! List) {
    throw const FormatException('exercemus.json has no exercises list');
  }

  final merged = <String, Map<String, Object?>>{};
  for (final raw in freeDb) {
    final entry = _fromFreeDb(raw);
    merged[_key(entry['name']! as String)] = entry;
  }

  for (final raw in exercemus.whereType<Map<String, dynamic>>()) {
    final name = _requiredString(raw['name'], 'exercemus exercise name');
    final key = _key(name);
    final existing = merged[key];
    if (existing == null) {
      merged[key] = _fromExercemus(raw, name);
    } else {
      _mergeExercemus(existing, raw);
    }
  }

  final exercises = merged.values.toList()
    ..sort((a, b) {
      final byName = (a['name']! as String).toLowerCase().compareTo(
        (b['name']! as String).toLowerCase(),
      );
      return byName != 0
          ? byName
          : (a['id']! as String).compareTo(b['id']! as String);
    });

  _validate(exercises);

  final payload = {
    'version': 1,
    'generatedBy': 'tool/build_exercises.dart',
    'sources': _sources,
    'exercises': exercises,
  };

  File(_outputPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
    );

  final withImages = exercises
      .where((e) => (e['images']! as List).isNotEmpty)
      .length;
  final withDescription = exercises
      .where((e) => e['description'] != null)
      .length;
  final withVideo = exercises.where((e) => e['video'] != null).length;
  final withTips = exercises
      .where((e) => (e['tips']! as List).isNotEmpty)
      .length;
  final withMechanic = exercises.where((e) => e['mechanic'] != null).length;

  stdout.writeln(
    'Wrote $_outputPath: ${exercises.length} exercises '
    '($withImages with images, $withDescription with descriptions, '
    '$withVideo with videos, $withTips with tips, $withMechanic with mechanics).',
  );
}

Map<String, Object?> _fromFreeDb(Map<String, dynamic> raw) {
  final name = _requiredString(raw['name'], 'free-exercise-db exercise name');
  return {
    'id': _optional(raw['id']) ?? _slug(name),
    'name': name,
    'aliases': <String>[],
    'primaryMuscles': _muscleList(raw['primaryMuscles']),
    'secondaryMuscles': _muscleList(raw['secondaryMuscles']),
    'equipment': _equipmentList(raw['equipment']),
    'category': _category(raw['category']),
    'level': _optional(raw['level']),
    'force': _optional(raw['force']),
    'mechanic': _optional(raw['mechanic']),
    'instructions': _lines(raw['instructions']),
    'description': null,
    'tips': <String>[],
    'video': null,
    'images': _strings(raw['images']),
  };
}

Map<String, Object?> _fromExercemus(Map<String, dynamic> raw, String name) {
  return {
    'id': _slug(name),
    'name': name,
    'aliases': _variations(raw),
    'primaryMuscles': _muscleList(raw['primary_muscles']),
    'secondaryMuscles': _muscleList(raw['secondary_muscles']),
    'equipment': _equipmentList(raw['equipment']),
    'category': _category(raw['category']),
    'level': null,
    'force': null,
    'mechanic': null,
    'instructions': _lines(raw['instructions']),
    'description': _optional(raw['description']),
    'tips': _lines(raw['tips']),
    'video': _optional(raw['video']),
    'images': <String>[],
  };
}

/// free-exercise-db is the base. exercemus fills the fields it does not carry
/// and contributes any muscle or equipment the other source missed; the union
/// is what keeps the 27–28 multi-secondary entries from collapsing to one.
void _mergeExercemus(Map<String, Object?> target, Map<String, dynamic> raw) {
  target['aliases'] = _union(
    target['aliases']! as List<String>,
    _variations(raw),
  );
  target['primaryMuscles'] = _union(
    target['primaryMuscles']! as List<String>,
    _muscleList(raw['primary_muscles']),
  );
  target['secondaryMuscles'] = _union(
    target['secondaryMuscles']! as List<String>,
    _muscleList(raw['secondary_muscles']),
  );
  target['equipment'] = _mergeEquipment(
    target['equipment']! as List<String>,
    _equipmentList(raw['equipment']),
  );

  final existingInstructions = target['instructions']! as List<String>;
  if (existingInstructions.isEmpty) {
    target['instructions'] = _lines(raw['instructions']);
  }

  target['description'] ??= _optional(raw['description']);
  target['tips'] = _union(target['tips']! as List<String>, _lines(raw['tips']));
  target['video'] ??= _optional(raw['video']);

  if ((target['category']! as String).isEmpty) {
    target['category'] = _category(raw['category']);
  }
}

void _validate(List<Map<String, Object?>> exercises) {
  final ids = <String>{};
  final names = <String>{};

  for (final entry in exercises) {
    final name = entry['name']! as String;
    final id = entry['id']! as String;
    final primary = entry['primaryMuscles']! as List<String>;
    final secondary = entry['secondaryMuscles']! as List<String>;
    final equipment = entry['equipment']! as List<String>;
    final instructions = entry['instructions']! as List<String>;

    if (name.isEmpty) _fail('an exercise has no name');
    if (id.isEmpty) _fail('$name has no id');
    if (!ids.add(id)) _fail('duplicate id: $id');
    if (!names.add(_key(name))) _fail('duplicate name: $name');
    if (primary.isEmpty) _fail('$name has no primary muscle');
    if (equipment.isEmpty) _fail('$name has no equipment');
    if (instructions.isEmpty) _fail('$name has no instructions');

    for (final muscle in [...primary, ...secondary]) {
      if (!_muscles.contains(muscle)) {
        _fail('$name uses unknown muscle "$muscle"');
      }
    }
    for (final item in equipment) {
      if (!_equipment.contains(item)) {
        _fail('$name uses unknown equipment "$item"');
      }
    }

    _checkOptional(entry, 'level', _levels);
    _checkOptional(entry, 'force', _forces);
    _checkOptional(entry, 'mechanic', _mechanics);

    if (!_categories.contains(entry['category'])) {
      _fail('$name uses unknown category "${entry['category']}"');
    }
  }
}

void _checkOptional(
  Map<String, Object?> entry,
  String field,
  Set<String> allowed,
) {
  final value = entry[field];
  if (value != null && !allowed.contains(value)) {
    _fail('${entry['name']} uses unknown $field "$value"');
  }
}

List<String> _muscleList(Object? raw) {
  return [
    for (final muscle in _strings(raw))
      _muscleAliases[muscle.toLowerCase()] ?? muscle.toLowerCase(),
  ];
}

List<String> _equipmentList(Object? raw) {
  final values = raw is String ? [raw] : _strings(raw);
  return [
    for (final item in values)
      _equipmentAliases[item.toLowerCase()] ?? item.toLowerCase(),
  ];
}

/// "none" beside "barbell" is a contradiction, not a longer list.
List<String> _mergeEquipment(List<String> a, List<String> b) {
  final merged = _union(a, b);
  if (merged.length > 1) merged.remove('body only');
  return merged;
}

List<String> _variations(Map<String, dynamic> raw) {
  return _union(
    _strings(raw['aliases']),
    _union(_strings(raw['variation_on']), _strings(raw['variations_on'])),
  );
}

List<String> _lines(Object? raw) {
  final values = raw is String ? raw.split('\n') : _strings(raw);
  return [
    for (final line in values)
      if (line.trim().isNotEmpty) line.trim(),
  ];
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final value in raw)
      if (value != null && value.toString().trim().isNotEmpty)
        value.toString().trim(),
  ];
}

List<String> _union(List<String> a, List<String> b) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in [...a, ...b]) {
    if (seen.add(value.toLowerCase())) result.add(value);
  }
  return result;
}

String _category(Object? raw) {
  final value = _optional(raw)?.toLowerCase() ?? '';
  return value.isEmpty ? 'strength' : value;
}

String _requiredString(Object? raw, String what) {
  final value = _optional(raw);
  if (value == null) throw FormatException('missing $what');
  return value;
}

String? _optional(Object? raw) {
  if (raw is! String) return null;
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

String _slug(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  return slug.isEmpty ? 'exercise' : slug;
}

String _key(String name) =>
    name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '');

List<Map<String, dynamic>> _readList(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! List) throw FormatException('$path is not a JSON list');
  return decoded.whereType<Map<String, dynamic>>().toList();
}

Map<String, dynamic> _readMap(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$path is not a JSON object');
  }
  return decoded;
}

Never _fail(String message) => throw StateError('catalogue: $message');
