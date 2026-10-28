import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/library_exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/planned_exercise_card.dart';
import 'add_exercise_screen.dart';

/// Builds a workout: what it is called, and what is in it.
///
/// The last step of the flow the library starts:
///
///   Library -> Create Own Workout -> Add Exercises -> Next -> here -> Save
///
/// The session already exists by the time this opens. "Create Own Workout"
/// writes a draft so there is something to attach exercises to, the picker
/// appends to it, and this screen names it and plans the sets. That is why
/// there is no date here and no classification: a workout carries a date from
/// the moment it is made, and modality, split and goal are set on the edit
/// screen for anyone who wants them.
///
/// Every edit writes straight through to the store rather than being held here
/// and saved at the end. Backing out with Cancel therefore leaves the plan as
/// it stands - which is honest, because the workout already exists and the user
/// was told they were editing it, not filling in a form.
class WorkoutBuilderScreen extends StatefulWidget {
  const WorkoutBuilderScreen({super.key, required this.route});

  /// The route that reached this screen; its name carries the workout id.
  final RouteSettings route;

  static const String routeName = '/workout-builder';

  static String routeFor(String workoutId) => '$routeName/$workoutId';

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final _name = TextEditingController();

  /// Which workout the name field was filled from, so a rebuild does not
  /// overwrite what the user is typing.
  String? _seeded;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  static String? _idFromPath(String? routeName) {
    if (routeName == null) return null;
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return Uri.decodeComponent(segments[1]);
  }

  void _replaceLog(Workout workout, int index, ExerciseLog log) {
    final logs = List.of(workout.logs);
    logs[index] = log;
    context.read<WorkoutProvider>().updateWorkout(workout.copyWith(logs: logs));
  }

  void _removeLog(Workout workout, int index) {
    final logs = List.of(workout.logs)..removeAt(index);
    context.read<WorkoutProvider>().updateWorkout(workout.copyWith(logs: logs));
  }

  /// Appends what the picker returns, skipping anything already in the line-up.
  ///
  /// The picker does not know what the session holds, so picking the same
  /// exercise twice would otherwise add it twice. Skipped rather than merged:
  /// deciding which of two prescriptions wins is not a call to make silently.
  Future<void> _addExercises(Workout workout) async {
    final provider = context.read<WorkoutProvider>();
    final picked = await Navigator.of(context)
        .pushNamed<List<LibraryExercise>>(AddExerciseScreen.routeName);
    if (picked == null || picked.isEmpty) return;

    // The workout as the store holds it now, not the copy this build captured.
    final current = provider.byId(workout.id);
    if (current == null) return;

    final already = {
      for (final log in current.logs) log.exercise.name.toLowerCase(),
    };
    final added = [
      for (final exercise in picked)
        if (!already.contains(exercise.name.toLowerCase()))
          ExerciseLog.planned(exercise),
    ];
    if (added.isEmpty) return;

    provider.updateWorkout(current.copyWith(logs: [...current.logs, ...added]));
  }

  void _save(Workout workout) {
    final provider = context.read<WorkoutProvider>();
    final navigator = Navigator.of(context);

    final trimmed = _name.text.trim();
    final updated = workout.copyWith(
      title: trimmed.isEmpty ? workout.title : trimmed,
    );
    provider.updateWorkout(updated);
    navigator.pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final id = _idFromPath(widget.route.name);
    final workout = id == null ? null : provider.byId(id);
    if (workout == null) return const _NotFound();

    if (_seeded != workout.id) {
      _seeded = workout.id;
      _name.text = workout.title;
    }

    final text = context.text;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Toolbar(
              onCancel: () => Navigator.of(context).maybePop(),
              onSave: () => _save(workout),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  TextField(
                    key: const Key('workout_name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    style: Theme.of(context).textTheme.headlineMedium,
                    decoration: const InputDecoration(
                      hintText: 'Name this workout',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(height: 24),
                  if (workout.logs.isEmpty)
                    // The state a new workout actually opens in. Without it the
                    // screen would be a toolbar and a name field.
                    //
                    // Padded, not height-constrained: `EmptyState` sizes to its
                    // own content, and boxing it overflows on a short viewport.
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyState(
                        icon: Icons.fitness_center_rounded,
                        title: 'Nothing in it yet',
                        message:
                            'Add the exercises you plan to train. Sets and '
                            'weights can be filled in now or as you go.',
                      ),
                    )
                  else
                    for (var i = 0; i < workout.logs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PlannedExerciseCard(
                          log: workout.logs[i],
                          index: i,
                          onChanged: (log) => _replaceLog(workout, i, log),
                          onRemove: () => _removeLog(workout, i),
                        ),
                      ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _addExercises(workout),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Exercise'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every change is saved as you make it.',
                    style: text.annotation,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cancel · New Workout · Save, the same shape as the picker it follows.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
              ),
              child: const Text('Cancel'),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'New Workout',
                  style: text.annotation.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onSave,
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Session not found',
        message: 'It may have been removed from your calendar.',
      ),
    );
  }
}
