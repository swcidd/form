import 'dart:async';

import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../data/exercise_images.dart';
import '../models/exercise_tags.dart';
import '../models/library_exercise.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/tag_pill.dart';

/// The exercise picker: search the catalogue, narrow it, choose, and hand the
/// choice back to whoever opened it.
///
/// Laid out from the Figma "Workout · Add exercise" frame (544:2117). It is a
/// route of its own rather than a sheet, because a catalogue is long, the two
/// facets open sheets of their own, and the caller wants a small, typed answer
/// back: [Navigator.pop] carries the selected exercises in the order they were
/// tapped, and a dismissed screen carries nothing.
///
/// The catalogue is the same network-first loader the library uses, so the
/// construction flow is offline-capable without knowing anything about it:
/// [catalog] exists so tests can drive both paths without touching the network.
class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key, this.catalog});

  static const String routeName = '/add-exercise';

  /// The catalogue loader; the real one by default.
  final ExerciseCatalog? catalog;

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  /// Where the row's info icon goes.
  ///
  /// The detail screen is owned elsewhere and registers this same name;
  /// referencing it by string rather than importing it keeps this screen
  /// compiling while that one is still being written.
  static const String _detailRoute = '/exercise-detail';

  late final ExerciseCatalog _catalog = widget.catalog ?? ExerciseCatalog();
  late Future<ExerciseCatalogResult> _resultFuture;
  final _search = TextEditingController();

  String _query = '';

  /// Narrowing applied on top of the load. Null is "All" — the catalogue as it
  /// came back. The raw catalogue value is kept so filtering never has to undo
  /// the reading label the button shows.
  String? _equipment;
  String? _muscle;

  /// The chosen exercises in tap order. A list rather than a set: the caller
  /// builds a workout from it, and a workout's exercise order is the order the
  /// user picked them in.
  final List<LibraryExercise> _selected = [];

  @override
  void initState() {
    super.initState();
    _resultFuture = _startLoad();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Re-runs the load. The error state offers this rather than asking the user
  /// to leave and come back.
  void _reload() {
    // Not an arrow body: setState asserts when its callback returns the Future
    // it was handed rather than storing it.
    setState(() {
      _resultFuture = _startLoad();
    });
  }

  /// Starts a load and gives it a listener of its own, so a failure that lands
  /// before the [FutureBuilder] draws is a state this screen can show rather
  /// than an unhandled error.
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

  void _toggle(LibraryExercise exercise) {
    setState(() {
      // remove reports whether it was there; a second tap unselects.
      if (!_selected.remove(exercise)) _selected.add(exercise);
    });
  }

  /// Opens the detail screen for [exercise].
  void _openDetail(LibraryExercise exercise) {
    Navigator.of(context)
        .pushNamed('$_detailRoute/${Uri.encodeComponent(exercise.id)}');
  }

  /// Pops with the current selection. An empty selection is still an answer:
  /// the caller decides what "no exercises" means.
  void _submit() =>
      Navigator.of(context).pop(List<LibraryExercise>.of(_selected));

  /// Cancels: nothing is returned, so the caller leaves the workout alone.
  void _cancel() => Navigator.of(context).pop();

  // --------------------------------------------------------------- filtering

  /// Catalogue entries that survive both facets and the search field.
  List<LibraryExercise> _visible(List<LibraryExercise> catalogue) {
    return [
      for (final exercise in catalogue)
        if (_inEquipment(exercise) && _inMuscle(exercise) && _matches(exercise))
          exercise,
    ];
  }

  bool _inEquipment(LibraryExercise exercise) {
    final selected = _equipment;
    return selected == null || exercise.equipment.contains(selected);
  }

  bool _inMuscle(LibraryExercise exercise) {
    final selected = _muscle;
    return selected == null || exercise.primaryMuscles.contains(selected);
  }

  /// Name and alias, case-insensitively, so "rdl" finds "Romanian Deadlift".
  bool _matches(LibraryExercise exercise) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (exercise.name.toLowerCase().contains(query)) return true;
    return exercise.aliases.any((alias) => alias.toLowerCase().contains(query));
  }

  /// Every distinct value of a facet, in reading order.
  List<String> _facets(
    List<LibraryExercise> catalogue,
    List<String> Function(LibraryExercise) values,
  ) {
    final seen = <String>{};
    final result = <String>[];
    for (final exercise in catalogue) {
      for (final value in values(exercise)) {
        if (seen.add(value)) result.add(value);
      }
    }
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  Future<void> _chooseFacet({
    required String title,
    required List<String> values,
    required String? selected,
    required String Function(String value) label,
    required ValueChanged<String?> onChosen,
  }) async {
    final choice = await showModalBottomSheet<_FacetChoice>(
      context: context,
      showDragHandle: true,
      builder: (_) => _FacetSheet(
        title: title,
        values: values,
        selected: selected,
        label: label,
      ),
    );
    // Dismissed — a tap outside or a swipe down — changes nothing. "All" comes
    // back as a choice with a null value, which is why the two are not both
    // null.
    if (choice == null) return;
    setState(() => onChosen(choice.value));
  }

  // --------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _toolbar(),
            Expanded(
              child: FutureBuilder<ExerciseCatalogResult>(
                future: _resultFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return _catalogError();

                  final result = snapshot.data;
                  final catalogue =
                      result?.exercises ?? const <LibraryExercise>[];
                  return _content(result, catalogue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cancel, the title, and Next. The title is centred on the frame rather
  /// than between the two labels, because "Add Exercise" would drift as the
  /// side labels changed width — hence the [Stack].
  Widget _toolbar() {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Add Exercise',
              style: text.exerciseMeta.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: _cancel,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Cancel',
                      style: text.exerciseMeta.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _submit,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Next',
                      style: text.exerciseMeta.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    ExerciseCatalogResult? result,
    List<LibraryExercise> catalogue,
  ) {
    final visible = _visible(catalogue);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result?.isOffline ?? false) ...[
            _offlineBanner(),
            const SizedBox(height: 12),
          ],
          _searchField(),
          const SizedBox(height: 12),
          _filterRow(catalogue),
          const SizedBox(height: 20),
          _eyebrow(visible.length),
          const SizedBox(height: 12),
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    title: 'Nothing matches',
                    message:
                        'Try another search, or clear the equipment and '
                        'muscle filters.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exercise = visible[index];
                      return _ExerciseRow(
                        exercise: exercise,
                        catalogue: catalogue,
                        selected: _selected.contains(exercise),
                        onTap: () => _toggle(exercise),
                        onInfo: () => _openDetail(exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search exercise',
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
        ],
      ),
    );
  }

  Widget _filterRow(List<LibraryExercise> catalogue) {
    final equipment = _facets(catalogue, (e) => e.equipment);
    final muscles = _facets(catalogue, (e) => e.primaryMuscles);

    return Row(
      children: [
        Expanded(
          child: _FilterButton(
            label: _equipment == null
                ? 'All Equipment'
                : equipmentTitle(_equipment!),
            onTap: () => _chooseFacet(
              title: 'Equipment',
              values: equipment,
              selected: _equipment,
              label: equipmentTitle,
              onChosen: (value) => _equipment = value,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FilterButton(
            label: _muscle ?? 'All Muscles',
            onTap: () => _chooseFacet(
              title: 'Muscles',
              values: muscles,
              selected: _muscle,
              label: (value) => value,
              onChosen: (value) => _muscle = value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _eyebrow(int count) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'EXERCISES',
          style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          '$count ${count == 1 ? 'exercise' : 'exercises'}',
          style: text.annotation.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// The offline notice: the list is real either way, so this states where it
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
}

/// The answer a facet sheet gives back: "All" is a choice with a null value,
/// which is distinct from a dismissal (a null choice), so the two do not have
/// to be told apart by a sentinel string.
class _FacetChoice {
  const _FacetChoice(this.value);

  /// The raw catalogue value, or null for "All".
  final String? value;
}

/// One facet's values behind a modal sheet. The first row is "All", which
/// clears the facet.
class _FacetSheet extends StatelessWidget {
  const _FacetSheet({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
  });

  final String title;
  final List<String> values;
  final String? selected;
  final String Function(String value) label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title.toUpperCase(),
                style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _FacetRow(
                    label: 'All',
                    selected: selected == null,
                    onTap: () =>
                        Navigator.of(context).pop(const _FacetChoice(null)),
                  ),
                  for (final value in values)
                    _FacetRow(
                      label: label(value),
                      selected: selected == value,
                      onTap: () =>
                          Navigator.of(context).pop(_FacetChoice(value)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacetRow extends StatelessWidget {
  const _FacetRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: context.text.exerciseMeta.copyWith(
          fontSize: 14,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, size: 18, color: scheme.primary)
          : null,
    );
  }
}

/// One of the two narrowing controls. Equal width with its sibling, and it
/// states the facet it is currently holding.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.exerciseMeta.copyWith(
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// One catalogue entry: what it is, its tags, and the two things a tap can do
/// here — select it, or open it.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.catalogue,
    required this.selected,
    required this.onTap,
    required this.onInfo,
  });

  final LibraryExercise exercise;

  /// The whole visible catalogue, because the title tells equipment variants
  /// apart only by seeing the other rows.
  final List<LibraryExercise> catalogue;

  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _Thumbnail(exercise: exercise),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exerciseTitle(exercise, catalogue),
                    style: text.programBadge.copyWith(fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  TagPillRow(exerciseTags(exercise)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onInfo,
              tooltip: 'Exercise details',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 64dp photo a row leads with: a bundled asset when one was saved,
/// otherwise the hotlinked photograph the library cards use.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.exercise});

  final LibraryExercise exercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bundled = ExerciseImages.bundledAsset(exercise);
    final placeholder = Icon(
      Icons.fitness_center_rounded,
      size: 28,
      color: scheme.onSurface,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 64,
        height: 64,
        child: ColoredBox(
          color: scheme.surfaceContainer,
          child: bundled != null
              ? Image.asset(
                  bundled,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                )
              : Image.network(
                  ExerciseImages.forExercise(exercise),
                  fit: BoxFit.cover,
                  cacheWidth: 160,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : placeholder,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}
