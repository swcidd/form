import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/app_tab.dart';
import 'providers/workout_provider.dart';
import 'screens/app_shell.dart';
import 'screens/set_logging_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/workout_summary_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PlusOneApp());
}

/// Root of the application.
///
/// The tabs are declared in [routes], each resolving to the shell with its
/// own tab selected, so every destination has a real URL. The workout detail
/// screen is built by [onGenerateRoute] because it is parameterised: a
/// `routes` entry can only match an exact string, so `/workout/:id` needed a
/// RouteFactory. Putting the id in the path rather than a route argument makes
/// the resulting link shareable.
///
/// Falls through to null for anything unrecognised, so Flutter raises its own
/// "unknown route" error instead of this method quietly substituting the wrong
/// screen.
class PlusOneApp extends StatelessWidget {
  const PlusOneApp({super.key, this.provider});

  /// Injected state, or a fresh empty account when null.
  ///
  /// Exists so tests can drive the real application - same routes, same theme -
  /// against known content. Without it a widget test can only ever see the
  /// empty default, which is a state no user ever reaches after signing in.
  final WorkoutProvider? provider;

  /// Every root destination, so a test harness can reuse the app's own route
  /// table instead of maintaining a second one that can drift.
  static Map<String, WidgetBuilder> get routes => {
    for (final tab in AppTab.values) tab.routeName: (_) => AppShell(tab: tab),
  };

  /// Resolves the parameterised workout routes. Null for anything unrecognised,
  /// so Flutter raises its own "unknown route" error instead of this
  /// substituting the wrong screen.
  static Route<dynamic>? routeFor(RouteSettings settings) {
    final name = settings.name;
    if (name == null) return null;

    final segments = name.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final routePrefix = '/${segments.first}';

    switch (routePrefix) {
      case WorkoutDetailScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => WorkoutDetailScreen(route: settings),
          settings: settings,
        );
      case SetLoggingScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => SetLoggingScreen(route: settings),
          settings: settings,
        );
      case WorkoutSummaryScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => WorkoutSummaryScreen(route: settings),
          settings: settings,
        );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = provider;
    final app = MaterialApp(
      title: 'FORM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppTab.home.routeName,
      onGenerateRoute: routeFor,
      routes: routes,
    );

    if (state != null) {
      return ChangeNotifierProvider<WorkoutProvider>.value(
        value: state,
        child: app,
      );
    }

    return ChangeNotifierProvider(create: (_) => WorkoutProvider(), child: app);
  }
}
