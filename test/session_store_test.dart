import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/data/app_database.dart';
import 'package:plus_one/data/workout_repository.dart';
import 'package:plus_one/main.dart';
import 'package:plus_one/providers/auth_provider.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/app_shell.dart';
import 'package:plus_one/screens/welcome_screen.dart';

import 'support/fake_auth.dart';
import 'support/harness.dart';

/// Which account's training the app opens on.
///
/// The store belongs to an account, so the app has to build one for whoever the
/// session names rather than for the device or for whoever was here last. These
/// drive the gate and watch which stores it asks for; the store's own contents
/// are [WorkoutRepository]'s business and are tested against a real database.
void main() {
  useOfflineFonts();

  /// The accounts the app asked for a store for, in order.
  late List<String> opened;

  /// The stores it was given, so the test can see them being replaced.
  late List<WorkoutProvider> stores;

  late FakeAuth fake;
  late AuthProvider auth;

  setUp(() async {
    opened = [];
    stores = [];
    fake = FakeAuth(session: namedSession());
    auth = AuthProvider(repository: fake);
    await auth.restore();
  });

  /// The app, handing out a fresh in-memory store per account and remembering
  /// which account it was asked for.
  Widget app() => PlusOneApp(
    auth: auth,
    openStore: (userId) {
      opened.add(userId);
      final store = WorkoutProvider();
      stores.add(store);
      return store;
    },
  );

  testWidgets('opens a store for the account the session names', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(opened, ['acct_1']);
  });

  testWidgets('opens no store while nobody is signed in', (tester) async {
    auth = AuthProvider.resolved();

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('holds the app window back until the store has been read', (
    tester,
  ) async {
    // A store that cannot be read here: widget tests run without a database
    // factory, so this is what "the read has not answered yet" looks like from
    // the gate's side. The question is only whether the window opens before the
    // answer, and a read that fails is still an answer arriving late.
    await tester.pumpWidget(
      PlusOneApp(
        auth: auth,
        openStore: (_) => WorkoutProvider(
          repository: WorkoutRepository(AppDatabase(), userId: 'acct_1'),
        ),
      ),
    );

    // The first frame, with the read still out. Every screen behind the gate
    // reads counts off the store, so the shell now would be an empty account
    // with a true-looking zero on it.
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // And an unreadable store is still an app: it opens on an empty account
    // rather than on a splash that never leaves.
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('signing in as somebody else opens their store', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(opened, ['acct_1']);
    final first = stores.single;

    await auth.signOut();
    await tester.pumpAndSettle();

    // Signing out takes the app window with it, and the store goes with the
    // widget that held it rather than being left listening for a session that
    // has ended.
    expect(find.byType(AppShell), findsNothing);
    expect(() {
      first.addListener(() {});
    }, throwsFlutterError);

    fake.session = namedSession(id: 'acct_2', email: 'alex@example.com');
    await auth.signIn(email: 'alex@example.com', password: 'one-rep-more');
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(opened, ['acct_1', 'acct_2']);
    expect(stores.last, isNot(same(first)));
  });
}
