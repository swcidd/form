import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'progress_bar.dart';
import 'pressable.dart';
import 'stat_pill.dart';

/// A session rendered as a card.
///
/// Two densities from one widget: `dense` for the calendar timeline and
/// recent-session lists, full for the dashboard's plan of the day. They share
/// the status marker, the title treatment and the progress bar, so a
/// completed workout looks completed in both places rather than one screen
/// inventing its own checkmark.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.workout,
    this.onTap,
    this.dense = false,
    this.actions,
    this.padding,
  });

  final Workout workout;
  final VoidCallback? onTap;
  final bool dense;

  /// Buttons rendered under the body in full density. Left to the caller so
  /// this widget does not have to know which screen is showing it.
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  bool get _hasSets => workout.totalSets > 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final card = Container(
      padding: padding ?? EdgeInsets.all(dense ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _StatusChip(status: workout.status),
              const SizedBox(width: 8),
              if (workout.startTime.isNotEmpty)
                Expanded(
                  child: Text(
                    workout.startTime,
                    style: textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              if (!dense && workout.estimatedKcal > 0)
                Text(
                  '${workout.estimatedKcal} KCAL',
                  style: context.text.labelCaps,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            workout.title,
            style: dense
                ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
                : textTheme.headlineSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (workout.place.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              workout.place,
              style: textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (workout.targetMuscleGroups.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final group in workout.targetMuscleGroups)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: AppRadius.tag,
                    ),
                    child: Text(
                      group.toUpperCase(),
                      style: context.text.labelCaps,
                    ),
                  ),
              ],
            ),
          ],
          if (!dense) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                StatPill(
                  value: '${workout.durationMin}',
                  label: 'MIN',
                  icon: Icons.timer_outlined,
                ),
                StatPill(
                  value: '${workout.totalSets}',
                  label: workout.totalSets == 1 ? 'SET' : 'SETS',
                  icon: Icons.fitness_center_outlined,
                ),
                if (_hasSets)
                  StatPill(value: '${workout.setsRemaining}', label: 'LEFT'),
              ],
            ),
          ],
          if (_hasSets) ...[
            const SizedBox(height: 12),
            ProgressBar(value: workout.progress, height: dense ? 3 : 4),
            const SizedBox(height: 6),
            Text(
              '${workout.completedSets}/${workout.totalSets} SETS DONE',
              style: textTheme.labelSmall,
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(children: actions!),
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}

/// Status marker shared by the card and the calendar cell.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final WorkoutStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (label, icon, background, foreground) = switch (status) {
      WorkoutStatus.completed => (
        'DONE',
        Icons.check_rounded,
        scheme.primary,
        scheme.onPrimary,
      ),
      WorkoutStatus.planned => (
        'PLANNED',
        Icons.schedule_rounded,
        scheme.surfaceContainerHigh,
        scheme.onSurface,
      ),
      WorkoutStatus.rest => (
        'REST',
        Icons.self_improvement_rounded,
        scheme.surfaceContainer,
        scheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.tag),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
