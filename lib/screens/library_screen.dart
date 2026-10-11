import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Library screen: search, filters, current program, and workout lists.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const String routeName = '/library';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          _StatusBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pageHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(),
                  const SizedBox(height: 24),
                  _SearchBar(),
                  const SizedBox(height: 16),
                  _FilterChips(),
                  const SizedBox(height: 24),
                  _CurrentProgramCard(),
                  const SizedBox(height: 24),
                  _SectionHeader(label: 'My Workouts'),
                  const SizedBox(height: 12),
                  _WorkoutList(),
                  const SizedBox(height: 24),
                  _SectionHeader(label: 'Saved'),
                  const SizedBox(height: 12),
                  _SavedList(),
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

/// iOS-style status bar.
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:41',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_4_bar_rounded,
                    size: 17,
                    color: scheme.onSurface,
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.wifi_rounded, size: 17, color: scheme.onSurface),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.battery_full_rounded,
                    size: 17,
                    color: scheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page header with title and plus button.
class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('THE TRAINING LIBRARY', style: text.labelCaps),
              const SizedBox(height: 4),
              Text('YOUR WORK. YOUR WAY.', style: text.programName),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.add_rounded, size: 22, color: scheme.onSurface),
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Search input.
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.sage50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Find a workout or exercise',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chips: My workouts (active), Discover, Saved.
class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    const filters = [
      ('My workouts', true),
      ('Discover', false),
      ('Saved', false),
    ];

    return Row(
      children: filters.map((f) {
        final isActive = f.$2;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isActive ? scheme.onSurface : scheme.surface,
              border: Border.all(
                color: isActive ? scheme.onSurface : scheme.outline,
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Text(
                f.$1,
                style: text.labelCaps.copyWith(
                  color: isActive ? scheme.surface : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Current program hero card with photograph, progress, and CTA.
class _CurrentProgramCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Stack(
      children: [
        // Background photograph
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/program_hero.png',
            height: 188,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(height: 188, color: scheme.surfaceContainerHighest),
          ),
        ),
        // Image shade
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 188,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00121512),
                  Color(0x73121512), // 45% opacity
                ],
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Row(
                children: [
                  Text(
                    'CURRENT PROGRAM',
                    style: text.labelCaps.copyWith(color: AppColors.lime),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 20,
                    color: scheme.surface,
                  ),
                ],
              ),
              const Spacer(),
              // Program name
              Text(
                'FOUNDATION / 08',
                style: text.programName.copyWith(color: scheme.surface),
              ),
              const SizedBox(height: 4),
              // Program meta
              Text(
                '8 weeks  ·  Strength  ·  4 days / week',
                style: text.programMeta.copyWith(color: scheme.surface),
              ),
              const SizedBox(height: 12),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Week 04 of 08',
                        style: text.programMeta.copyWith(color: scheme.surface),
                      ),
                      const Spacer(),
                      Text(
                        '50%',
                        style: text.programMeta.copyWith(color: AppColors.lime),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.5,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.lime),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section header with label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Text(label, style: text.labelCaps);
  }
}

/// My workouts list.
class _WorkoutList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final workouts = [
      ('Foundation / 08', 'Week 04 of 08', 'Strength', '4 days/week', true),
      (
        'Upper Body Focus',
        'Week 02 of 06',
        'Hypertrophy',
        '3 days/week',
        false,
      ),
      ('Push Pull Legs', 'Week 01 of 12', 'Strength', '6 days/week', false),
    ];

    return Column(
      children: workouts
          .map(
            (w) => _ProgramListItem(
              name: w.$1,
              progress: w.$2,
              type: w.$3,
              frequency: w.$4,
              isCurrent: w.$5,
            ),
          )
          .toList(),
    );
  }
}

class _ProgramListItem extends StatelessWidget {
  const _ProgramListItem({
    required this.name,
    required this.progress,
    required this.type,
    required this.frequency,
    required this.isCurrent,
  });

  final String name;
  final String progress;
  final String type;
  final String frequency;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppColors.lime : scheme.outlineVariant,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.sage50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 26,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isCurrent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CURRENT',
                          style: text.annotation.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$progress  ·  $type  ·  $frequency',
                  style: text.previousPerf,
                ),
              ],
            ),
          ),
          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Saved workouts list.
class _SavedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final saved = [
      'Bench Press Specialization',
      'Deadlift Accessory Circuit',
      'Core & Mobility Flow',
    ];

    return Column(children: saved.map((s) => _SavedItem(name: s)).toList());
  }
}

class _SavedItem extends StatelessWidget {
  const _SavedItem({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bookmark_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
