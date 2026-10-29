import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/session_stats.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';

/// Post-workout summary: what the session added up to.
///
/// The screen follows the Figma "Session · Workout summary" frame. Every figure
/// is counted from the sets the user actually ticked, and a personal record is
/// only claimed when the session's best set beat an earlier finished session.
class WorkoutSummaryScreen extends StatefulWidget {
  const WorkoutSummaryScreen({super.key, this.route});

  final RouteSettings? route;

  static String routeFor(String id) => '$routeName/$id';
  static const String routeName = '/workout-summary';

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  String? _feeling;
  String? _note;

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

    if (workout == null) {
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

    final stats = SessionStats(provider.workouts, today: provider.today);
    final topSet = stats.topSetIn(workout);
    final previous = topSet == null
        ? null
        : stats.previousBestOf(topSet.exercise, before: workout.date);
    final volume = _completedVolume(workout);
    final previousVolume = stats.lastVolumeOf(
      workout.title,
      before: workout.date,
    );
    final completedReps = workout.logs.fold<int>(
      0,
      (sum, log) =>
          sum +
          log.sets
              .where((set) => set.completed)
              .fold(0, (s, set) => s + set.reps),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: _SummaryToolbar(
                onShare: () => _share(context, workout, volume),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Headline(workout: workout),
                  const SizedBox(height: 24),
                  _Volume(volume: volume, previousVolume: previousVolume),
                  const SizedBox(height: 16),
                  Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  _Totals(
                    duration: _duration(workout.durationMin),
                    sets: workout.completedSets,
                    reps: completedReps,
                  ),
                  if (topSet != null &&
                      previous != null &&
                      topSet.estimatedOneRepMax >
                          previous.estimatedOneRepMax) ...[
                    const SizedBox(height: 24),
                    _PersonalRecordCard(record: topSet, previous: previous),
                  ],
                  const SizedBox(height: 24),
                  _Feeling(
                    selected: _feeling,
                    onSelected: (value) => setState(() => _feeling = value),
                  ),
                  const SizedBox(height: 12),
                  _NoteLine(note: _note, onTap: () => _editNote(context)),
                  const SizedBox(height: 24),
                  _SaveButton(workout: workout),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(BuildContext context) async {
    final controller = TextEditingController(text: _note);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'SESSION NOTE',
                style: context.text.labelCaps.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'How did it feel? What worked?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (value != null && mounted) {
      setState(() => _note = value.trim().isEmpty ? null : value.trim());
    }
  }

  void _share(BuildContext context, Workout workout, double volume) {
    final text =
        '${workout.title} · '
        '${DateFormat('EEE, MMM d').format(workout.date)}\n'
        '${NumberFormat.decimalPattern().format(volume)} kg · '
        '${workout.completedSets} sets · '
        '${_duration(workout.durationMin)}\n'
        'Logged in FORM.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Summary copied.')));
  }

  static double _completedVolume(Workout workout) =>
      workout.logs.fold(0.0, (total, log) => total + log.volume);

  static String _duration(int minutes) {
    if (minutes <= 0) return '—';
    return '${minutes.toString().padLeft(2, '0')}:00';
  }

  static String? _idFromPath(String? routeName) {
    if (routeName == null) return null;
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return Uri.decodeComponent(segments[1]);
  }
}

class _SummaryToolbar extends StatelessWidget {
  const _SummaryToolbar({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text(
              'SESSION COMPLETE',
              style: text.annotation.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onShare,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.share_outlined,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateFormat('EEE, MMM d').format(workout.date).toUpperCase()} / '
          '${workout.title.toUpperCase()}',
          style: text.labelCaps.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 10),
        Text(
          'WORK.\nBANKED.',
          style: text.dataHero.copyWith(
            fontSize: 48,
            height: 0.98,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You showed up. You got stronger.',
          style: text.exerciseMeta.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Volume extends StatelessWidget {
  const _Volume({required this.volume, required this.previousVolume});

  final double volume;
  final double? previousVolume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final previous = previousVolume;
    final change = previous == null || previous <= 0
        ? null
        : (volume - previous) / previous * 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL VOLUME',
                style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormat.decimalPattern().format(volume),
                    style: text.dataLarge.copyWith(
                      fontSize: 62,
                      height: 0.9,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'kg',
                    style: text.exerciseMeta.copyWith(
                      fontSize: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (change != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                style: text.exerciseMeta.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: change >= 0 ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'vs. last session',
                style: text.annotation.copyWith(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.duration,
    required this.sets,
    required this.reps,
  });

  final String duration;
  final int sets;
  final int reps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Total(label: 'DURATION', value: duration),
        _Total(label: 'SETS', value: '$sets'),
        _Total(label: 'REPS', value: '$reps'),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: text.dataMetric.copyWith(
              fontSize: 26,
              height: 1,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalRecordCard extends StatelessWidget {
  const _PersonalRecordCard({required this.record, required this.previous});

  final SetRecord record;
  final SetRecord previous;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final gain = record.weightKg - previous.weightKg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEW PERSONAL RECORD',
                style: text.labelCaps.copyWith(
                  color: scheme.onPrimary,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.emoji_events_outlined,
                size: 22,
                color: scheme.onPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.exercise,
            style: text.exerciseMeta.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'previous best · '
            '${DateFormat('MMM d').format(previous.date)}  ·  '
            '${_trim(previous.weightKg)} kg × ${previous.reps}',
            style: text.annotation.copyWith(
              fontSize: 10,
              color: scheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _trim(record.weightKg).toUpperCase(),
                      style: text.dataLarge.copyWith(
                        fontSize: 44,
                        height: 0.9,
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KG × ${record.reps}',
                      style: text.exerciseMeta.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${gain >= 0 ? '+' : ''}${_trim(gain)} kg ↗',
                style: text.exerciseMeta.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _Feeling extends StatelessWidget {
  const _Feeling({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HOW DID IT FEEL?',
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(_feelings[index]),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected == _feelings[index]
                          ? scheme.surfaceContainer
                          : scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected == _feelings[index]
                            ? scheme.outline
                            : scheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      _feelings[index],
                      style: text.annotation.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected == _feelings[index]
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  static const List<String> _feelings = ['Easy', 'Solid', 'All out'];
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({required this.note, required this.onTap});

  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.add_rounded, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                note ?? 'Add a session note',
                style: text.annotation.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: () {
          context.read<WorkoutProvider>().completeWorkout(workout.id);
          Navigator.of(context).popUntil((route) => route.isFirst);
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
              'Save & close',
              style: text.labelCaps.copyWith(
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
            Icon(Icons.check_rounded, size: 22, color: scheme.onPrimary),
          ],
        ),
      ),
    );
  }
}
