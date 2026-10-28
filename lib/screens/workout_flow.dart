import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/library_exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import 'add_exercise_screen.dart';
import 'save_workout_screen.dart';

/// Makes a workout, from nothing to named.
///
/// Three steps in one place, because a workout has two entry points - the
/// calendar's plan button and the library's create button - and both have to
/// leave the user somewhere identical:
///
///  1. **Create the draft.** The session is written straight away under
///     [SaveWorkoutScreen.draftTitle], so there is something to attach
///     exercises to. A flow that collected a list first and wrote at the end
///     would have nothing to add exercise *to*.
///  2. **Pick the exercises.** [AddExerciseScreen] appends to that draft.
///  3. **Name and classify it.** [SaveWorkoutScreen] sets the title, modality,
///     split and goal.
///
/// Returns the saved session, or null when the user abandoned the picker.
///
/// Backing out of the *picker* deletes the draft: nothing has been chosen and
/// leaving a "New Workout" behind on the calendar is litter. Backing out of the
/// *save screen* keeps it, on purpose - the exercises are already in it, and
/// finishing the naming later is a legitimate thing to do.
Future<Workout?> startWorkout(BuildContext context, {DateTime? date}) async {
  final provider = context.read<WorkoutProvider>();
  final navigator = Navigator.of(context);

  final draft = provider.addWorkout(
    Workout(
      id: '',
      title: SaveWorkoutScreen.draftTitle,
      date: date ?? provider.today,
      status: WorkoutStatus.planned,
      durationMin: 45,
      estimatedKcal: 0,
      targetMuscleGroups: const [],
      equipment: const [],
      logs: const [],
    ),
  );

  final picked = await navigator.pushNamed<List<LibraryExercise>>(
    AddExerciseScreen.routeName,
  );
  if (picked == null) {
    provider.deleteWorkout(draft.id);
    return null;
  }

  if (picked.isNotEmpty) {
    provider.updateWorkout(
      draft.copyWith(
        logs: [
          ...draft.logs,
          for (final exercise in picked) ExerciseLog.planned(exercise),
        ],
      ),
    );
  }

  final saved = await navigator.pushNamed<Workout>(
    SaveWorkoutScreen.routeFor(draft.id),
  );
  return saved ?? provider.byId(draft.id);
}
