import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/session_stats.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';

/// Strength and history, counted from the sessions on the device.
///
/// The screen follows the Figma "Progress · Strength and history" frame: a
/// period selector, one exercise's estimated 1RM trend, the training totals
/// behind it, and the sessions those totals came from. Every number is read
/// from [SessionStats], so a plan that was never finished cannot move it.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  static const String routeName = '/progress';

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const List<_Period> _periods = [
    _Period('4 weeks', 28),
    _Period('12 weeks', 84),
    _Period('All time', null),
  ];

  int _periodIndex = 0;
  String? _exercise;
  bool _showAllHistory = false;

  int? get _days => _periods[_periodIndex].days;

  void _selectExercise(List<String> exercises) {
    if (exercises.isEmpty) return;
    if (_exercise != null && exercises.contains(_exercise)) return;
    _exercise = exercises.first;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final stats = SessionStats(provider.workouts, today: provider.today);
    final records = stats.records;
    final exercises = [for (final record in records) record.exercise];
    _selectExercise(exercises);

    final sessions = stats.recentSessions(
      days: _days,
      limit: _showAllHistory ? null : 3,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(bottom: false, child: SizedBox(height: 8)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
              child: _Header(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PeriodSelector(
                    periods: _periods,
                    selected: _periodIndex,
                    onSelected: (index) => setState(() {
                      _periodIndex = index;
                      _showAllHistory = false;
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (records.isEmpty)
                    const _EmptyProgress()
                  else ...[
                    _StrengthCard(
                      exercise: _exercise!,
                      exercises: exercises,
                      series: stats.bestSeriesFor(_exercise!, days: _days),
                      days: _days,
                      onExerciseChanged: (value) =>
                          setState(() => _exercise = value),
                    ),
                    const SizedBox(height: 18),
                    _TrainingTotals(
                      sessions: stats.sessionsIn(_days ?? 100000),
                      volumeKg: _days == null
                          ? stats.volumeKg
                          : stats.volumeIn(_days!),
                      records: stats.recordCountIn(_days),
                    ),
                    const SizedBox(height: 20),
                    if (sessions.isEmpty)
                      _NoSessions(period: _periods[_periodIndex].label)
                    else
                      _SessionHistory(
                        sessions: sessions,
                        stats: stats,
                        expanded: _showAllHistory,
                        hasMore:
                            !_showAllHistory &&
                            stats.recentSessions(days: _days).length > 3,
                        onToggle: () =>
                            setState(() => _showAllHistory = !_showAllHistory),
                      ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR PROGRESS',
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 5),
        Text(
          'PROOF OF THE WORK.',
          style: text.programName.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}

class _Period {
  const _Period(this.label, this.days);

  final String label;
  final int? days;
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.onSelected,
  });

  final List<_Period> periods;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (var index = 0; index < periods.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: Container(
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == selected
                        ? scheme.surfaceContainerLowest
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    periods[index].label,
                    style: text.annotation.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: index == selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
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

class _StrengthCard extends StatelessWidget {
  const _StrengthCard({
    required this.exercise,
    required this.exercises,
    required this.series,
    required this.days,
    required this.onExerciseChanged,
  });

  final String exercise;
  final List<String> exercises;
  final List<SetRecord> series;
  final int? days;
  final ValueChanged<String> onExerciseChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    final latest = series.isEmpty ? null : series.last.estimatedOneRepMax;
    final first = series.isEmpty ? null : series.first.estimatedOneRepMax;
    final change =
        series.length < 2 || latest == null || first == null || first <= 0
        ? null
        : (latest - first) / first * 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: exercises.length <= 1 ? null : () => _pickExercise(context),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise,
                      style: text.exerciseMeta.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED 1-REP MAX',
                      style: text.labelCaps.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          latest == null ? '—' : latest.toStringAsFixed(0),
                          style: text.dataLarge.copyWith(
                            fontSize: 62,
                            height: 0.9,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'kg',
                          style: text.exerciseMeta.copyWith(
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
                      '${change >= 0 ? '+' : ''}'
                      '${change.toStringAsFixed(1)}% '
                      '${change >= 0 ? '↗' : '↘'}',
                      style: text.exerciseMeta.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: change >= 0
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days == null ? 'all time' : 'last ${days! ~/ 4} weeks',
                      style: text.annotation.copyWith(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 129,
            child: series.isEmpty
                ? Center(
                    child: Text(
                      'No completed sets for this exercise yet.',
                      style: text.annotation.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _StrengthChartPainter(
                      series: series,
                      grid: scheme.outlineVariant,
                      line: scheme.primary,
                      area: scheme.primary.withValues(alpha: 0.14),
                      label: scheme.onSurfaceVariant,
                      textStyle: text.annotation.copyWith(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExercise(BuildContext context) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final name in exercises)
                ListTile(
                  title: Text(
                    itemOrNull(name),
                    style: context.text.exerciseMeta,
                  ),
                  trailing: name == exercise
                      ? Icon(Icons.check_rounded, color: scheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(name),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null) onExerciseChanged(chosen);
  }

  String itemOrNull(String value) => value;
}

class _StrengthChartPainter extends CustomPainter {
  _StrengthChartPainter({
    required this.series,
    required this.grid,
    required this.line,
    required this.area,
    required this.label,
    required this.textStyle,
  });

  final List<SetRecord> series;
  final Color grid;
  final Color line;
  final Color area;
  final Color label;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left;

    final values = [for (final point in series) point.estimatedOneRepMax];
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if ((maxValue - minValue).abs() < 1) {
      minValue -= 2;
      maxValue += 2;
    } else {
      final padding = (maxValue - minValue) * 0.15;
      minValue -= padding;
      maxValue += padding;
    }

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      final y = top + chartHeight * index / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      final value = maxValue - (maxValue - minValue) * index / 2;
      final painter = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(0), style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = series.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * index / (series.length - 1);
      final normalised = (values[index] - minValue) / (maxValue - minValue);
      final y = top + chartHeight * (1 - normalised);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, top + chartHeight)
      ..lineTo(points.first.dx, top + chartHeight)
      ..close();
    canvas.drawPath(areaPath, Paint()..color = area);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 4, Paint()..color = line);

    // Four date ticks across the window, or one label per point when there
    // are fewer points than ticks.
    final tickCount = math.min(4, series.length);
    for (var index = 0; index < tickCount; index++) {
      final pointIndex = tickCount == 1
          ? 0
          : (series.length - 1) * index ~/ (tickCount - 1);
      final point = series[pointIndex];
      final text = DateFormat('MMM d').format(point.date).toUpperCase();
      final painter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final x = tickCount == 1
          ? left + chartWidth / 2 - painter.width / 2
          : (left +
                    chartWidth *
                        (points[pointIndex].dx - left).clamp(0, chartWidth) /
                        chartWidth) -
                painter.width / 2;
      painter.paint(
        canvas,
        Offset(
          x.clamp(0, math.max(0, size.width - painter.width)),
          size.height - bottom + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_StrengthChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.line != line ||
      oldDelegate.grid != grid;
}

class _TrainingTotals extends StatelessWidget {
  const _TrainingTotals({
    required this.sessions,
    required this.volumeKg,
    required this.records,
  });

  final int sessions;
  final double volumeKg;
  final int records;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Total(value: '$sessions', label: 'SESSIONS'),
        const SizedBox(width: 12),
        _Total(value: _compact(volumeKg), label: 'KG LIFTED'),
        const SizedBox(width: 12),
        _Total(value: '$records', label: 'NEW RECORDS'),
      ],
    );
  }

  static String _compact(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: text.dataMetric.copyWith(
              fontSize: 32,
              height: 1,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SessionHistory extends StatelessWidget {
  const _SessionHistory({
    required this.sessions,
    required this.stats,
    required this.expanded,
    required this.hasMore,
    required this.onToggle,
  });

  final List<Workout> sessions;
  final SessionStats stats;
  final bool expanded;
  final bool hasMore;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final month = sessions.isEmpty
        ? 'HISTORY'
        : '${DateFormat('MMMM').format(sessions.first.date).toUpperCase()} '
              'HISTORY';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              month,
              style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
            ),
            const Spacer(),
            if (hasMore || expanded)
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  expanded ? 'Show less' : 'View all',
                  style: text.annotation.copyWith(
                    fontSize: 11,
                    color: scheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        for (final workout in sessions)
          _HistoryRow(workout: workout, stats: stats),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.workout, required this.stats});

  final Workout workout;
  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final volume = workout.logs.fold<double>(0, (sum, log) => sum + log.volume);
    final hasRecord = stats.records.any(
      (record) =>
          record.date.year == workout.date.year &&
          record.date.month == workout.date.month &&
          record.date.day == workout.date.day,
    );
    final parts = [
      if (workout.durationMin > 0) '${workout.durationMin} min',
      '${_compactKg(volume)} kg',
      '${workout.totalSets} sets',
    ];

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(workout.date),
                  style: text.dataMetric.copyWith(
                    fontSize: 26,
                    height: 1,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  DateFormat('EEE').format(workout.date).toUpperCase(),
                  style: text.annotation.copyWith(
                    fontSize: 9,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 32, color: scheme.outlineVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  workout.title,
                  style: text.exerciseMeta.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  parts.join('  ·  '),
                  style: text.annotation.copyWith(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasRecord)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 14,
                color: scheme.onPrimary,
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

  static String _compactKg(double value) {
    if (value >= 1000) return (value / 1000).toStringAsFixed(1);
    return value.toStringAsFixed(0);
  }
}

class _NoSessions extends StatelessWidget {
  const _NoSessions({required this.period});

  final String period;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No finished sessions in $period yet.',
        style: text.exerciseMeta.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 40,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'NO PROGRESS TO SHOW YET.',
            style: text.programName.copyWith(color: scheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Finish a session and the proof starts here.',
            style: text.exerciseMeta.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
