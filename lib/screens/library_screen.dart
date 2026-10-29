import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/exercise_catalog.dart';
import '../data/exercise_images.dart';
import '../models/library_exercise.dart';
import '../models/saved_exercise.dart';
import '../models/taxonomy.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'workout_flow.dart';
import 'exercise_detail_screen.dart';
import 'workout_detail_screen.dart';

/// Which list the library is showing.
///
/// The design puts the three behind one row of pills rather than behind routes,
/// so switching costs no navigation and the search field keeps its text.
enum LibraryTab {
  myWorkouts('My workouts'),
  discover('Discover'),
  saved('Saved');

  const LibraryTab(this.label);

  final String label;
}

/// The training library: what the user has, what they can find, and what they
/// kept.
///
/// Laid out from the Figma "Train · Workout library" frame (header, search,
/// pill row, week card, rotation) and its empty-state frame (welcome, first
/// workout, other ways to start).
///
/// Every figure on it is countedfl from the sessions in [WorkoutProvider] or
/// from the loaded catalogue. The frame it replaces carried a hardcoded
/// "FOUNDATION / 08" program at "WEEK 04 OF 08 / 50%" and lists of workouts
/// nobody had, which read as the user's own training.
///
/// The catalogue is network-first (the wger REST API) with the bundled data
/// sets as the offline fallback; [catalog] exists so tests can drive both paths
/// without touching the network.
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
  final _search = TextEditingController();

  LibraryTab _tab = LibraryTab.myWorkouts;
  String _query = '';

  /// Narrowing applied inside Discover, on top of [ExerciseCatalog]'s own
  /// loading. Null is "All" — the catalogue as it came back.
  ///
  /// Driven by [ExerciseCategory] rather than a hand-written list: Plyometrics
  /// and Powerlifting already shipped in the bundled set without a chip, and a
  /// category that is only in the data is a category nobody can filter by.
  ExerciseCategory? _category;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _startLoad();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Re-runs the network-first load. The offline banner and the error state
  /// both offer this rather than asking the user to leave and come back.
  void _reload() {
    // Not an arrow body: setState asserts when its callback returns the
    // Future it was handed rather than storing it.
    setState(() {
      _exercisesFuture = _startLoad();
    });
  }

  /// Starts a load and gives it a listener of its own.
  ///
  /// Discover is one pill away, so the load can fail while nothing is
  /// rendering it, and an error on a future nobody has listened to yet is an
  /// unhandled error rather than a state the screen can show. The handler
  /// keeps the failure on this side of the FutureBuilder, which draws it when
  /// the tab opens.
  Future<ExerciseCatalogResult> _startLoad() {
    final future = _catalog.load();
    unawaited(
      future.then(
        (_) {},
        onError: (Object error) =>
            debugPrint('Could not load the exercise catalogue: $error'),
      ),
    );
    return future;
  }

  /// Creates a session and opens it, the same way the Workout destination
  /// does, so both entry points leave the user in the same place.
  Future<void> _createWorkout() async {
    final navigator = Navigator.of(context);

    final stored = await startWorkout(context);
    if (stored == null || !mounted) return;

    navigator.pushNamed(WorkoutDetailScreen.routeFor(stored.id));
  }

  void _showTab(LibraryTab tab) => setState(() => _tab = tab);

  bool _matches(String text) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty || text.toLowerCase().contains(query);
  }

  // --------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final hasRotation = _rotation(provider).isNotEmpty;
    // The empty library has no search field in the design: there is nothing
    // to narrow, and the first move should be the loudest thing on screen.
    final showSearch = _tab != LibraryTab.myWorkouts || hasRotation;
    final showProgram = hasRotation;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Top inset only — the OS draws the phone's status bar, not the app.
          SliverToBoxAdapter(
            child: SafeArea(bottom: false, child: SizedBox(height: 8)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: _header(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSearch) ...[
                    _searchField(),
                    const SizedBox(height: 16),
                  ],
                  _filterPills(),
                  const SizedBox(height: 16),
                  // The current program heads every list, as it does in the
                  // frames: it is the context the rest of the library sits in,
                  // not a fourth destination of its own.
                  if (showProgram) ...[
                    _weekCard(provider),
                    const SizedBox(height: 16),
                  ],
                  switch (_tab) {
                    LibraryTab.myWorkouts => _myWorkouts(),
                    LibraryTab.discover => _discover(),
                    LibraryTab.saved => _saved(),
                  },
                  const SizedBox(height: 24),
                  _attribution(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THE TRAINING LIBRARY',
                style: text.annotation.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'YOUR WORK. YOUR WAY.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.28,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        _AddButton(tooltip: 'New workout', onPressed: _createWorkout),
      ],
    );
  }

  Widget _searchField() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              // The one field narrows whichever tab is open: workouts by
              // title, catalogue entries by name and muscle.
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Find a workout or exercise',
                // The theme's own body face rather than a family name: the
                // scale resolves through google_fonts, and a hand-written
                // family would fall back to the platform default.
                hintStyle: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurface),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              onPressed: () {
                _search.clear();
                setState(() => _query = '');
              },
              tooltip: 'Clear search',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterPills() {
    final text = context.text;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in LibraryTab.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(
                label: tab.label,
                selected: tab == _tab,
                labelStyle: text.labelCaps,
                onTap: () => _showTab(tab),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- my workouts

  Widget _myWorkouts() {
    final provider = context.watch<WorkoutProvider>();
    final entries = _rotation(provider);

    if (entries.isEmpty) {
      return _emptyLibrary();
    }

    final visible = entries.where((entry) => _matches(entry.title)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading('MY ROTATION', _count(visible.length, 'workout')),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          _note('No workouts match "${_query.trim()}".')
        else
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RotationRow(
                entry: entry,
                onTap: () => Navigator.of(context)
                    .pushNamed(WorkoutDetailScreen.routeFor(entry.workout.id)),
              ),
            ),
      ],
    );
  }

  /// The user's sessions grouped into the routines they repeat.
  ///
  /// "Lower body" trained five times is one entry in the rotation, not five:
  /// the list is what the library is for, and a session-by-session log is what
  /// the calendar and the dashboard are for. The entry opens its next
  /// scheduled occurrence when there is one, otherwise the last one trained.
  List<_RotationEntry> _rotation(WorkoutProvider provider) {
    final byTitle = <String, List<Workout>>{};
    for (final workout in provider.workouts) {
      // Rest days are not routines; the calendar is where they belong.
      if (workout.status == WorkoutStatus.rest) continue;
      byTitle.putIfAbsent(workout.title, () => []).add(workout);
    }

    final entries = <_RotationEntry>[
      for (final group in byTitle.values)
        _RotationEntry.from(group, provider.today),
    ];

    // What is coming leads; what is behind is ordered by how recently it was
    // trained. A rotation with nothing scheduled falls back to that order.
    entries.sort((a, b) {
      final next = a.next;
      final other = b.next;
      if (next != null && other != null) return next.date.compareTo(other.date);
      if (next != null) return -1;
      if (other != null) return 1;
      return b.workout.date.compareTo(a.workout.date);
    });

    // One routine is the session being walked into; the others that are
    // scheduled say when they are due instead, so the list does not read as
    // three simultaneous next sessions.
    for (final entry in entries) {
      if (entry.next == null) continue;
      entry.isNext = true;
      break;
    }

    return entries;
  }

  /// This week, as the design's current-program card: the frame is used for a
  /// program the app has no concept of, so it holds the week the user is
  /// actually in.
  Widget _weekCard(WorkoutProvider provider) {
    final text = context.text;

    final done = provider.sessionsDoneThisWeek;
    final target = provider.weeklyGoal;
    // Scoped to the week, not the account: the panel is labelled THIS WEEK.
    final next = provider.focusWorkoutThisWeek;

    final ratio = target == 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
    final headline =
        next?.title.toUpperCase() ??
        (done > 0 ? 'WEEK IN THE BOOKS' : 'NOTHING PLANNED');

    return _HeroPanel(
      minHeight: 160,
      shade: const ColoredBox(color: Color(0x73121512)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'CURRENT PROGRAM',
                style: text.annotation.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.lime,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.north_east_rounded,
                size: 20,
                color: AppColors.warmCream,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: text.programName.copyWith(color: AppColors.warmCream),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '$done of $target sessions done',
                style: text.programMeta.copyWith(color: AppColors.warmCream),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    // The track and fill are fixed over the photograph: this
                    // card keeps its dark scrim in both themes, so a surface
                    // token from the current theme would disappear in light.
                    const ColoredBox(
                      color: AppColors.inkMuted,
                      child: SizedBox(height: 3, width: double.infinity),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: const ColoredBox(
                        color: AppColors.lime,
                        child: SizedBox(height: 3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'WEEK OF '
                '${DateFormat('MMM d').format(provider.weekStart).toUpperCase()}',
                style: text.annotation.copyWith(color: AppColors.warmCream),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The empty library, as drawn: the welcome, a first step, and the other
  /// ways in. The frame's version recommends a specific workout with a fixed
  /// name, time and exercise count; this offers the action that creates a real
  /// session instead of a routine nobody chose.
  Widget _emptyLibrary() {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'MAKE YOUR FIRST MOVE.',
          style: text.programName,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'MAKE YOUR FIRST MOVE.',
          style: text.programName,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'No workouts yet. Start with the basics,\n'
          "then build a library that's yours.",
          style: text.exerciseMeta.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _firstWorkoutCard(),
        const SizedBox(height: 20),
        Text(
          'OTHER WAYS TO START',
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        _OutlineButton(
          icon: Icons.add_rounded,
          label: 'Create my own workout',
          onPressed: _createWorkout,
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your exercises. Make it your own.',
          style: text.annotation.copyWith(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _OutlineButton(
          icon: Icons.explore_outlined,
          label: 'Explore exercises',
          onPressed: () => _showTab(LibraryTab.discover),
        ),
      ],
    );
  }

  Widget _firstWorkoutCard() {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return _HeroPanel(
      minHeight: 224,
      shade: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xEB121512), Color(0x66121512)],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'GET STARTED',
            style: text.labelCaps.copyWith(color: AppColors.lime),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR FIRST SESSION',
                style: text.programName.copyWith(color: AppColors.warmCream),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Name it, then add the exercises you plan to train.',
                style: text.exerciseMeta.copyWith(
                  color: AppColors.warmCream,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _createWorkout,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.control,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create a workout',
                        style: text.labelCaps.copyWith(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- discover

  Widget _discover() {
    final provider = context.watch<WorkoutProvider>();

    return FutureBuilder<ExerciseCatalogResult>(
      future: _exercisesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) return _catalogError();

        final result = snapshot.data;
        final exercises = _filtered(result?.exercises ?? const []);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (result?.isOffline ?? false) ...[
              _offlineBanner(),
              const SizedBox(height: 12),
            ],
            _categoryChips(),
            const SizedBox(height: 16),
            _sectionHeading(
              'DISCOVER EXERCISES',
              _count(exercises.length, 'exercise'),
            ),
            const SizedBox(height: 12),
            if (exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    _query.trim().isEmpty
                        ? 'No exercises found.'
                        : 'No exercises match "${_query.trim()}".',
                    style: context.text.exerciseMeta,
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // An extent rather than a ratio: the card holds an image, a
                  // title, a muscle and up to two lines of tips, which does
                  // not scale with whatever width the phone hands over. A 0.68
                  // ratio is 165dp of card on a 320dp screen and the text
                  // block does not fit in it.
                  mainAxisExtent: 228,
                ),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  // Wrapped here rather than inside the card so the bookmark,
                  // which has its own gesture, still wins taps on itself.
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context)
                        .pushNamed(ExerciseDetailScreen.routeFor(exercise.id)),
                    child: _ExerciseCard(
                      exercise: exercise,
                      saved: provider.isSaved(exercise.id),
                      onToggleSaved: () =>
                          provider.toggleSavedExercise(exercise),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  /// Catalogue entries that survive both the category chip and the search
  /// field.
  List<LibraryExercise> _filtered(List<LibraryExercise> exercises) {
    return [
      for (final exercise in exercises)
        if (_inCategory(exercise) &&
            (_matches(exercise.name) || _matches(_muscleText(exercise))))
          exercise,
    ];
  }

  /// Every muscle name on an entry, so a search finds the second one too.
  String _muscleText(LibraryExercise exercise) =>
      [...exercise.primaryMuscles, ...exercise.secondaryMuscles].join(' ');

  bool _inCategory(LibraryExercise exercise) {
    final selected = _category;
    if (selected == null) return true;
    // The chip names a category; an entry whose category the catalogue does
    // not recognise stays visible under "All" only, rather than disappearing
    // from every filter.
    return ExerciseCategory.tryParse(exercise.category) == selected;
  }

  Widget _categoryChips() {
    final text = context.text;
    final options = <ExerciseCategory?>[null, ...ExerciseCategory.values];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(
                label: category?.label ?? 'All',
                selected: category == _category,
                labelStyle: text.annotation.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                compact: true,
                onTap: () => setState(() => _category = category),
              ),
            ),
        ],
      ),
    );
  }

  /// The offline notice: the grid is real either way, so this states where it
  /// came from instead of pretending the request answered.
  Widget _offlineBanner() {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
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
              style: text.previousPerf.copyWith(color: scheme.onSurfaceVariant),
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'Could not load the exercise library.',
            style: context.text.exerciseMeta,
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _reload, child: const Text('Retry')),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- saved

  Widget _saved() {
    final provider = context.watch<WorkoutProvider>();
    final saved = provider.savedExercises;

    if (saved.isEmpty) {
      return _emptySaved();
    }

    final visible = saved
        .where(
          (entry) =>
              _matches(entry.exercise.name) ||
              // The row shows the muscle it trains, so the search field has to
              // find it by that too - the same terms the catalogue matches on,
              // since a saved entry came from there.
              _matches(_muscleText(entry.exercise)),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading('SAVED EXERCISES', _count(visible.length, 'exercise')),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          _note('No saved exercises match "${_query.trim()}".')
        else
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SavedRow(
                entry: entry,
                onRemove: () => provider.toggleSavedExercise(entry.exercise),
              ),
            ),
      ],
    );
  }

  Widget _emptySaved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'NOTHING SAVED YET.',
          style: context.text.programName,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Keep an exercise from Discover and it waits here.',
          style: context.text.exerciseMeta.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _OutlineButton(
          icon: Icons.explore_outlined,
          label: 'Browse exercises',
          onPressed: () => _showTab(LibraryTab.discover),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- shared bits

  Widget _sectionHeading(String label, String trailing) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.annotation.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          trailing,
          style: text.previousPerf.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _note(String message) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        message,
        style: context.text.exerciseMeta.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }

  /// wger asks for attribution (its entries are CC BY-SA, per entry) and
  /// exercemus is MIT, so both are named where the catalogue is shown rather
  /// than only in an about screen. free-exercise-db is public domain but named
  /// anyway, so a reader can tell where the offline catalogue came from. The
  /// card photography is Unsplash, whose licence does not require a credit but
  /// makes the source worth naming.
  ///
  /// The full notices, including the bundled fonts, are in docs/ATTRIBUTION.md.
  Widget _attribution() {
    return Text(
      'Exercise data: wger.de (CC BY-SA 3.0/4.0) · exercemus (MIT) · '
      'free-exercise-db (public domain). Exercise photos: Unsplash.',
      style: context.text.annotation.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  static String _count(int value, String noun) =>
      '$value ${value == 1 ? noun : '${noun}s'}';
}

/// One routine in the rotation, with the sessions behind it.
class _RotationEntry {
  _RotationEntry({
    required this.workout,
    required this.next,
    required this.lastDone,
  });

  /// The session this entry opens.
  final Workout workout;

  /// The soonest occurrence that is still ahead, if any.
  final Workout? next;

  /// The most recent occurrence already trained, if any.
  final Workout? lastDone;

  /// Whether this is the one occurrence the user is walking into. Set by the
  /// list once it knows the whole rotation, because it takes the other entries
  /// to know they are not it.
  bool isNext = false;

  /// Groups every session sharing a title.
  factory _RotationEntry.from(List<Workout> group, DateTime today) {
    Workout? next;
    Workout? lastDone;
    Workout? latest;

    for (final workout in group) {
      if (latest == null || workout.date.isAfter(latest.date)) latest = workout;

      if (workout.status == WorkoutStatus.completed) {
        if (lastDone == null || workout.date.isAfter(lastDone.date)) {
          lastDone = workout;
        }
      } else if (!workout.date.isBefore(today)) {
        if (next == null || workout.date.isBefore(next.date)) next = workout;
      }
    }

    return _RotationEntry(
      workout: next ?? lastDone ?? latest!,
      next: next,
      lastDone: lastDone,
    );
  }

  String get title => workout.title;

  /// What this routine is to the user right now.
  String get label {
    if (isNext) return 'NEXT SESSION';
    final upcoming = next;
    if (upcoming != null) return 'PLANNED ${_day(upcoming.date)}';
    final done = lastDone;
    if (done != null) return 'LAST TRAINED ${_day(done.date)}';
    return 'NOT TRAINED YET';
  }

  static String _day(DateTime date) =>
      DateFormat('MMM d').format(date).toUpperCase();

  String get meta {
    final parts = <String>[
      if (workout.logs.isNotEmpty)
        '${workout.logs.length} '
            '${workout.logs.length == 1 ? 'exercise' : 'exercises'}',
      if (workout.durationMin > 0) '${workout.durationMin} min',
      if (workout.modality != null) workout.modality!.label,
      if (workout.targetMuscleGroups.isNotEmpty)
        workout.targetMuscleGroups.first,
    ];
    return parts.join('  ·  ');
  }
}

/// The design's pill: ink and lime when it is the one selected, an outline
/// otherwise.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.labelStyle,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final TextStyle labelStyle;
  final VoidCallback onTap;

  /// A step down from the tab row, for the second row inside Discover.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 34 : 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: labelStyle.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// The bare plus in the header.
///
/// The design sets a 22px glyph on the page rather than on a filled tile, so
/// the button keeps a full 44px target without drawing a surface around it.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(Icons.add_rounded, size: 22),
      style: IconButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(44, 44),
      ),
    );
  }
}

/// The design's photographic panel: the image, a shade over it, content on top.
///
/// Sized by its content and never shorter than the height the design gives it,
/// so a title long enough to wrap grows the panel instead of overflowing the
/// fixed box the frame's measurements imply.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.child,
    required this.shade,
    this.minHeight = 160,
  });

  final Widget child;
  final Widget shade;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/program_hero.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            Positioned.fill(child: shade),
            Padding(padding: const EdgeInsets.all(18), child: child),
          ],
        ),
      ),
    );
  }
}

/// One routine: what it is to the user, its name, and what it contains.
class _RotationRow extends StatelessWidget {
  const _RotationRow({required this.entry, required this.onTap});

  final _RotationEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _iconFor(entry.workout.targetMuscleGroups),
                size: 26,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: text.annotation.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    entry.title.toUpperCase(),
                    style: text.programBadge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // A session planned with no exercises and no target muscle
                  // has nothing to say here. An empty string would still take
                  // a line's height and leave the card with a blank row in it.
                  if (entry.meta.isNotEmpty)
                    Text(
                      entry.meta,
                      style: text.previousPerf.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.north_east_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// The symbol the row leads with. Chosen from what the session trains, so
  /// the list reads at a glance without inventing a category per title.
  static IconData _iconFor(List<String> muscles) {
    if (muscles.isEmpty) return Icons.fitness_center_rounded;
    final first = muscles.first.toLowerCase();
    if (first.contains('quad') ||
        first.contains('hamstring') ||
        first.contains('glute') ||
        first.contains('calf') ||
        first.contains('leg')) {
      return Icons.directions_run_rounded;
    }
    if (first.contains('core') || first.contains('ab')) {
      return Icons.self_improvement_rounded;
    }
    if (first.contains('full') || first.contains('cardio')) {
      return Icons.bolt_rounded;
    }
    return Icons.fitness_center_rounded;
  }
}

/// The bookmark that keeps an exercise.
///
/// Filled when it is kept, outlined when it is not, so the two states read at
/// a glance in a grid of identical cards.
class _Bookmark extends StatelessWidget {
  const _Bookmark({required this.isSaved, required this.onToggle});

  final bool isSaved;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onToggle,
      tooltip: isSaved ? 'Remove from saved' : 'Save this exercise',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 20,
        color: isSaved ? scheme.primary : scheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
      ),
    );
  }
}

/// The symbol a saved exercise leads with.
IconData _iconForCategory(String category) {
  return switch (ExerciseCategory.tryParse(category)) {
    ExerciseCategory.cardio => Icons.directions_run_rounded,
    ExerciseCategory.mobility => Icons.self_improvement_rounded,
    ExerciseCategory.plyometrics => Icons.bolt_rounded,
    ExerciseCategory.calisthenics ||
    ExerciseCategory.calisthenicSkills => Icons.accessibility_new_rounded,
    _ => Icons.fitness_center_rounded,
  };
}

/// One kept exercise, with the way out of the list.
class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.entry, required this.onRemove});

  final SavedExercise entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final exercise = entry.exercise;

    final meta = <String>[
      if (exercise.primaryMuscle.isNotEmpty) exercise.primaryMuscle,
      exercise.categoryLabel,
      if (exercise.level != null) exercise.level!,
    ].join('  ·  ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconForCategory(exercise.category),
              size: 26,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAVED ${DateFormat('MMM d').format(entry.savedAt).toUpperCase()}',
                  style: text.annotation.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  exercise.name.toUpperCase(),
                  style: text.programBadge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  style: text.previousPerf.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove from saved',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.bookmark_remove_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The design's outlined secondary action.
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
    );
  }
}

/// One catalogue entry, with its bookmark.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.saved,
    required this.onToggleSaved,
  });

  final LibraryExercise exercise;

  /// Whether the user has kept this one already.
  final bool saved;

  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final bundled = ExerciseImages.bundledAsset(exercise);
    final placeholder = Icon(
      Icons.fitness_center_rounded,
      size: 30,
      color: scheme.onSurface,
    );

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
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: bundled != null
                      ? Image.asset(
                          bundled,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => placeholder,
                        )
                      : Image.network(
                          ExerciseImages.forExercise(exercise),
                          fit: BoxFit.cover,
                          cacheWidth: 480,
                          filterQuality: FilterQuality.medium,
                          excludeFromSemantics: true,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : placeholder,
                          errorBuilder: (_, _, _) => placeholder,
                        ),
                ),
              ),
              // Kept against the corner of the image rather than under the
              // text, so the card's lower half reads the same whatever the
              // title's length.
              Positioned(
                top: 4,
                right: 4,
                child: _Bookmark(isSaved: saved, onToggle: onToggleSaved),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Flexible from here down, so a long title at a large text scale
          // gives up a line instead of overflowing the card. The level stays
          // pinned to the bottom, which is why the space is distributed
          // between the two rather than with a spacer between them.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          exercise.name,
                          style: text.exerciseMeta.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        exercise.primaryMuscle,
                        style: text.annotation.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (exercise.tipsText != null) ...[
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            exercise.tipsText!,
                            style: text.annotation.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${categoryLabel(exercise.category).toUpperCase()} · '
                  '${(exercise.level ?? 'beginner').toUpperCase()}',
                  style: text.annotation.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
