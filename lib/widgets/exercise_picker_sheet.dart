import 'package:flutter/material.dart';

import '../exercise_library.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Picks one exercise from the catalogue.
///
/// The picker reads the bundled catalogue rather than the live wger feed: the
/// session screen has to work while the phone is offline, and adding an
/// exercise is editing local training data, not browsing a remote library.
class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({super.key, this.loadExercises});

  /// Replaces the bundled load in tests and in callers that already hold the
  /// catalogue. Null reads [ExerciseLibrary.loadAll].
  final Future<List<LibraryExercise>> Function()? loadExercises;

  /// Shows the picker and resolves to the chosen exercise, or null on dismiss.
  static Future<LibraryExercise?> show(
    BuildContext context, {
    Future<List<LibraryExercise>> Function()? loadExercises,
  }) {
    return showModalBottomSheet<LibraryExercise>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => ExercisePickerSheet(loadExercises: loadExercises),
    );
  }

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  late Future<List<LibraryExercise>> _exercises;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _exercises = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<LibraryExercise>> _load() =>
      (widget.loadExercises ?? ExerciseLibrary.loadAll)();

  void _retry() {
    setState(() => _exercises = _load());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add exercise',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search exercises',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.control,
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.control,
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.control,
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<LibraryExercise>>(
                future: _exercises,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _PickerMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load exercises',
                      message:
                          'The bundled catalogue is unavailable. Try again.',
                      actionLabel: 'Try again',
                      onAction: _retry,
                    );
                  }

                  final matches = _matches(snapshot.data ?? const []);
                  if (matches.isEmpty) {
                    return _PickerMessage(
                      icon: Icons.search_off_rounded,
                      title: _query.trim().isEmpty
                          ? 'No exercises yet'
                          : 'No matches',
                      message: _query.trim().isEmpty
                          ? 'The catalogue did not contain any exercises.'
                          : 'Try a different name, muscle or piece of '
                                'equipment.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final exercise = matches[index];
                      final detail = [
                        if (exercise.primaryMuscles.isNotEmpty)
                          exercise.primaryMuscles.first,
                        if (exercise.equipment.isNotEmpty)
                          exercise.equipment.first,
                      ].join(' · ');

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.fitness_center_rounded,
                            size: 22,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: text.exerciseMeta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: detail.isEmpty
                            ? null
                            : Text(
                                detail,
                                style: text.annotation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: const Icon(Icons.add_rounded, size: 20),
                        onTap: () => Navigator.of(context).pop(exercise),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LibraryExercise> _matches(List<LibraryExercise> exercises) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return exercises;

    return [
      for (final exercise in exercises)
        if (exercise.name.toLowerCase().contains(query) ||
            exercise.aliases.any(
              (alias) => alias.toLowerCase().contains(query),
            ) ||
            exercise.primaryMuscles.any(
              (muscle) => muscle.toLowerCase().contains(query),
            ) ||
            exercise.equipment.any(
              (item) => item.toLowerCase().contains(query),
            ))
          exercise,
    ];
  }
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.annotation,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
