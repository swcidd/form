import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/exercise.dart';
import '../models/library_exercise.dart';
import '../models/taxonomy.dart';
import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The form for creating a workout, presented as a centred dialog.
///
/// Four questions, because this is reached from the bar rather than chosen
/// deliberately. A lifter tapping the action mid-session wants to start
/// training, not fill in a questionnaire, so every row is a single tap and
/// nothing is required: a session created without touching them stays
/// unclassified rather than being called "General strength" on the user's
/// behalf. The questions are the ones that change what the next screen shows -
/// its name, its date, and the three classification axes the library filters
/// and the detail header read. Everything else - exercises, sets - is added
/// from the workout itself once it exists.
///
/// Returns the created [Workout] through [Navigator.pop], rather than writing
/// to the provider directly. The dialog owns no store, so a caller that
/// abandons it has nothing to undo, and the caller decides whether to open the
/// new session or just leave it in the list.
class NewWorkoutDialog extends StatefulWidget {
  const NewWorkoutDialog({
    super.key,
    this.initialDate,
    this.exercises = const [],
  });

  final DateTime? initialDate;

  /// Exercises the session already has, chosen in the Add Exercise picker.
  ///
  /// The picker runs first, so this dialog is the second half of one flow: the
  /// user says what they are training, then names it. Sets are deliberately not
  /// invented here - each exercise lands as a planned entry with no sets, which
  /// the logging screen already handles ("No sets planned. Add one below.")
  /// rather than opening on numbers nobody chose.
  final List<LibraryExercise> exercises;

  /// Shows the dialog and resolves to the new workout, or null if dismissed.
  ///
  /// Null covers every way out - the back gesture, the barrier, Cancel - so
  /// callers do not have to distinguish them.
  static Future<Workout?> show(
    BuildContext context, {
    DateTime? initialDate,
    List<LibraryExercise> exercises = const [],
  }) {
    return showDialog<Workout>(
      context: context,
      builder: (_) =>
          NewWorkoutDialog(initialDate: initialDate, exercises: exercises),
    );
  }

  @override
  State<NewWorkoutDialog> createState() => _NewWorkoutDialogState();
}

class _NewWorkoutDialogState extends State<NewWorkoutDialog> {
  final _name = TextEditingController();
  late DateTime _date;

  /// The three classification axes. Left null until the user taps one, so the
  /// dialog never claims a session is "General strength" on their behalf.
  Modality? _modality;
  WorkoutSplit? _split;
  TrainingGoal? _goal;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _name.text.trim();
    Navigator.of(context).pop(
      Workout(
        id: '',
        title: trimmed.isEmpty ? _defaultTitle() : trimmed,
        date: DateTime(_date.year, _date.month, _date.day),
        status: WorkoutStatus.planned,
        durationMin: 45,
        estimatedKcal: 0,
        targetMuscleGroups: const [],
        equipment: const [],
        logs: [
          for (final exercise in widget.exercises)
            ExerciseLog(
              exercise: Exercise(
                name: exercise.name,
                // The catalogue allows an empty equipment list on a malformed
                // saved row; a blank label is better than a made-up one.
                equipment: exercise.equipment.isEmpty
                    ? ''
                    : exercise.equipment.first,
                muscleGroups: exercise.primaryMuscles,
              ),
              sets: const [],
            ),
        ],
        modality: _modality,
        split: _split,
        goal: _goal,
      ),
    );
  }

  /// Offers a starting point for someone who does not want to name a session.
  ///
  /// "Training" rather than "Workout" so the title is not the same word as the
  /// app, and an empty name is not rejected - a lifter mid-session wants the
  /// log, not a naming exercise.
  String _defaultTitle() => 'Training ${DateFormat('MMM d').format(_date)}';

  Future<void> _pickDate() async {
    // Wide enough that no calendar position reaches the edge, and the seed is
    // clamped anyway: `showDatePicker` asserts when its initial date falls
    // outside the range, and the date arriving here is whichever day the
    // calendar is pointed at.
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstDate)
          ? firstDate
          : (_date.isAfter(lastDate) ? lastDate : _date),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('New workout'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NAME THIS SESSION', style: context.text.labelCaps),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: _defaultTitle(),
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
                // Deliberately no validator. An untitled session is still a
                // real one, and forcing a name here is friction in front of
                // the one thing the lifter opened the app to do.
                helperText: 'Leave blank to use the date.',
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            Text('MODALITY', style: context.text.labelCaps),
            const SizedBox(height: 8),
            _ChoiceWrap<Modality>(
              values: Modality.values,
              selected: _modality,
              labelOf: (value) => value.label,
              onSelected: (value) => setState(() => _modality = value),
            ),
            const SizedBox(height: 18),
            Text('SPLIT', style: context.text.labelCaps),
            const SizedBox(height: 8),
            _ChoiceWrap<WorkoutSplit>(
              values: WorkoutSplit.values,
              selected: _split,
              labelOf: (value) => value.label,
              onSelected: (value) => setState(() => _split = value),
            ),
            const SizedBox(height: 18),
            Text('GOAL', style: context.text.labelCaps),
            const SizedBox(height: 8),
            _ChoiceWrap<TrainingGoal>(
              values: TrainingGoal.values,
              selected: _goal,
              labelOf: (value) => value.label,
              onSelected: (value) => setState(() => _goal = value),
            ),
            const SizedBox(height: 18),
            Text('DATE', style: context.text.labelCaps),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: AppRadius.control,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.control,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, MMM d').format(_date),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: scheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Start'),
        ),
      ],
    );
  }
}

/// A wrapping row of single-select pills.
///
/// Wrapping rather than scrolling: seven modalities do not fit one line on a
/// 320dp phone, and a horizontal scroll would hide the three new disciplines
/// behind a gesture nobody knows is there.
class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(
              labelOf(value),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: value == selected
                    ? scheme.onPrimary
                    : scheme.onSurfaceVariant,
              ),
            ),
            selected: value == selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            selectedColor: scheme.primary,
            backgroundColor: scheme.surfaceContainerHigh,
            side: BorderSide(color: scheme.outlineVariant),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
