import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/session_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'sparkline_chart.dart';

/// The estimated-1RM trend for one exercise over the last four weeks.
///
/// The card owns which exercise is shown. The data is rebuilt from the session
/// log on every build, so a selection that no longer exists falls back to the
/// strongest current lift instead of showing a stale series.
class OneRepMaxCard extends StatefulWidget {
  const OneRepMaxCard({super.key, required this.trends});

  final List<ExerciseOneRepMaxTrend> trends;

  @override
  State<OneRepMaxCard> createState() => _OneRepMaxCardState();
}

class _OneRepMaxCardState extends State<OneRepMaxCard> {
  String? _selected;

  @override
  void didUpdateWidget(OneRepMaxCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.trends.any((trend) => trend.exercise == _selected)) {
      _selected = null;
    }
  }

  ExerciseOneRepMaxTrend? get _trend {
    if (widget.trends.isEmpty) return null;
    for (final trend in widget.trends) {
      if (trend.exercise == _selected) return trend;
    }
    return widget.trends.first;
  }

  @override
  Widget build(BuildContext context) {
    final trend = _trend;
    if (trend == null) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? AppColors.inkMuted : AppColors.ink;
    final border = dark ? AppColors.inkSubtle : AppColors.ink;
    const muted = AppColors.sage300;
    final text = context.text;
    final latest = trend.latest ?? 0;
    final change = trend.changePercent;
    final changeColor = change == null || change == 0
        ? muted
        : change > 0
        ? AppColors.lime
        : AppColors.rust;
    final direction = change == null || change == 0
        ? ''
        : ', ${change > 0 ? 'up' : 'down'} '
              '${change.abs().toStringAsFixed(1)} percent over the last '
              'four weeks';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Choose exercise',
            onSelected: (exercise) => setState(() => _selected = exercise),
            itemBuilder: (context) => [
              for (final option in widget.trends)
                PopupMenuItem(
                  value: option.exercise,
                  child: Text(option.exercise),
                ),
            ],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    trend.exercise,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.cream,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.sage300,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ESTIMATED 1-REP MAX',
            style: text.labelCaps.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest.round().toString(),
                style: text.dataLarge.copyWith(color: AppColors.cream),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'kg',
                  style: text.exerciseMeta.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (change != null)
            Row(
              children: [
                Text(
                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: text.dataChange.copyWith(color: changeColor),
                ),
                if (change != 0) ...[
                  const SizedBox(width: 4),
                  Icon(
                    change > 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 18,
                    color: changeColor,
                  ),
                ],
                const SizedBox(width: 10),
                Text(
                  'last 4 weeks',
                  style: text.annotation.copyWith(color: muted),
                ),
              ],
            )
          else
            Text(
              'Not enough history yet',
              style: text.annotation.copyWith(color: muted),
            ),
          const SizedBox(height: 10),
          SparklineChart(
            values: [for (final week in trend.weeks) week.estimatedOneRepMax],
            color: AppColors.lime,
            semanticLabel:
                'Estimated one rep max for ${trend.exercise}: '
                '${latest.round()} kilograms$direction.',
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var index = 0; index < trend.weeks.length; index++)
                Expanded(
                  child: Text(
                    DateFormat('MMM dd')
                        .format(trend.weeks[index].weekStart)
                        .toUpperCase(),
                    textAlign: index == 0
                        ? TextAlign.start
                        : index == trend.weeks.length - 1
                        ? TextAlign.end
                        : TextAlign.center,
                    style: text.annotation.copyWith(color: muted, fontSize: 9),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
