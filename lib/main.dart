import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'auth/local_auth_repository.dart';
import 'data/app_database.dart';
import 'data/workout_repository.dart';
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
  // account's training the app opens on, and a launch that showed the sign-in
  // screen before taking it away would look exactly like having been signed
  // out. The training itself is read behind the gate's splash, which is on
  // screen by then - see [_StoreWindow].
  final database = AppDatabase();
  final auth = AuthProvider(repository: LocalAuthRepository(database));

  await auth.restore();

  runApp(
    PlusOneApp(
      auth: auth,
      openStore: (userId) => WorkoutProvider(
        repository: WorkoutRepository(database, userId: userId),
      ),
    ),
  );
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
  const PlusOneApp({super.key, this.openStore, this.auth});

  /// Builds the store for one account, whoever is signed in.
  ///
  /// A function rather than a provider, because a session belongs to an
  /// account: the app calls this with the id the session names, so signing in
  /// as somebody else opens their training and the previous account's copy goes
  /// with the widget that held it. [main] passes the SQLite one; null - the
  /// default in tests - gets accounts that read and write nothing.
  ///
  /// The app takes ownership of what this returns and disposes it.
  final WorkoutProvider Function(String userId)? openStore;

  /// Who is signed in, or null for a resolved "nobody" with no store behind it.
  ///
  /// Injected for the same reason as [openStore]: a widget test about a screen
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
    final identity = auth;

    return MultiProvider(
      providers: [
        if (identity != null)
          ChangeNotifierProvider<AuthProvider>.value(value: identity)
        else
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider.resolved(),
          ),
      ],
      child: _Gate(openStore: openStore),
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
  const _Gate({this.openStore});

  /// Builds the store for the signed-in account, or null in a test that has no
  /// store behind the app.
  final WorkoutProvider Function(String userId)? openStore;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = auth.session;

    if (session == null) {
      return PlusOneApp._window(
        key: const ValueKey('sign-in'),
        home: const _SignInHome(),
        routes: PlusOneApp.signInRoutes,
      );
    }

    // One store per account, keyed on whose it is: signing in as somebody else
    // builds theirs and disposes the copy the previous account was reading,
    // rather than letting two accounts' sessions share one object.
    final open = openStore ?? (_) => WorkoutProvider();

    return ChangeNotifierProvider<WorkoutProvider>(
      key: ValueKey(session.userId),
      create: (_) {
        final store = open(session.userId);
        unawaited(store.load());
        return store;
      },
      child: const _StoreWindow(),
    );
  }
}

/// The app's window, held on the splash until the account's training is read.
///
/// Every screen behind the gate reads counts off the store, and one that has not
/// read yet is an empty account: showing it would put a true-looking "0 sessions
/// this week" in front of somebody who has twenty. The splash is the one the
/// session check uses, so the two waits look like a single one.
class _StoreWindow extends StatelessWidget {
  const _StoreWindow();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutProvider>();

    if (!store.isLoaded) {
      return PlusOneApp._window(
        key: const ValueKey('opening'),
        home: const _SessionSplash(),
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
