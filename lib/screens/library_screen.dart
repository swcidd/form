import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../exercise_library.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Library screen: search, filters, current program, workout lists, + exercise catalog.
///
/// The catalogue is network-first (the wger REST API) with the bundled data
/// sets as the offline fallback; [catalog] exists so tests can drive both
/// paths without touching the network.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.catalog});

  static const String routeName = '/library';

  /// The catalogue loader; the real one by default.
  final ExerciseCatalog? catalog;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ExerciseCatalog _catalog = widget.catalog ?? ExerciseCatalog();
  late Future<ExerciseCatalogResult> _exercisesFuture;
  String _selectedTab = 'All';

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _catalog.load();
  }

  /// Re-runs the network-first load. The offline banner and the error state
  /// both offer this rather than asking the user to leave and come back.
  void _reload() {
    // Not an arrow body: setState asserts when its callback returns the
    // Future it was handed rather than storing it.
    setState(() {
      _exercisesFuture = _catalog.load();
    });
  }

  // --------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        slivers: [
          // Top inset only — the OS draws the phone's status bar, not the app.
          SliverToBoxAdapter(
            child: SafeArea(bottom: false, child: SizedBox(height: 8)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.pageHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pageHeader(),
                  const SizedBox(height: 24),
                  _searchBar(),
                  const SizedBox(height: 16),
                  _exerciseFilterChips(
                    selected: _selectedTab,
                    onSelected: (tab) {
                      setState(() => _selectedTab = tab);
                    },
                  ),
                  const SizedBox(height: 16),
                  _exerciseGrid(future: _exercisesFuture, filter: _selectedTab),
                  const SizedBox(height: 24),
                  _currentProgramCard(),
                  const SizedBox(height: 24),
                  _sectionHeader(label: 'My Workouts'),
                  const SizedBox(height: 12),
                  _workoutList(),
                  const SizedBox(height: 24),
                  _sectionHeader(label: 'Saved'),
                  const SizedBox(height: 12),
                  _SavedList(),
                  const SizedBox(height: 24),
                  _attribution(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- page header
  Widget _pageHeader() {
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
  Widget _searchBar() {
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
                hintStyle: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
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
  Widget _exerciseFilterChips({
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
  Widget _exerciseGrid({
    required Future<ExerciseCatalogResult> future,
    required String filter,
  }) {
    return FutureBuilder<ExerciseCatalogResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return _catalogError();
        }

        final result = snapshot.data;
        final filtered = _applyFilter(result?.exercises ?? const [], filter);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result?.isOffline ?? false) ...[
              _offlineBanner(),
              const SizedBox(height: 12),
            ],
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No exercises found.')),
              )
            else
              GridView.builder(
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
                  return _exerciseCard(exercise: filtered[index]);
                },
              ),
          ],
        );
      },
    );
  }

  List<LibraryExercise> _applyFilter(
    List<LibraryExercise> exercises,
    String filter,
  ) {
    if (filter == 'All') return exercises;
    // The chips name categories ("Strength"), so match on the category and
    // keep a muscle fallback for names that read like muscle groups.
    final needle = filter.toLowerCase();
    return exercises
        .where(
          (ex) =>
              ex.category.toLowerCase() == needle ||
              ex.primaryMuscle.toLowerCase().contains(needle),
        )
        .toList();
  }

  // --------------------------------------------------------------- exercise card
  Widget _exerciseCard({required LibraryExercise exercise}) {
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
                    errorBuilder: (_, _, _) =>
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
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (exercise.tips != null) ...[
            const SizedBox(height: 4),
            Text(
              exercise.tips!,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10),
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
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.lime),
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

  /// The offline notice: the grid is real either way, so this states where
  /// it came from instead of pretending the request made it.
  Widget _offlineBanner() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.sage50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Offline catalogue — wger.de couldn't be reached.",
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: _reload, child: const Text('Retry')),
        ],
      ),
    );
  }

  /// Only total failure reaches this: both wger and the bundled assets are
  /// gone, which is worth an explicit retry rather than an empty page.
  Widget _catalogError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'Could not load the exercise library.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _reload, child: const Text('Retry')),
        ],
      ),
    );
  }

  /// wger and exercemus are CC BY-SA and ask for attribution; free-exercise-db
  /// is public domain. One line covers every set the grid can show.
  Widget _attribution() {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      'Exercise data: wger.de (CC BY-SA) · exercemus (CC BY-SA) · '
      'free-exercise-db (public domain).',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10),
    );
  }

  // --------------------------------------------------------------- current program card
  Widget _currentProgramCard() {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 188,
      child: Stack(
        children: [
          // Background photograph
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/program_hero.png',
              height: 188,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
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
                          style: text.programMeta.copyWith(
                            color: scheme.surface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '50%',
                          style: text.programMeta.copyWith(
                            color: AppColors.lime,
                          ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.lime,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- section header
  Widget _sectionHeader({required String label}) {
    final text = context.text;
    return Text(label, style: text.labelCaps);
  }

  // --------------------------------------------------------------- my workouts list
  Widget _workoutList() {
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
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
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
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
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
