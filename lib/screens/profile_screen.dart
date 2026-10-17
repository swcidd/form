import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/profile_stats.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/progress_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';

/// The account's own history, and the one setting the rest of the app reads
/// back.
///
/// Every figure on this screen is counted off the sessions the user actually
/// logged rather than read from the stored totals on [ProfileStats]. Those
/// fields exist, but nothing keeps them up to date, so a screen quoting them
/// would show a history that stopped being true the moment a set was ticked -
/// and a brand new account would still show the numbers it was seeded with.
/// Counting here means the profile and the dashboard cannot disagree, and an
/// empty account reads as empty.
///
/// Personal records and achievements remain the stored fields: they are facts
/// about what has been earned, not totals something can recount from the
/// sessions still on the device.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final profile = provider.profile;

    final finished = provider.workouts
        .where((workout) => workout.status == WorkoutStatus.completed)
        .toList();

    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Text('Profile', style: context.text.dataHero),
          const SizedBox(height: 20),
          _identity(context, profile),
          const SizedBox(height: 28),
          const SectionHeader(label: 'Training'),
          const SizedBox(height: 12),
          _training(provider, finished),
          const SizedBox(height: 28),
          const SectionHeader(label: 'Weekly target'),
          const SizedBox(height: 12),
          _weeklyTarget(context, provider),
          const SizedBox(height: 28),
          const SectionHeader(label: 'Body'),
          const SizedBox(height: 12),
          _body(profile),
          const SizedBox(height: 28),
          const SectionHeader(label: 'Personal records'),
          const SizedBox(height: 12),
          _records(profile),
          const SizedBox(height: 28),
          const SectionHeader(label: 'Achievements'),
          const SizedBox(height: 12),
          _achievements(context, profile),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ identity

  Widget _identity(BuildContext context, ProfileStats profile) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final named = profile.name.trim().isNotEmpty;
    final subtitle = [
      profile.handle,
      profile.role,
      if (profile.memberSince.trim().isNotEmpty) 'Since ${profile.memberSince}',
    ].where((part) => part.trim().isNotEmpty).join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Image.asset(
            'assets/images/profile_avatar.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Icon(Icons.person_outline, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                named ? profile.name : 'No name yet',
                style: text.exerciseName.copyWith(fontSize: 26),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle.isEmpty
                    ? 'Your training stays on this device.'
                    : subtitle,
                style: text.exerciseMeta,
              ),
            ],
          ),
        ),
        if (profile.isPro)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'PRO',
              style: text.labelCaps.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ training

  Widget _training(WorkoutProvider provider, List<Workout> finished) {
    final volumeKg = finished.fold<double>(
      0,
      (sum, workout) => sum + _volumeOf(workout),
    );
    final minutes = finished.fold<int>(
      0,
      (sum, workout) => sum + workout.durationMin,
    );

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatTile(
                value: '${finished.length}',
                label: 'Sessions',
                icon: Icons.fitness_center,
                caption: provider.completedThisMonth == 0
                    ? 'none finished this month'
                    : '${provider.completedThisMonth} this month',
                emphasis: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: '${provider.streakDays}',
                label: 'Streak (days)',
                icon: Icons.local_fire_department_outlined,
                caption: provider.streakDays == 0
                    ? 'finish a session to start one'
                    : 'in a row',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatTile(
                value: _thousands(volumeKg.round()),
                label: 'Volume lifted (kg)',
                icon: Icons.monitor_weight_outlined,
                caption: 'completed sets only',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: _hours(minutes),
                label: 'Time trained',
                icon: Icons.timer_outlined,
                caption: 'in finished sessions',
              ),
            ),
          ],
        ),
        if (finished.isEmpty) ...[
          const SizedBox(height: 12),
          _EmptyNote(
            text:
                'Nothing logged yet. Your totals start with the first session '
                'you finish.',
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------- weekly target

  Widget _weeklyTarget(BuildContext context, WorkoutProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final goal = provider.weeklyGoal;
    final done = provider.workoutsThisWeek;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sessions per week', style: text.labelCaps),
                    const SizedBox(height: 4),
                    Text('$done of $goal this week', style: text.exerciseMeta),
                  ],
                ),
              ),
              _StepButton(
                icon: Icons.remove,
                tooltip: 'Fewer sessions per week',
                onPressed: goal > WorkoutProvider.weeklyGoalMin
                    ? () => provider.setWeeklyGoal(goal - 1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('$goal', style: text.metric),
              ),
              _StepButton(
                icon: Icons.add,
                tooltip: 'More sessions per week',
                onPressed: goal < WorkoutProvider.weeklyGoalMax
                    ? () => provider.setWeeklyGoal(goal + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(value: goal == 0 ? 0 : done / goal),
          const SizedBox(height: 8),
          Text(
            'The dashboard counts the same sessions against this target.',
            style: text.annotation,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------- body

  Widget _body(ProfileStats profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: _decimal(profile.weightKg, 1),
                label: 'Weight (kg)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: _decimal(profile.heightCm, 0),
                label: 'Height (cm)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                value: _decimal(profile.bodyFatPct, 1),
                label: 'Body fat (%)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: _decimal(profile.restingHrBpm, 0),
                label: 'Resting HR (bpm)',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------- records and badges

  Widget _records(ProfileStats profile) {
    if (profile.records.isEmpty) {
      return const _EmptyNote(
        text:
            'No personal records yet. They are written here as you lift '
            'heavier than you have before.',
      );
    }

    return Column(
      children: [
        for (final record in profile.records) ...[
          _RecordRow(record: record),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _achievements(BuildContext context, ProfileStats profile) {
    if (profile.achievements.isEmpty) {
      return const _EmptyNote(
        text: 'No badges yet. They arrive a session at a time.',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final achievement in profile.achievements)
          Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: text.exerciseName),
                const SizedBox(height: 2),
                Text(achievement.subtitle, style: text.annotation),
                const SizedBox(height: 6),
                Text(achievement.detail, style: text.labelCaps),
              ],
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ helpers

  /// Work done in the sets actually completed, so a plan that was never
  /// finished does not add to the total while it sits on the calendar.
  static double _volumeOf(Workout workout) =>
      workout.logs.fold(0.0, (sum, log) => sum + log.volume);

  /// "1,240" rather than "1240" - four and five digit totals are unreadable
  /// without a separator at this size.
  static String _thousands(int value) => NumberFormat('#,##0').format(value);

  static String _hours(int minutes) {
    if (minutes == 0) return '0h';
    final hours = minutes / 60;
    return hours < 10 ? '${hours.toStringAsFixed(1)}h' : '${hours.round()}h';
  }

  /// Figures the profile has never been given render as a dash. A stored zero
  /// is "not set", not "weighs nothing", and printing "0 kg" would state a
  /// fact the app has not been told.
  static String _decimal(num value, int places) =>
      value == 0 ? '—' : value.toStringAsFixed(places);
}

/// One step of the weekly target, disabled at the ends of the accepted range.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// A record row: the badge, the lift, the protocol it was set under, and the
/// number itself on the right.
class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.id,
              style: text.labelCaps.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.name, style: text.exerciseName),
                Text(record.protocol, style: text.annotation),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${record.value} ${record.unit}', style: text.setValue),
        ],
      ),
    );
  }
}

/// Says what is missing and why, in the space a list would have taken.
///
/// Deliberately not an [EmptyState]: these sit inside a scrolling column of
/// real sections, where a full-height centred block would read as the screen
/// having failed rather than one section having nothing in it yet.
class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: context.text.exerciseMeta.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
