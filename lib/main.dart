import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'auth/local_auth_repository.dart';
import 'data/app_database.dart';
import 'data/workout_repository.dart';
import 'models/session.dart';
import 'navigation/app_tab.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/app_shell.dart';
import 'screens/create_account_screen.dart';
import 'screens/set_logging_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/workout_summary_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inter and Barlow Condensed ship in assets/fonts, so the first frame must
  // never wait on fonts.gstatic.com. Leaving this on would trade the download
  // the app already paid for against a request on someone's metered connection
  // every launch, and a font that fails to arrive renders the app in the wrong
  // face. See pubspec.yaml for the files and their weights.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Whoever is signed in is read first, and on purpose: it decides which
  // account's training the next line reads. Both answers are in before the
  // first frame, so a relaunch opens on the screen the user left behind rather
  // than on a welcome screen that a moment later turns out to be wrong.
  final database = AppDatabase();
  final auth = AuthProvider(repository: LocalAuthRepository(database));
  final provider = WorkoutProvider(
    repository: WorkoutRepository(database, userId: Session.deviceUserId),
  );

  await auth.restore();
  await provider.load();

  runApp(PlusOneApp(provider: provider, auth: auth));
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
  const PlusOneApp({super.key, this.provider, this.auth});

  /// Injected state, or a fresh empty account when null.
  ///
  /// [main] passes a provider backed by the SQLite store; null - the default
  /// in tests - gets one that reads and writes nothing.
  ///
  /// Exists so tests can drive the real application - same routes, same theme -
  /// against known content. Without it a widget test can only ever see the
  /// empty default, which is a state no user ever reaches after signing in.
  final WorkoutProvider? provider;

  /// Who is signed in, or null for a resolved "nobody" with no store behind it.
  ///
  /// Injected for the same reason as [provider]: a widget test about a screen
  /// wants the shell, not a sign-in flow.
  final AuthProvider? auth;

  /// Every root destination, so a test harness can reuse the app's own route
  /// table instead of maintaining a second one that can drift.
  static Map<String, WidgetBuilder> get routes => {
    for (final tab in AppTab.values) tab.routeName: (_) => AppShell(tab: tab),
  };

  /// The sign-in flow's destinations.
  ///
  /// Separate from [routes] because none of them is reachable once there is a
  /// session, and the flow is a navigator of its own — see [_Gate].
  static Map<String, WidgetBuilder> get signInRoutes => {
    SignInScreen.routeName: (_) => const SignInScreen(),
    CreateAccountScreen.routeName: (_) => const CreateAccountScreen(),
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

  /// The application window, so both sides of the gate share one title and one
  /// theme rather than each declaring their own.
  ///
  /// [key] is what makes the two sides distinct widgets rather than the same
  /// widget showing something else: without it Flutter reuses the element —
  /// and with it the Navigator and every route on its stack — so signing in
  /// would leave the sign-in screens underneath and signing out would leave the
  /// app's screens underneath.
  static MaterialApp _window({
    Key? key,
    Widget? home,
    String? initialRoute,
    Map<String, WidgetBuilder> routes = const {},
    RouteFactory? onGenerateRoute,
  }) {
    return MaterialApp(
      key: key,
      title: 'FORM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: home,
      initialRoute: initialRoute,
      routes: routes,
      onGenerateRoute: onGenerateRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = provider;
    final identity = auth;

    return MultiProvider(
      providers: [
        if (identity != null)
          ChangeNotifierProvider<AuthProvider>.value(value: identity)
        else
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider.resolved(),
          ),
        if (state != null)
          ChangeNotifierProvider<WorkoutProvider>.value(value: state)
        else
          ChangeNotifierProvider<WorkoutProvider>(
            create: (_) => WorkoutProvider(),
          ),
      ],
      child: const _Gate(),
    );
  }
}

/// Chooses between the sign-in flow and the app itself.
///
/// A gate rather than a redirect: redirecting would leave the sign-in screens
/// on the stack behind the app, and signing out would then reveal the last of
/// them instead of starting over. Swapping the whole window gives each side its
/// own navigator, so signing out cannot leave anything of the session's behind.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isSignedIn) {
      return PlusOneApp._window(
        key: const ValueKey('sign-in'),
        home: const _SignInHome(),
        routes: PlusOneApp.signInRoutes,
      );
    }

    return PlusOneApp._window(
      key: const ValueKey('app'),
      initialRoute: AppTab.home.routeName,
      routes: PlusOneApp.routes,
      onGenerateRoute: PlusOneApp.routeFor,
    );
  }
}

/// The sign-in flow's own home.
///
/// While the stored session is still being read this is a splash rather than
/// the welcome screen: a launch that turns out to have a session would
/// otherwise show somebody the sign-in screen and then take it away, which
/// looks exactly like having been signed out.
class _SignInHome extends StatelessWidget {
  const _SignInHome();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isResolved ? const WelcomeScreen() : const _SessionSplash();
  }
}

/// The brand while the session is being read.
///
/// The same mark the native splash leaves on screen, so the hand-off to the
/// first frame is a continuation rather than a flash of something else.
class _SessionSplash extends StatelessWidget {
  const _SessionSplash();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FORM',
              style: context.text.exerciseName.copyWith(
                fontSize: 40,
                letterSpacing: -1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
