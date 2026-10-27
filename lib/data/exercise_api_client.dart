import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/library_exercise.dart';

/// Raised when the wger REST API cannot be reached or sends unusable data.
///
/// Every failure this client can hit - no connection, HTTP error, malformed
/// body - arrives as this one type, so the catalogue above it has exactly one
/// thing to catch before falling back to the bundled data sets.
class ExerciseApiException implements Exception {
  const ExerciseApiException(this.message);

  final String message;

  @override
  String toString() => 'ExerciseApiException: $message';
}

/// Reads exercises from the public wger REST API.
///
/// wger (https://wger.de) is free to use and its exercise endpoints need no
/// API key for reads. Entries arrive with an English translation, a category,
/// muscles and equipment - everything the library card draws. The model they
/// are mapped onto is [LibraryExercise], the same one the bundled sets parse
/// into, so the grid has a single shape to render whichever source answered.
class ExerciseApiClient {
  ExerciseApiClient({
    http.Client? client,
    this.baseUrl = 'https://wger.de',
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  /// Fetches up to [limit] exercises with English translations.
  ///
  /// The catalogue is 900+ entries on wger; the card grid only needs a first
  /// page, and loading more than the user can scroll to would be waste.
  Future<List<LibraryExercise>> fetchExercises({int limit = 60}) async {
    final uri = Uri.parse('$baseUrl/api/v2/exerciseinfo/')
        .replace(queryParameters: {'language': '2', 'limit': '$limit'});

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on Exception catch (error) {
      throw ExerciseApiException('could not reach wger.de ($error)');
    }

    if (response.statusCode != 200) {
      throw ExerciseApiException(
        'wger.de answered HTTP ${response.statusCode}',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw ExerciseApiException('wger.de sent invalid JSON ($error)');
    }

    final results = decoded is Map<String, dynamic> ? decoded['results'] : null;
    if (results is! List) {
      throw const ExerciseApiException('wger.de payload has no results list');
    }

    final exercises = <LibraryExercise>[];
    for (final entry in results) {
      if (entry is! Map<String, dynamic>) continue;
      final exercise = _parse(entry);
      if (exercise != null) exercises.add(exercise);
    }
    return exercises;
  }

  /// Maps one wger entry; null when it has no usable translation.
  LibraryExercise? _parse(Map<String, dynamic> json) {
    final translations = (json['translations'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (translations.isEmpty) return null;

    // Language 2 is English; a German-only entry still beats dropping it.
    final translation = translations.firstWhere(
      (t) => t['language'] == 2,
      orElse: () => translations.first,
    );

    final name = ((translation['name'] as String?) ?? '').trim();
    if (name.isEmpty) return null;

    final category =
        (json['category'] as Map<String, dynamic>?)?['name'] as String? ?? '';

    return LibraryExercise(
      catalogueId: _id(json['id']),
      name: name,
      primaryMuscles: _muscles(json['muscles']),
      secondaryMuscles: _muscles(json['muscles_secondary']),
      instructions: _instructions(
        (translation['description'] as String?) ?? '',
      ),
      equipment: _equipment(json['equipment']),
      category: category.isEmpty ? 'strength' : category,
    );
  }

  /// wger's id namespaced so it cannot collide with a bundled free-exercise-db
  /// id once both have been saved.
  String? _id(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : 'wger-$value';
  }

  /// Muscle labels, English names preferred; empty when none.
  List<String> _muscles(Object? raw) {
    final labels = <String>[];
    for (final node in raw as List? ?? const []) {
      if (node is! Map<String, dynamic>) continue;
      final english = ((node['name_en'] as String?) ?? '').trim();
      final latin = ((node['name'] as String?) ?? '').trim();
      final label = english.isNotEmpty ? english : latin;
      if (label.isNotEmpty) labels.add(label);
    }
    return labels;
  }

  /// Equipment names; wger nests them as objects, unlike the bundled sets.
  List<String> _equipment(Object? raw) {
    final names = <String>[];
    for (final node in raw as List? ?? const []) {
      final name = node is Map<String, dynamic> ? node['name'] : null;
      if (name is String && name.isNotEmpty) names.add(name);
    }
    return names;
  }

  /// wger descriptions arrive as HTML; the cards show plain text.
  ///
  /// One string becomes one instruction line. Keeping the list lets the model
  /// hold the bundled catalogue's line-by-line instructions without a second
  /// shape for network entries.
  static List<String> _instructions(String html) {
    final text = html
        .replaceAll(RegExp('<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? const [] : [text];
  }
}
