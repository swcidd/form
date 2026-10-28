import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/taxonomy.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';

/// The last step of making a workout: name it and say what kind of training it
/// is.
///
/// The session already exists by the time this screen opens. "Create my own
/// workout" writes a draft named [draftTitle] so there is something to add
/// exercises to, and this screen finishes it off. That is why there is no
/// exercise list and no date here: the exercises are already in the session,
/// and its date was decided when it was created.
///
/// Field-for-field this is the Edit workout screen. It is a separate screen
/// rather than a mode of that one because the two differ in intent - finishing
/// a draft nobody has named yet, against amending a session that is already on
/// the calendar - and the copy carries that difference. If they diverge much
/// past this, they should share the form rather than the screen.
class SaveWorkoutScreen extends StatefulWidget {
  const SaveWorkoutScreen({super.key, required this.route});

  /// The route that reached this screen; its name carries the workout id.
  final RouteSettings route;

  static const String routeName = '/save-workout';

  static String routeFor(String workoutId) => '$routeName/$workoutId';

  /// The name a draft is created under, before anybody has chosen one.
  static const String draftTitle = 'New Workout';

  @override
  State<SaveWorkoutScreen> createState() => _SaveWorkoutScreenState();
}

class _SaveWorkoutScreenState extends State<SaveWorkoutScreen> {
  late final TextEditingController _name;

  Modality? _modality;
  WorkoutSplit? _split;
  TrainingGoal? _goal;

  @override
  void initState() {
    super.initState();
    final workout = _current();
    _name = TextEditingController(text: workout?.title ?? '');
    _modality = workout?.modality;
    _split = workout?.split;
    _goal = workout?.goal;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Workout? _current() {
    final id = _idFromPath(widget.route.name);
    return id == null ? null : context.read<WorkoutProvider>().byId(id);
  }

  static String? _idFromPath(String? routeName) {
    if (routeName == null) return null;
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return Uri.decodeComponent(segments[1]);
  }

  /// Names the session and records what kind of training it is.
  ///
  /// `copyWith` takes `null` on a classification as "clear it", so a group the
  /// user tapped off ends up unset rather than keeping the value they removed.
  void _save() {
    final provider = context.read<WorkoutProvider>();
    final workout = _current();
    final navigator = Navigator.of(context);
    if (workout == null) return;

    final trimmed = _name.text.trim();
    final updated = workout.copyWith(
      title: trimmed.isEmpty ? SaveWorkoutScreen.draftTitle : trimmed,
      modality: _modality,
      split: _split,
      goal: _goal,
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

    final text = context.text;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Toolbar(
              onBack: () => Navigator.of(context).maybePop(),
              onSave: _save,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text('NAME THIS SESSION', style: text.labelCaps),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: SaveWorkoutScreen.draftTitle,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.control,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.control,
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Group(
                    label: 'MODALITY',
                    values: Modality.values,
                    labelOf: (value) => value.label,
                    selected: _modality,
                    onSelected: (value) => setState(
                      () => _modality = _modality == value ? null : value,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Group(
                    label: 'SPLIT',
                    values: WorkoutSplit.values,
                    labelOf: (value) => value.label,
                    selected: _split,
                    onSelected: (value) =>
                        setState(() => _split = _split == value ? null : value),
                  ),
                  const SizedBox(height: 24),
                  _Group(
                    label: 'GOAL',
                    values: TrainingGoal.values,
                    labelOf: (value) => value.label,
                    selected: _goal,
                    onSelected: (value) =>
                        setState(() => _goal = _goal == value ? null : value),
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

/// Go Back · Save Workout · Save, the same shape as the picker it follows.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onBack, required this.onSave});

  final VoidCallback onBack;
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
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Go Back',
                    style: text.annotation.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Save Workout',
                  style: text.annotation.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onSave,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Save',
                    style: text.annotation.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
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

/// A labelled group of single-select pills, wrapped rather than scrolled.
class _Group<T> extends StatelessWidget {
  const _Group({
    required this.label,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final String Function(T value) labelOf;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelCaps),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final value in values)
              _Pill(
                label: labelOf(value),
                selected: value == selected,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: selected,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: context.text.annotation.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
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
