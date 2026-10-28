import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/library_exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import 'add_exercise_screen.dart';
import 'edit_workout_screen.dart';
import 'set_logging_screen.dart';

/// Pre-workout screen: what the session is, and how the user works on it.
///
/// The layout follows the Figma "Library · Selected Workout Session" frames —
/// the filled one and the empty one: a compact toolbar, a photographic title
/// band, the focus the plan was built around, the exercise line-up (or the
/// framed empty block when there is none), and the action band that adds an
/// exercise and starts the session.
///
/// It is also the hub for everything else about the session, which is why the
/// edit affordance sits beside the line-up rather than in the toolbar: the
/// frame puts it there, and it is what the user reaches for while reading the
/// plan.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, this.route});

  final RouteSettings? route;

  static String routeFor(String id) => '$routeName/$id';
  static const String routeName = '/workout-detail';

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final id = switch (arguments) {
      String value => value,
      Workout value => value.id,
      _ => _idFromPath(route?.name),
    };

    final provider = context.watch<WorkoutProvider>();
    final workout = id == null ? null : provider.byId(id);

    if (workout == null) return const _NotFound();

    final hasExercises = workout.logs.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: _Toolbar(workout: workout),
                  ),
                ),
                SliverToBoxAdapter(child: _Hero(workout: workout)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (workout.targetMuscleGroups.isNotEmpty ||
                            workout.equipment.isNotEmpty) ...[
                          _Focus(workout: workout),
                          const SizedBox(height: 8),
                        ],
                        _LineupHeading(
                          onEdit: () => _openEditor(context, workout),
                        ),
                        if (hasExercises)
                          _Lineup(logs: workout.logs)
                        else
                          const _EmptyExercises(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ActionBand(
            hasExercises: hasExercises,
            onAddExercise: () => _addExercises(context, workout),
            onStart: () =>
                Navigator.of(context)
                    .pushNamed(SetLoggingScreen.routeFor(workout.id)),
          ),
        ],
      ),
    );
  }

  /// Opens the editor for [workout]. A plain push, because the edit screen
  /// writes the change through the store itself.
  void _openEditor(BuildContext context, Workout workout) {
    Navigator.of(context).pushNamed(EditWorkoutScreen.routeFor(workout.id));
  }

  /// Runs the Add Exercise picker and appends what it returns to the line-up.
  ///
  /// Nothing is written until the picker hands something back: a dismissed
  /// screen — the back gesture, or Cancel — returns null, so backing out of the
  /// picker leaves the session exactly as it was. The append is done against
  /// the workout as the store holds it now rather than the copy this build
  /// captured, so a picker that outlived an edit still lands on the latest
  /// record.
  Future<void> _addExercises(BuildContext context, Workout workout) async {
    final provider = context.read<WorkoutProvider>();
    final picked = await Navigator.of(context)
        .pushNamed<List<LibraryExercise>>(AddExerciseScreen.routeName);
    if (picked == null || picked.isEmpty) return;

    final current = provider.byId(workout.id);
    if (current == null) return;

    // The picker does not know what the session already holds, so picking
    // something twice would add a second log for the same exercise. Skipped
    // rather than merged: this screen appends, and deciding which of two
    // prescriptions for one exercise wins is not a call to make silently.
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

  static String? _idFromPath(String? routeName) {
    if (routeName == null) return null;
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return Uri.decodeComponent(segments[1]);
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 16),
            Text(
              'Session not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'It may have been removed from your calendar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.workout});

  final Workout workout;

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
            const Spacer(),
            Text(
              workout.date.day.toString().padLeft(2, '0'),
              style: text.annotation.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmDelete(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 22,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The toolbar's overflow: the session's one remaining destructive action.
  ///
  /// The design's toolbar is icon-only and shows no overflow, but delete is the
  /// only way to remove a session and there is nowhere else in the frame to put
  /// it, so it stays behind the gesture it has always been behind rather than
  /// being dropped. It is on its own now — edit has moved into the line-up
  /// header, where the frame draws it.
  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<WorkoutProvider>();
    final navigator = Navigator.of(context);

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete session'),
              onTap: () => Navigator.of(sheet).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (choice != 'delete') return;
    // The sheet awaited above; the screen may be gone by now.
    if (!context.mounted) return;

    // Deleting takes the session out of the week's counts and off the
    // calendar, and nothing in the app can bring it back.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete this session?'),
        content: const Text(
          'It will be removed from your calendar and your training history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    provider.deleteWorkout(workout.id);
    navigator.maybePop();
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final focus = [
      if (workout.modality != null) workout.modality!.label.toUpperCase(),
      if (workout.split != null) workout.split!.label.toUpperCase(),
    ].join(' / ');
    final meta = [
      if (workout.durationMin > 0) '${workout.durationMin} min',
      '${workout.logs.length} '
          '${workout.logs.length == 1 ? 'exercise' : 'exercises'}',
      '${workout.totalSets} sets',
    ].join('  /  ');

    return SizedBox(
      height: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/workout_hero.png',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xE8121512), Color(0x21121512)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  focus.isEmpty
                      ? workout.targetMuscleGroups
                            .take(2)
                            .join(' / ')
                            .toUpperCase()
                      : focus,
                  style: text.labelCaps.copyWith(
                    fontSize: 10,
                    color: const Color(0xFFD5FC61),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  workout.title.toUpperCase(),
                  style: text.dataHero.copyWith(
                    fontSize: 44,
                    height: 0.98,
                    color: const Color(0xFFF2F1E9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  style: text.annotation.copyWith(
                    fontSize: 12,
                    color: const Color(0xFFF2F1E9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Focus extends StatelessWidget {
  const _Focus({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final values = [...workout.targetMuscleGroups, ...workout.equipment];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S FOCUS",
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 5),
        Text(
          values.join('  ·  '),
          style: text.exerciseMeta.copyWith(
            fontSize: 13,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LineupHeading extends StatelessWidget {
  const _LineupHeading({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            'THE LINEUP',
            style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          // The frame's 90x44 Edit action: edit lives here now rather than in
          // the toolbar's overflow, because the line-up is what it changes.
          // Announced as a button: a bare GestureDetector reads as plain text
          // to a screen reader, and this is the only way into editing.
          Semantics(
            button: true,
            label: 'Edit workout',
            child: GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 90,
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Edit workout',
                    style: text.exerciseMeta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lineup extends StatelessWidget {
  const _Lineup({required this.logs});

  final List<ExerciseLog> logs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < logs.length; index++)
          _ExerciseRow(index: index, log: logs[index]),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.index, required this.log});

  final int index;
  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              style: text.dataMetric.copyWith(
                fontSize: 23,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.exercise.name,
                  style: text.exerciseMeta.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.sets.length} sets × ${log.setScheme}'
                  '${log.heaviestWeight == '0' ? '' : '  ·  ${log.heaviestWeight} kg'}',
                  style: text.annotation.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              '${log.restSeconds}s rest',
              textAlign: TextAlign.end,
              style: text.annotation.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// The empty variant of the line-up: the framed block the empty frame draws in
/// place of the exercise rows.
///
/// A surface rather than bare text, so an empty session reads as a deliberate
/// state instead of a section that failed to load — and the Add Exercise action
/// in the band below is the way out of it.
class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      height: 336,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 28,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'NOTHING LINED UP YET',
            textAlign: TextAlign.center,
            style: text.programBadge.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'This session has no exercises yet.',
            textAlign: TextAlign.center,
            style: text.exerciseMeta.copyWith(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The action band at the foot of the screen: add to the line-up, and start.
///
/// Laid out from the frame's 112-tall band — two 56-tall controls side by side
/// with a 12 gap, sized 152 and 190 so they fill the frame's 354 of content
/// width exactly. The empty session drops the band to Add Exercise alone,
/// because there is nothing yet to start.
class _ActionBand extends StatelessWidget {
  const _ActionBand({
    required this.hasExercises,
    required this.onAddExercise,
    required this.onStart,
  });

  final bool hasExercises;
  final VoidCallback onAddExercise;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                flex: 152,
                child: _AddExerciseButton(onPressed: onAddExercise),
              ),
              if (hasExercises) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 190,
                  child: _StartWorkoutButton(onPressed: onStart),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The design's secondary action: a tonal 56-tall control with the add glyph.
class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // The label gives way before the control does: at the frame's width both
      // sit side by side with room to spare, but a 320dp phone cannot hold the
      // two at their full size, and ellipsis beats an overflow stripe.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, size: 22, color: scheme.onSurface),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Add Exercise',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.exerciseMeta.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The design's primary action: an ink-filled control that opens the log.
class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Start workout',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelCaps.copyWith(
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.play_arrow_rounded, size: 22, color: scheme.onPrimary),
        ],
      ),
    );
  }
}
