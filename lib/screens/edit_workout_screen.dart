import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/taxonomy.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';

/// Edits a session that already exists: what it is, how it is organised, what
/// it is for, and what it is called.
///
/// The screen owns no copy of the workout. It reads the one the provider holds,
/// seeds its controls from it, and writes a single edited record back through
/// [WorkoutProvider.updateWorkout] on save — so the store remains the only
/// place a session is decided.
///
/// The classification is the part no other screen edits today: the model makes
/// modality, split and goal nullable precisely because a session made before
/// those questions existed has no honest answer, so each group starts from the
/// current value and may be left unset. A tapped pill that is already selected
/// clears it rather than forcing a value the user never chose.
class EditWorkoutScreen extends StatelessWidget {
  const EditWorkoutScreen({super.key, required this.route});

  /// The route that reached this screen; its name carries the workout id.
  final RouteSettings route;

  static const String routeName = '/edit-workout';

  static String routeFor(String workoutId) => '$routeName/$workoutId';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final id = _idFromPath(route.name);
    final workout = id == null ? null : provider.byId(id);

    if (workout == null) return const _NotFound();

    return _Editor(workout: workout);
  }

  /// The workout id from `/edit-workout/<id>`, in the same shape
  /// [WorkoutDetailScreen] reads its own route in.
  static String? _idFromPath(String? routeName) {
    if (routeName == null) return null;
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return Uri.decodeComponent(segments[1]);
  }
}

/// The not-found state every screen showing a session falls back to, rather
/// than throwing when its id no longer resolves.
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

/// The form itself, holding the in-progress edits until they are saved.
///
/// Local state on purpose: the user is mid-edit and a keystroke on the name
/// must not be a store write, so nothing reaches the provider until Save.
class _Editor extends StatefulWidget {
  const _Editor({required this.workout});

  final Workout workout;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late Modality? _modality = widget.workout.modality;
  late WorkoutSplit? _split = widget.workout.split;
  late TrainingGoal? _goal = widget.workout.goal;
  late final TextEditingController _name = TextEditingController(
    text: widget.workout.title,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Writes the edits through the store and closes only if they landed.
  ///
  /// `updateWorkout` returns false when nothing matched, and popping anyway
  /// would tell the user the change saved when the record is gone. The updated
  /// workout is handed back so the caller can navigate to or re-render it
  /// without a second lookup.
  void _save() {
    final provider = context.read<WorkoutProvider>();
    final updated = _edited();
    if (!provider.updateWorkout(updated)) return;
    Navigator.of(context).pop(updated);
  }

  /// The workout as edited.
  ///
  /// [Workout.copyWith] treats a null argument as "leave it alone", which is
  /// the right default everywhere else and the wrong one here: a user clearing
  /// the selected modality means unset, not unchanged. The common path stays on
  /// The session as the form currently reads it.
  ///
  /// `copyWith` takes `null` on a classification as "clear it", so a group the
  /// user tapped off ends up unset rather than keeping the value they removed.
  Workout _edited() {
    return widget.workout.copyWith(
      title: _name.text.trim(),
      modality: _modality,
      split: _split,
      goal: _goal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SafeArea(bottom: false, child: _Toolbar(onSave: _save)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Group(
                    label: 'MODALITY',
                    children: [
                      for (final value in Modality.values)
                        _Pill(
                          label: value.label,
                          selected: value == _modality,
                          onTap: () => setState(
                            () => _modality = value == _modality ? null : value,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Group(
                    label: 'SPLIT',
                    children: [
                      for (final value in WorkoutSplit.values)
                        _Pill(
                          label: value.label,
                          selected: value == _split,
                          onTap: () => setState(
                            () => _split = value == _split ? null : value,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Group(
                    label: 'GOAL',
                    children: [
                      for (final value in TrainingGoal.values)
                        _Pill(
                          label: value.label,
                          selected: value == _goal,
                          onTap: () => setState(
                            () => _goal = value == _goal ? null : value,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // The design also carries a WORKOUT DESCRIPTION group. The
                  // model has no description or notes field and adding one means
                  // a database migration, so it is deliberately left out here
                  // rather than stood in for by a control that persists nothing.
                  _NameField(controller: _name),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back, the screen title, and Save.
///
/// Leaving with unsaved edits is allowed on purpose: the name and the
/// classification are cheap to redo, and a confirm dialog on every back tap
/// costs more than the rare redo it would prevent, so there is none.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Edit workout',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onSave,
                child: Text(
                  'Save',
                  style: text.exerciseMeta.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One labelled classification group: the caps eyebrow and its selectable pills.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelCaps.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

/// A single-select classification pill, in the app's filter-pill shape.
///
/// Deliberately not a [ChoiceChip]: the design's pill is 36 tall with an 18
/// radius and an ink fill when selected, which is the same control the library
/// filters with rather than Material's 44-tall default.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: context.text.exerciseMeta.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// The session's name, seeded from the workout and never validated.
///
/// An untitled session is still a real one — the model requires a title but not
/// a meaningful one — so saving a blank name is allowed rather than blocked.
class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WORKOUT NAME',
          style: context.text.labelCaps.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            textAlignVertical: TextAlignVertical.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurface),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: scheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintText: 'Name this workout',
              hintStyle: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
