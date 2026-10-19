import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/main.dart';
import 'package:plus_one/models/session.dart';
import 'package:plus_one/providers/auth_provider.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/app_shell.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'fake_auth.dart';
import 'fixtures.dart';

/// An identity already resolved to the device account.
///
/// Almost every widget test is about a screen, not about signing in, so the
/// sign-in flow is taken as read. Tests about sign-in itself build a provider
/// over a [FakeAuth] and drive it — which is also the only way to make a
/// refusal happen on purpose.
AuthProvider signedInAuth() => AuthProvider.resolved(
  session: Session.device(issuedAt: DateTime(2026, 10, 19)),
);

/// The app, signed in as the device account.
Widget emptyApp() =>
    PlusOneApp(provider: WorkoutProvider(), auth: signedInAuth());

/// An empty account whose provider the test holds a reference to, so it can
/// assert on what the UI did to the store.
Widget emptyAppWith(WorkoutProvider provider) =>
    PlusOneApp(provider: provider, auth: signedInAuth());

/// The app with the seeded sessions behind it, for tests that assert on a
/// populated screen.
///
/// Every widget test has to choose which of the two it is running, because the
/// application ships no sample data. Leaving that implicit is what let four
/// tests pass against fixtures the app itself no longer had.
Widget seededApp({DateTime? today}) => PlusOneApp(
  provider: seededProvider(today: today),
  auth: signedInAuth(),
);

/// The app on its first launch: nobody signed in, the store behind the sign-in
/// screens held by the test so it can be driven.
Widget signedOutApp({AuthProvider? auth}) => PlusOneApp(
  provider: WorkoutProvider(),
  auth: auth ?? AuthProvider.resolved(),
);

/// The app as it starts, with the session still being read.
///
/// The store never answers, so the gate stays on its splash — which is the one
/// state a test cannot otherwise hold still.
Widget checkingApp({AuthProvider? auth}) => PlusOneApp(
  provider: WorkoutProvider(),
  auth: auth ?? AuthProvider(repository: FakeAuth()),
);

/// The real [AppShell] around a provider of the test's choosing.
///
/// Uses the app's own routes and theme rather than a bare MaterialApp, so a
/// test cannot pass here and fail in the app because of a different navigator
/// or route table.
Widget shellWith(WorkoutProvider provider) =>
    ChangeNotifierProvider<WorkoutProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.light(),
        onGenerateRoute: PlusOneApp.routeFor,
        routes: PlusOneApp.routes,
      ),
    );

/// Runs [body] with google_fonts offline.
///
/// Fonts are fetched over the network at runtime otherwise, which makes the
/// suite slow and flaky in CI. The platform fallback is enough to assert
/// layout, and none of these tests measure glyph shapes.
void useOfflineFonts() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}
