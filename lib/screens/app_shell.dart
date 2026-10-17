import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_tab.dart';
import '../providers/workout_provider.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/new_workout_dialog.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'progress_screen.dart';
import 'workout_detail_screen.dart';

/// Hosts the root tabs and owns which one is visible.
///
/// Tabs live in an [IndexedStack] rather than being rebuilt on each tap, so a
/// tab keeps whatever the user left on it. Rebuilding on tap would silently
/// discard that state every time they came back.
///
/// Each tab is built lazily and kept once built. The stack alone would construct
/// all of them on first paint, running work for screens the user may never open.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.tab = AppTab.home});

  /// Which tab to show first. Taken from the route so `/library` opens the
  /// library rather than the home tab wearing a library URL.
  final AppTab tab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _active = widget.tab;

  void _select(AppTab tab) {
    if (_active == tab) return;
    setState(() => _active = tab);
  }

  /// Called when the Workout tab is selected. Opens the pre-workout screen.
  Future<void> _onWorkoutSelected() async {
    final provider = context.read<WorkoutProvider>();
    final target = provider.focusWorkout ?? provider.workouts.lastOrNull;
    final navigator = Navigator.of(context);

    if (target != null) {
      navigator.pushNamed(WorkoutDetailScreen.routeFor(target.id));
      return;
    }

    final created = await NewWorkoutDialog.show(context);
    if (created == null) return;

    final stored = provider.addWorkout(created);
    navigator.pushNamed(WorkoutDetailScreen.routeFor(stored.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _active.index,
        children: [
          for (final tab in AppTab.values)
            _LazyTab(tab: tab, active: _active, select: _select),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        selected: _active,
        onSelected: _select,
        onWorkoutPressed: _onWorkoutSelected,
      ),
    );
  }
}

/// Builds one tab on first visit and keeps it thereafter.
class _LazyTab extends StatefulWidget {
  const _LazyTab({
    required this.tab,
    required this.active,
    required this.select,
  });

  final AppTab tab;
  final AppTab active;
  final ValueChanged<AppTab> select;

  @override
  State<_LazyTab> createState() => _LazyTabState();
}

class _LazyTabState extends State<_LazyTab> {
  bool _visited = false;

  @override
  void initState() {
    super.initState();
    if (widget.active == widget.tab) _visited = true;
  }

  @override
  void didUpdateWidget(_LazyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `active` arrives as a plain field rather than an inherited dependency, so
    // didChangeDependencies does not fire when the tab changes and the latch has
    // to be updated here instead.
    if (!_visited && widget.active == widget.tab) _visited = true;
  }

  @override
  Widget build(BuildContext context) {
    return _visited ? _body(widget.tab) : const SizedBox.shrink();
  }

  Widget _body(AppTab tab) {
    return switch (tab) {
      AppTab.home => HomeScreen(onSelectTab: widget.select),
      AppTab.progress => const ProgressScreen(),
      AppTab.workout => const WorkoutTabScreen(),
      AppTab.library => const LibraryScreen(),
      AppTab.profile => const PlaceholderTabScreen(tab: AppTab.profile),
    };
  }
}

/// Workout tab - shows the pre-workout screen or creates a new workout.
class WorkoutTabScreen extends StatelessWidget {
  const WorkoutTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger the workout action when this tab becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shell = context.findAncestorStateOfType<_AppShellState>();
      shell?._onWorkoutSelected();
    });

    return const SizedBox.shrink();
  }
}

/// Stands in for a tab that is routed and reachable but not built yet.
///
/// Exists so the bar can be demonstrated without shipping three dead controls
/// that do nothing on tap. Each one states plainly what it will do, which is
/// more honest than a spinner or a blank page, and gives the destination a
/// real name in the UI so the navigation is reviewable before the screens land.
///
/// The next slice replaces these one at a time; nothing else has to change.
class PlaceholderTabScreen extends StatelessWidget {
  const PlaceholderTabScreen({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(),
      body: EmptyState(
        icon: Icons.fitness_center_outlined,
        title: '${tab.label} is next',
        message: _messageFor(tab),
      ),
    );
  }

  static String _messageFor(AppTab tab) => switch (tab) {
    AppTab.progress =>
      'Your strength progress, personal records and volume trends.',
    AppTab.profile =>
      'Your training totals, personal records and the settings behind them.',
    AppTab.home => 'The dashboard.',
    AppTab.workout => 'Your workout session.',
    AppTab.library => 'The training library.',
  };
}
