import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/auth_messages.dart';
import '../models/profile_stats.dart';
import '../models/workout.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/edit_body_sheet.dart';
import '../widgets/progress_bar.dart';
import '../widgets/pressable.dart';
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
          SectionHeader(
            label: 'Body',
            actionLabel: 'Edit',
            onAction: () => showEditBodySheet(context),
          ),
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
          const SizedBox(height: 28),
          const SectionHeader(label: 'Account'),
          const SizedBox(height: 12),
          _account(context),
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
    final done = provider.sessionsDoneThisWeek;

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
                value: profile.age == 0 ? '—' : '${profile.age}',
                label: 'Age',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                value: _decimal(profile.bodyFatPct, 1),
                label: 'Body fat (%)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
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

  // ------------------------------------------------------------------ account

  /// Who is signed in, and the two ways out of it.
  ///
  /// A section of its own rather than a control in the corner, because the
  /// device account has to be able to say what it is: somebody who never made an
  /// account should be able to find out that they never made one, and that their
  /// training is on this device and nowhere else.
  ///
  /// Signing out asks nothing, because nothing is lost by it and the way back in
  /// is the welcome screen. Deleting asks once, and says what goes.
  Widget _account(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final auth = context.watch<AuthProvider>();
    final session = auth.session;
    final busy = auth.busy;

    final guest = session == null || session.isGuest;
    final email = session?.email?.trim() ?? '';
    final name = session?.displayName?.trim() ?? '';

    final title = guest
        ? 'Offline account'
        : (name.isNotEmpty
              ? name
              : (email.isNotEmpty ? email : 'Your account'));
    final detail = guest
        ? 'No email, no password: this device is the account.'
        : (name.isNotEmpty && email.isNotEmpty ? email : 'Signed in');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              children: [
                Icon(
                  guest ? Icons.phonelink_lock_outlined : Icons.person_outline,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.exerciseMeta.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: text.annotation.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          if (!guest) ...[
            _AccountAction(
              icon: Icons.lock_reset,
              label: 'Change password',
              onPressed: busy ? null : () => showChangePasswordSheet(context),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
          ],
          _AccountAction(
            icon: Icons.logout,
            label: 'Sign out',
            onPressed: busy ? null : () => _signOut(context, auth),
          ),
          if (!guest) ...[
            Divider(height: 1, color: scheme.outlineVariant),
            _AccountAction(
              icon: Icons.delete_outline,
              label: 'Delete account',
              destructive: true,
              onPressed: busy ? null : () => _confirmDelete(context, auth),
            ),
          ],
        ],
      ),
    );
  }

  /// Ends the session. Nothing is deleted, so nothing needs confirming.
  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signOut();
      // The gate swaps the window and this screen goes with it, so there is
      // nothing to say afterwards and nowhere on this screen to say it.
    } catch (error) {
      debugPrint('Could not sign out: $error');
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AuthMessages.unexpected)),
      );
    }
  }

  /// Asks once more, and names what is about to go.
  ///
  /// Counted off the store rather than described in general terms: "delete your
  /// account" invites the question of what that includes, and the app knows the
  /// answer to the session and the exercise.
  Future<void> _confirmDelete(BuildContext context, AuthProvider auth) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<WorkoutProvider>();

    final going = _and([
      if (provider.workouts.isNotEmpty)
        _count(provider.workouts.length, 'session'),
      'your profile',
      if (provider.savedExercises.isNotEmpty)
        _count(provider.savedExercises.length, 'saved exercise'),
    ]);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) {
        final scheme = Theme.of(dialog).colorScheme;
        return AlertDialog(
          title: const Text('Delete this account?'),
          content: Text(
            'This removes $going from this device, and cannot be undone. There '
            'is no copy anywhere else: the app has no server to keep one on.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: const Text('Keep my account'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await auth.deleteAccount();
    } catch (error) {
      debugPrint('Could not delete the account: $error');
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AuthMessages.unexpected)),
      );
    }
  }

  /// "12 sessions", "1 session" — one place, so the sentence cannot disagree
  /// with itself about the plural.
  static String _count(int count, String noun) =>
      count == 1 ? '1 $noun' : '$count ${noun}s';

  /// "a, b and c", so a list inside a sentence reads as one.
  static String _and(List<String> parts) {
    if (parts.length <= 1) return parts.join();
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }
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

/// One row inside the account card: an icon, a label, and the chevron that says
/// it does something.
///
/// A [ListTile] would bring its own padding, tap target and idea of how big a
/// leading icon is, and this has to sit inside a bordered card whose dividers
/// run the full width.
class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;

  /// Null while the account is busy, which is also what greys the row out.
  final VoidCallback? onPressed;

  /// Paints it in the error colour, for the one row that cannot be undone.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final colour = destructive ? scheme.error : scheme.onSurface;
    final shade = enabled ? colour : scheme.onSurfaceVariant;

    return Pressable(
      onTap: onPressed,
      borderRadius: AppRadius.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: shade),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: context.text.exerciseMeta.copyWith(color: shade),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Says what is missing and why, in the space a list would have taken.///
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
