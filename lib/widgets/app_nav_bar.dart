import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../navigation/app_tab.dart';

/// Reusable bottom navigation bar using Lucide SVG icons.
///
/// Uniform destination bar:
/// - Home (activity icon)
/// - Progress (chart-no-axes-combined icon)
/// - Workout (dumbbell icon)
/// - Library (library icon)
/// - Profile (user-round icon)
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.iconSize = 22,
  });

  final AppTab selected;
  final ValueChanged<AppTab> onSelected;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: NavigationBar(
        selectedIndex: _slots.indexOf(selected),
        onDestinationSelected: (index) {
          onSelected(_slots[index]);
        },
        destinations: [for (final tab in _slots) _destination(context, tab)],
        height: 72,
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  /// The destinations in uniform layout.
  static List<AppTab> get _slots => [
    AppTab.home,
    AppTab.progress,
    AppTab.workout,
    AppTab.library,
    AppTab.profile,
  ];

  Widget _destination(BuildContext context, AppTab tab) {
    final isSelected = tab == selected;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return NavigationDestination(
      key: tab == AppTab.workout ? const Key('workout_destination') : null,
      icon: _SvgIcon(
        assetPath: tab.iconAssetPath,
        size: iconSize,
        color: color,
      ),
      selectedIcon: _SvgIcon(
        assetPath: tab.selectedIconAssetPath,
        size: iconSize,
        color: color,
      ),
      label: tab.label,
      tooltip: tab.label,
    );
  }
}

/// SVG icon widget with consistent sizing and coloring.
class _SvgIcon extends StatelessWidget {
  const _SvgIcon({
    required this.assetPath,
    required this.size,
    required this.color,
  });

  final String assetPath;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
