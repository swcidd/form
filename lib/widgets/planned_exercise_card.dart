import 'package:flutter/material.dart';

import '../data/exercise_images.dart';
import '../models/exercise.dart';
import '../models/library_exercise.dart';
import '../theme/app_typography.dart';

/// One exercise in the workout builder: what it is, and the sets it is planned
/// for.
///
/// Deliberately says nothing about rest or notes. The reference app puts a rest
/// timer and a note on every card and both are worth having, but a plan is
/// about sets - and a chip that opens a sheet nobody has designed is an
/// affordance with no destination.
///
/// Stateless, and every edit is reported upward: the card keeps no copy of the
/// plan, so two cards cannot drift from the workout they were built from.
class PlannedExerciseCard extends StatelessWidget {
  const PlannedExerciseCard({
    super.key,
    required this.log,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final ExerciseLog log;

  /// Position in the line-up, so the card can say which exercise it is when a
  /// screen reader has nothing else to go on.
  final int index;

  final ValueChanged<ExerciseLog> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catalogue = _catalogueView(log.exercise);
    final bundled = ExerciseImages.bundledAsset(catalogue);
    final placeholder = _PhotoPlaceholder();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: bundled != null
                      ? Image.asset(
                          bundled,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => placeholder,
                        )
                      : Image.network(
                          ExerciseImages.forExercise(catalogue),
                          fit: BoxFit.cover,
                          cacheWidth: 120,
                          excludeFromSemantics: true,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : placeholder,
                          errorBuilder: (_, _, _) => placeholder,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  log.exercise.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Removing is one tap and re-adding is two, so this asks for no
              // confirmation.
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove ${log.exercise.name}',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SetTable(log: log, onChanged: onChanged),
        ],
      ),
    );
  }

  /// The catalogue shape the photo needs.
  ///
  /// A log carries only the three fields the logging and summary screens read,
  /// so the muscle and equipment the image is chosen from are rebuilt here
  /// rather than stored twice on every set.
  LibraryExercise _catalogueView(Exercise exercise) => LibraryExercise(
    name: exercise.name,
    equipment: exercise.equipment.isEmpty ? const [] : [exercise.equipment],
    category: 'strength',
    primaryMuscles: exercise.muscleGroups,
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.fitness_center_rounded,
      size: 20,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// The sets a session is planned for: a number, a weight, a rep count.
class _SetTable extends StatelessWidget {
  const _SetTable({required this.log, required this.onChanged});

  final ExerciseLog log;
  final ValueChanged<ExerciseLog> onChanged;

  void _updateSet(int index, WorkoutSet set) {
    final sets = List.of(log.sets);
    sets[index] = set;
    onChanged(log.copyWith(sets: sets));
  }

  void _addSet() {
    // Zero rather than a guess: a planned weight nobody chose is worse than an
    // obvious blank to fill in.
    onChanged(
      log.copyWith(sets: [...log.sets, const WorkoutSet(reps: 0, weightKg: 0)]),
    );
  }

  void _removeSet(int index) {
    onChanged(log.copyWith(sets: List.of(log.sets)..removeAt(index)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(width: 44, child: Text('SET', style: text.labelCaps)),
            const SizedBox(width: 8),
            Expanded(child: Text('KG', style: text.labelCaps)),
            const SizedBox(width: 8),
            Expanded(child: Text('REPS', style: text.labelCaps)),
            const SizedBox(width: 36),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < log.sets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${i + 1}', style: text.annotation),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    value: log.sets[i].weightKg,
                    label: 'Set ${i + 1} weight in kilograms',
                    onChanged: (value) =>
                        _updateSet(i, log.sets[i].copyWith(weightKg: value)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    value: log.sets[i].reps.toDouble(),
                    label: 'Set ${i + 1} repetitions',
                    onChanged: (value) => _updateSet(
                      i,
                      log.sets[i].copyWith(reps: value.round()),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeSet(i),
                  tooltip: 'Remove set ${i + 1}',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: _addSet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Set'),
          ),
        ),
      ],
    );
  }
}

/// A weight or rep count.
///
/// Keeps no state of its own beyond what the field displays: the value lives on
/// the plan, and every keystroke writes it back, so backing out of the screen
/// cannot leave an edit stranded in a controller.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      // 52 rather than 40: at 40 with dense padding the field read as a label
      // with a line under it rather than somewhere to type a weight.
      height: 52,
      child: TextFormField(
        initialValue: value == 0 ? '' : _trim(value),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: context.text.annotation.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: '—',
          hintStyle: context.text.annotation.copyWith(
            fontSize: 15,
            color: scheme.outline,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
        // A field that cannot be parsed clears the value rather than silently
        // keeping the old one: "abc" is not a weight.
        onChanged: (raw) => onChanged(double.tryParse(raw.trim()) ?? 0),
      ),
    );
  }

  static String _trim(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';
}
