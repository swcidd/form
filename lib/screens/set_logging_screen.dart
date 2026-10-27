import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import 'workout_summary_screen.dart';

/// Active workout screen: the current exercise, its set table, rest, and the
/// weight/reps for the set being logged.
///
/// The layout follows the Figma "Session · Set logging" frame. Values are read
/// from the plan and written back through [WorkoutProvider], so a completed set
/// is the set the user actually entered rather than a screen-local copy.
class SetLoggingScreen extends StatefulWidget {
  const SetLoggingScreen({super.key, this.route});

  final RouteSettings? route;

  static String routeFor(String id) => '$routeName/$id';
  static const String routeName = '/set-logging';

  @override
  State<SetLoggingScreen> createState() => _SetLoggingScreenState();
}

class _SetLoggingScreenState extends State<SetLoggingScreen> {
  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 0;

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restTotal = seconds;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restRemaining <= 1) {
        timer.cancel();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining -= 1);
      }
    });
  }

  void _extendRest() {
    setState(() {
      _restRemaining += 30;
      _restTotal = _restTotal < _restRemaining ? _restRemaining : _restTotal;
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final id = switch (arguments) {
      String value => value,
      Workout value => value.id,
      _ => _idFromPath(widget.route?.name),
    };

    final provider = context.watch<WorkoutProvider>();
    final workout = id == null ? null : provider.byId(id);

    if (workout == null) return const _NotFound();
    if (workout.logs.isEmpty) return _NoExercises(workout: workout);

    final currentIndex = _currentIndex(workout);
    final current = workout.logs[currentIndex];
    final previous = provider.previousSetsFor(
      current.exercise.name,
      before: workout.date,
    );
    final activeSet = _activeSetIndex(current);
    final allDone = workout.logs.every((log) => log.isFinished);

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
                    child: _SessionToolbar(workout: workout),
                  ),
                ),
                SliverToBoxAdapter(child: _SessionProgress(workout: workout)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CurrentExerciseHeader(
                          index: currentIndex.clamp(0, workout.logs.length - 1),
                          total: workout.logs.length,
                          log: current,
                          previous: previous,
                        ),
                        const SizedBox(height: 12),
                        _SetLog(
                          log: current,
                          logIndex: currentIndex.clamp(
                            0,
                            workout.logs.length - 1,
                          ),
                          workoutId: workout.id,
                          activeSet: activeSet,
                          previous: previous,
                        ),
                        if (_restRemaining > 0) ...[
                          const SizedBox(height: 14),
                          _RestTimer(
                            remaining: _restRemaining,
                            total: _restTotal,
                            onExtend: _extendRest,
                            onSkip: _skipRest,
                          ),
                        ],
                        if (!allDone && activeSet != null) ...[
                          const SizedBox(height: 18),
                          _NextSetEntry(
                            workoutId: workout.id,
                            logIndex: currentIndex,
                            setIndex: activeSet,
                            set: current.sets[activeSet],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _LoggingAction(
            workout: workout,
            logIndex: currentIndex,
            activeSet: activeSet,
            allDone: allDone,
            onLogged: (seconds) {
              if (seconds > 0) _startRest(seconds);
            },
          ),
        ],
      ),
    );
  }

  static int _currentIndex(Workout workout) {
    final index = workout.logs.indexWhere(
      (log) => log.sets.isEmpty || log.sets.any((set) => !set.completed),
    );
    return index >= 0 ? index : 0;
  }

  static int? _activeSetIndex(ExerciseLog log) {
    final index = log.sets.indexWhere((set) => !set.completed);
    return index >= 0 ? index : null;
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
    return const _MessageScreen(
      title: 'Session not found',
      body: 'It may have been removed from your calendar.',
    );
  }
}

class _NoExercises extends StatelessWidget {
  const _NoExercises({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return const _MessageScreen(
      title: 'Nothing to log yet',
      body: 'Add an exercise to this session before you start.',
    );
  }
}

class _MessageScreen extends StatelessWidget {
  const _MessageScreen({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionToolbar extends StatelessWidget {
  const _SessionToolbar({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24,
                color: scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  workout.title.toUpperCase(),
                  style: text.annotation.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${workout.completedSets} / ${workout.totalSets} sets',
                  style: text.exerciseMeta.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                Navigator.of(context)
                    .pushNamed(WorkoutSummaryScreen.routeFor(workout.id)),
            child: Text(
              'Finish',
              style: text.exerciseMeta.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionProgress extends StatelessWidget {
  const _SessionProgress({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 3,
      color: scheme.outlineVariant,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: workout.progress.clamp(0.0, 1.0).toDouble(),
        child: Container(color: scheme.primary),
      ),
    );
  }
}

class _CurrentExerciseHeader extends StatelessWidget {
  const _CurrentExerciseHeader({
    required this.index,
    required this.total,
    required this.log,
    required this.previous,
  });

  final int index;
  final int total;
  final ExerciseLog log;
  final List<WorkoutSet> previous;

  String? get _lastTime {
    if (previous.isEmpty) return null;
    final best = previous.reduce((a, b) => a.weightKg > b.weightKg ? a : b);
    return 'Last time  ${_trim(best.weightKg)} kg × ${best.reps}';
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final reps = log.sets.isEmpty
        ? ''
        : log.sets.length == 1
        ? '${log.sets.length} set × ${log.sets.first.reps} reps'
        : '${log.sets.length} sets × ${log.sets.map((s) => s.reps).reduce((a, b) => a < b ? a : b)}–${log.sets.map((s) => s.reps).reduce((a, b) => a > b ? a : b)} reps';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'EXERCISE ${(index + 1).toString().padLeft(2, '0')} / '
              '${total.toString().padLeft(2, '0')}',
              style: text.labelCaps.copyWith(color: scheme.primary),
            ),
            const Spacer(),
            Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          log.exercise.name.toUpperCase(),
          style: text.exerciseName.copyWith(
            fontSize: 34,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [if (reps.isNotEmpty) reps, '${log.restSeconds}s rest'].join('  /  '),
          style: text.exerciseMeta.copyWith(
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              _lastTime ?? 'No previous data',
              style: text.annotation.copyWith(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SetLog extends StatelessWidget {
  const _SetLog({
    required this.log,
    required this.logIndex,
    required this.workoutId,
    required this.activeSet,
    required this.previous,
  });

  final ExerciseLog log;
  final int logIndex;
  final String workoutId;
  final int? activeSet;
  final List<WorkoutSet> previous;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    if (log.sets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No sets planned. Add one below.',
          style: text.exerciseMeta.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
          child: Row(
            children: [
              _col(context, text, 'SET', flex: 2),
              _col(context, text, 'PREVIOUS', flex: 5),
              _col(context, text, 'KG', flex: 3),
              _col(context, text, 'REPS', flex: 3),
              const SizedBox(width: 44),
            ],
          ),
        ),
        for (var index = 0; index < log.sets.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SetRow(
              log: log,
              workoutId: workoutId,
              logIndex: logIndex,
              setIndex: index,
              active: index == activeSet,
              previous: index < previous.length ? previous[index] : null,
            ),
          ),
      ],
    );
  }

  Widget _col(
    BuildContext context,
    AppText text,
    String label, {
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: text.annotation.copyWith(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.log,
    required this.workoutId,
    required this.logIndex,
    required this.setIndex,
    required this.active,
    required this.previous,
  });

  final ExerciseLog log;
  final String workoutId;
  final int logIndex;
  final int setIndex;
  final bool active;
  final WorkoutSet? previous;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final set = log.sets[setIndex];
    final completed = set.completed;
    final future =
        setIndex > (log.sets.indexWhere((s) => !s.completed)) &&
        !completed &&
        !active;

    Widget value(String textValue, {bool muted = false}) => Text(
      textValue,
      style: text.exerciseMeta.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: muted || future ? scheme.onSurfaceVariant : scheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Container(
      height: active ? 52 : 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? scheme.surface : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '${setIndex + 1}',
              style: text.exerciseMeta.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              previous == null
                  ? '—'
                  : '${_trim(previous!.weightKg)} × ${previous!.reps}',
              style: text.annotation.copyWith(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: value(future ? '—' : _trim(set.weightKg), muted: future),
          ),
          Expanded(
            flex: 3,
            child: value(future ? '—' : '${set.reps}', muted: future),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              completed
                  ? Icons.check_circle_rounded
                  : active
                  ? Icons.edit_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: completed || active
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _RestTimer extends StatelessWidget {
  const _RestTimer({
    required this.remaining,
    required this.total,
    required this.onExtend,
    required this.onSkip,
  });

  final int remaining;
  final int total;
  final VoidCallback onExtend;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final progress = total == 0 ? 0.0 : remaining / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REST / ${_clock(total)}',
                      style: text.labelCaps.copyWith(
                        fontSize: 10,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _clock(remaining),
                      style: text.dataMetric.copyWith(
                        fontSize: 32,
                        height: 1,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onExtend,
                child: Container(
                  width: 60,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+30s',
                    style: text.annotation.copyWith(
                      fontSize: 12,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: onSkip,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Text(
                      'Skip',
                      style: text.annotation.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 3,
              backgroundColor: scheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  static String _clock(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _NextSetEntry extends StatelessWidget {
  const _NextSetEntry({
    required this.workoutId,
    required this.logIndex,
    required this.setIndex,
    required this.set,
  });

  final String workoutId;
  final int logIndex;
  final int setIndex;
  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final provider = context.read<WorkoutProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'LOG SET ${(setIndex + 1).toString().padLeft(2, '0')}',
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Stepper(
                label: 'WEIGHT / KG',
                value: _trim(set.weightKg),
                onMinus: () => provider.updateSet(
                  workoutId,
                  logIndex,
                  setIndex,
                  weightKg: (set.weightKg - 2.5).clamp(0, 1000),
                ),
                onPlus: () => provider.updateSet(
                  workoutId,
                  logIndex,
                  setIndex,
                  weightKg: (set.weightKg + 2.5).clamp(0, 1000),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stepper(
                label: 'REPETITIONS',
                value: '${set.reps}',
                onMinus: () => provider.updateSet(
                  workoutId,
                  logIndex,
                  setIndex,
                  reps: (set.reps - 1).clamp(1, 100),
                ),
                onPlus: () => provider.updateSet(
                  workoutId,
                  logIndex,
                  setIndex,
                  reps: (set.reps + 1).clamp(1, 100),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              _StepButton(icon: Icons.remove_rounded, onTap: onMinus),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: text.dataMetric.copyWith(
                      fontSize: 40,
                      height: 1,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: onPlus),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 44,
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _LoggingAction extends StatelessWidget {
  const _LoggingAction({
    required this.workout,
    required this.logIndex,
    required this.activeSet,
    required this.allDone,
    required this.onLogged,
  });

  final Workout workout;
  final int logIndex;
  final int? activeSet;
  final bool allDone;
  final ValueChanged<int> onLogged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final provider = context.read<WorkoutProvider>();
    final log = workout.logs[logIndex.clamp(0, workout.logs.length - 1)];
    final noSets = log.sets.isEmpty;

    final label = allDone
        ? 'Finish workout'
        : noSets
        ? 'Add set'
        : 'Log set ${(activeSet! + 1).toString().padLeft(2, '0')}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () {
              if (allDone) {
                Navigator.of(context)
                    .pushNamed(WorkoutSummaryScreen.routeFor(workout.id));
                return;
              }
              if (noSets) {
                final previous = provider.previousSetsFor(
                  log.exercise.name,
                  before: workout.date,
                );
                provider.addSet(
                  workout.id,
                  logIndex,
                  reps: previous.isEmpty ? 8 : previous.first.reps,
                  weightKg: previous.isEmpty ? 0 : previous.first.weightKg,
                );
                return;
              }
              provider.toggleSet(workout.id, logIndex, activeSet!);
              onLogged(log.restSeconds);
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: text.labelCaps.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimary,
                  ),
                ),
                Icon(
                  allDone ? Icons.done_all_rounded : Icons.check_rounded,
                  size: 22,
                  color: scheme.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
