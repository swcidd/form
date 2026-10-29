import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../data/exercise_images.dart';
import '../models/exercise_tags.dart';
import '../models/library_exercise.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/tag_pill.dart';

/// One catalogue exercise, in full: what it is, what it trains, how to do it.
///
/// Reached from the picker and from the library's Discover cards, so it is the
/// one place that gets to say everything the catalogue holds about an entry.
/// The list surfaces (the picker row, the library card) stay one line and a
/// tag row; this is where the instruction list and the form cues stop being
/// truncated.
///
/// Read-only and parameterised by path: the slug lives in `route.name`
/// (`/exercise-detail/<slug>`), the same way the workout screens carry their
/// id, so the link is shareable and no route argument has to survive a
/// rebuild. The catalogue is injected so a test drives both the loaded and the
/// failed path without touching the network.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.route, this.catalog});

  final RouteSettings route;

  /// The catalogue loader; the real one by default.
  final ExerciseCatalog? catalog;

  static const String routeName = '/exercise-detail';

  static String routeFor(String slug) => '$routeName/$slug';

  @override
  Widget build(BuildContext context) {
    return _ExerciseDetailBody(route: route, catalog: catalog);
  }
}

/// Loads the catalogue once, resolves the slug, and renders either the entry
/// or the reason it could not be shown.
///
/// Stateful only because the load is asynchronous: the future is created once
/// in [initState] rather than in `build`, so a rebuild from the image or a
/// rotation does not ask the network again.
class _ExerciseDetailBody extends StatefulWidget {
  const _ExerciseDetailBody({required this.route, this.catalog});

  final RouteSettings route;
  final ExerciseCatalog? catalog;

  @override
  State<_ExerciseDetailBody> createState() => _ExerciseDetailBodyState();
}

class _ExerciseDetailBodyState extends State<_ExerciseDetailBody> {
  late final Future<ExerciseCatalogResult> _future =
      (widget.catalog ?? ExerciseCatalog()).load();

  @override
  Widget build(BuildContext context) {
    final slug = _slugFromPath(widget.route.name);
    if (slug == null) return const _NotFound();

    return FutureBuilder<ExerciseCatalogResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _LoadFailed();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }

        final catalogue = snapshot.data?.exercises ?? const <LibraryExercise>[];
        final exercise = _find(catalogue, slug);
        if (exercise == null) return const _NotFound();

        return _Detail(exercise: exercise, catalogue: catalogue);
      },
    );
  }

  /// The slug from `/exercise-detail/<slug>`, decoded the way the workout
  /// screens read their id out of the path.
  static String? _slugFromPath(String? routeName) {
    if (routeName == null) return null;
    final segments = routeName.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return Uri.decodeComponent(segments[1]);
  }

  /// The entry the route names.
  ///
  /// Matched on a hyphenated name slug, which is the handle the entry's own
  /// [Exercise] form exposes, and on the stored id as a fallback so a caller
  /// that pushed the route from the id still lands on the entry.
  static LibraryExercise? _find(List<LibraryExercise> catalogue, String slug) {
    for (final exercise in catalogue) {
      final matches = _slugOf(exercise.name) == slug || exercise.id == slug;
      if (matches) return exercise;
    }
    return null;
  }

  static String _slugOf(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
}

/// The full entry: toolbar, photograph, and every section the catalogue fills.
class _Detail extends StatelessWidget {
  const _Detail({required this.exercise, required this.catalogue});

  final LibraryExercise exercise;
  final List<LibraryExercise> catalogue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: _Toolbar(name: exercise.name),
            ),
          ),
          SliverToBoxAdapter(child: _Hero(exercise: exercise)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: _Body(exercise: exercise, catalogue: catalogue),
            ),
          ),
        ],
      ),
    );
  }
}

/// The compact top bar: the way out on the left, the name held in the middle.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            // Kept clear of the chevron on both sides so a long name ellipsises
            // rather than running under the button.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.programBadge.copyWith(
                  fontSize: 20,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The photograph, full width, with the same shade the workout hero carries.
///
/// A bundled asset is preferred when the entry has one; otherwise the
/// muscle-derived Unsplash photograph is hotlinked, exactly as the library
/// cards do. The shade stays a fixed ink gradient rather than a theme token:
/// it sits over a photograph that is dark in both themes.
class _Hero extends StatelessWidget {
  const _Hero({required this.exercise});

  final LibraryExercise exercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bundled = ExerciseImages.bundledAsset(exercise);
    final placeholder = ColoredBox(color: scheme.surfaceContainerHigh);

    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bundled != null)
            Image.asset(
              bundled,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => placeholder,
            )
          else
            Image.network(
              ExerciseImages.forExercise(exercise),
              fit: BoxFit.cover,
              cacheWidth: 720,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => placeholder,
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.ink.withValues(alpha: 0.91),
                  AppColors.ink.withValues(alpha: 0.13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything under the photograph, as one scrolling column.
class _Body extends StatelessWidget {
  const _Body({required this.exercise, required this.catalogue});

  final LibraryExercise exercise;
  final List<LibraryExercise> catalogue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final description = exercise.description?.trim();
    final mechanic = _capitalise(exercise.mechanic);
    final force = _capitalise(exercise.force);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exerciseTitle(exercise, catalogue),
          style: text.exerciseName.copyWith(
            fontSize: 32,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        TagPillRow(exerciseTags(exercise)),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            description,
            style: text.exerciseMeta.copyWith(
              fontSize: 13,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (exercise.primaryMuscles.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Section(
            label: 'PRIMARY MUSCLES',
            child: _muscleLine(context, exercise.primaryMuscles),
          ),
        ],
        if (exercise.secondaryMuscles.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Section(
            label: 'SECONDARY MUSCLES',
            child: _muscleLine(context, exercise.secondaryMuscles),
          ),
        ],
        // The instruction list is the point of the screen, so an empty one
        // drops the whole section rather than leaving a heading over nothing.
        if (exercise.instructions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Section(
            label: 'HOW TO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (
                  var index = 0;
                  index < exercise.instructions.length;
                  index++
                )
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == exercise.instructions.length - 1
                          ? 0
                          : 12,
                    ),
                    child: _StepRow(
                      number: index + 1,
                      text: exercise.instructions[index],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (exercise.tips.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Section(
            label: 'FORM CUES',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < exercise.tips.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == exercise.tips.length - 1 ? 0 : 8,
                    ),
                    child: Text(
                      exercise.tips[index],
                      style: text.exerciseMeta.copyWith(
                        fontSize: 13,
                        height: 1.5,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (mechanic != null || force != null) ...[
          const SizedBox(height: 24),
          _Section(
            label: 'DETAILS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (mechanic != null)
                  _DetailRow(
                    label: 'MECHANIC',
                    value: mechanic,
                    showDivider: force != null,
                  ),
                if (force != null) _DetailRow(label: 'FORCE', value: force),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _muscleLine(BuildContext context, List<String> muscles) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      muscles.map(_capitalise).join('  ·  '),
      style: context.text.exerciseMeta.copyWith(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );
  }

  /// The catalogue stores mechanic and force in lower case ("compound",
  /// "push"); the row shows them as a value, so they read as one.
  static String? _capitalise(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}

/// A heading and the content under it, spaced the same way everywhere.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelCaps.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// One numbered instruction line: the count in the display face, the step in
/// the body face, aligned so a wrapping step keeps its number.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = context.text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$number',
            style: type.dataMetric.copyWith(
              fontSize: 20,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: type.exerciseMeta.copyWith(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// A label on the left and its value on the right, with an optional hairline.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Text(
                label,
                style: text.labelCaps.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                value,
                style: text.exerciseMeta.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: scheme.outlineVariant),
      ],
    );
  }
}

/// The screen while the catalogue is in flight.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// The slug names nothing in the catalogue.
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return _Empty(
      icon: Icons.search_off_rounded,
      title: 'Exercise not found',
      message: 'It may have been removed from the catalogue.',
    );
  }
}

/// The catalogue could not be reached at all, online or offline.
class _LoadFailed extends StatelessWidget {
  const _LoadFailed();

  @override
  Widget build(BuildContext context) {
    return _Empty(
      icon: Icons.error_outline_rounded,
      title: 'Could not load this exercise',
      message: 'The exercise library could not be reached.',
    );
  }
}

/// The shared failure shell, so both dead ends leave the user a way back.
class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: EmptyState(
          icon: icon,
          title: title,
          message: message,
          actionLabel: 'Go back',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
