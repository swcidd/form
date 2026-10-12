import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../exercise_library.dart';

/// Library screen: search, filters, current program, workout lists, + exercise catalog.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  static const String routeName = '/library';

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<LibraryExercise>> _exercisesFuture;
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    _exercisesFuture = ExerciseLibrary.loadAll();
  }

  // --------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

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
                  _ExerciseFilterChips(
                    selected: _selectedTab,
                    onSelected: (tab) {
                      setState(() => _selectedTab = tab);
                    },
                  ),
                  const SizedBox(height: 16),
                  _ExerciseGrid(filter: _selectedTab),
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

  // --------------------------------------------------------------- status bar
  Widget _StatusBar() {
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

  // --------------------------------------------------------------- page header
  Widget _PageHeader() {
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

  // --------------------------------------------------------------- search bar
  Widget _SearchBar() {
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

  // --------------------------------------------------------------- exercise filter chips
  Widget _ExerciseFilterChips({
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;

    const chips = ['All', 'Strength', 'Stretching', 'Strongman'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((label) {
          final isSelected = label == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? scheme.surface : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.lime,
              onSelected: (bool selected) => onSelected(label),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------------------- exercise grid
  Widget _ExerciseGrid({required String filter}) {
    return FutureBuilder<List<LibraryExercise>>(
      future: ExerciseLibrary.loadAll(),
      builder: (context, snapshot) {
        final exercises = snapshot.data ?? const [];
        final filtered = _applyFilter(exercises, filter);

        if (filtered.isEmpty) {
          return const Center(child: Text('No exercises found.'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final ex = filtered[index];
            return _ExerciseCard(exercise: ex);
          },
        );
      },
    );
  }

  List<LibraryExercise> _applyFilter(
    List<LibraryExercise> exercises,
    String filter,
  ) {
    if (filter == 'All') return exercises;
    return exercises
        .where(
          (ex) =>
              ex.primaryMuscle.toLowerCase().contains(filter.toLowerCase()) ||
              (ex.secondaryMuscle?.toLowerCase().contains(
                    filter.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  // --------------------------------------------------------------- exercise card
  Widget _ExerciseCard({required LibraryExercise exercise}) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / icon placeholder
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: exercise.images.isNotEmpty
                ? Image.asset(
                    exercise.images.first,
                    width: double.infinity,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.fitness_center, size: 30),
                  )
                : Icon(
                    Icons.fitness_center,
                    size: 30,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            exercise.primaryMuscle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (exercise.tips != null) ...[
            const SizedBox(height: 4),
            Text(
              exercise.tips!,
              style: Theme.of(context).textTheme.bodyExtraSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise.level,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.lime),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: () {},
                tooltip: 'Save workout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- current program card
  Widget _CurrentProgramCard() {
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
                colors: [Color(0x00121512), Color(0x73121512)],
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

  // --------------------------------------------------------------- section header
  Widget _SectionHeader({required String label}) {
    final text = context.text;
    return Text(label, style: text.labelCaps);
  }

  // --------------------------------------------------------------- my workouts list
  Widget _WorkoutList() {
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
