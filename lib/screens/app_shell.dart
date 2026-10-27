import 'package:flutter/material.dart';

import '../navigation/app_tab.dart';
import '../widgets/app_nav_bar.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';

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
      bottomNavigationBar: AppNavBar(selected: _active, onSelected: _select),
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
      AppTab.workout => const CalendarScreen(),
      AppTab.library => const LibraryScreen(),
      AppTab.profile => const ProfileScreen(),
    };
  }
}
