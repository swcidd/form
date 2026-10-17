/// The root destinations, in tab-bar order.
///
/// - Home (activity icon)
/// - Progress (chart-no-axes-combined icon)
/// - Workout (dumbbell icon)
/// - Library (library icon)
/// - Profile (user-round icon)
///
/// Modelled as an enum so the bar, the route table and any in-app
/// cross-reference all resolve a destination the same way.
enum AppTab {
  home(
    routeName: '/',
    label: 'Home',
    iconAssetPath: 'assets/icons/activity.svg',
    selectedIconAssetPath: 'assets/icons/activity.svg',
  ),
  progress(
    routeName: '/progress',
    label: 'Progress',
    iconAssetPath: 'assets/icons/chart-no-axes-combined.svg',
    selectedIconAssetPath: 'assets/icons/chart-no-axes-combined.svg',
  ),
  workout(
    routeName: '/workout',
    label: 'Workout',
    iconAssetPath: 'assets/icons/dumbbell.svg',
    selectedIconAssetPath: 'assets/icons/dumbbell.svg',
  ),
  library(
    routeName: '/library',
    label: 'Library',
    iconAssetPath: 'assets/icons/library.svg',
    selectedIconAssetPath: 'assets/icons/library.svg',
  ),
  profile(
    routeName: '/profile',
    label: 'Profile',
    iconAssetPath: 'assets/icons/user-round.svg',
    selectedIconAssetPath: 'assets/icons/user-round.svg',
  );

  const AppTab({
    required this.routeName,
    required this.label,
    required this.iconAssetPath,
    required this.selectedIconAssetPath,
  });

  final String routeName;
  final String label;
  final String iconAssetPath;
  final String selectedIconAssetPath;

  /// Resolves a route name to its tab, falling back to [AppTab.home].
  ///
  /// Used by the route table, where an unmatched path has to land somewhere
  /// rather than throw.
  static AppTab fromRoute(String? routeName) {
    for (final tab in AppTab.values) {
      if (tab.routeName == routeName) return tab;
    }
    return AppTab.home;
  }
}
