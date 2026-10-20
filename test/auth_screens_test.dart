import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/auth/auth_repository.dart';
import 'package:plus_one/providers/auth_provider.dart';
import 'package:plus_one/screens/app_shell.dart';
import 'package:plus_one/screens/sign_up_account_screen.dart';
import 'package:plus_one/screens/sign_up_age_screen.dart';
import 'package:plus_one/screens/sign_up_name_screen.dart';
import 'package:plus_one/screens/sign_in_screen.dart';
import 'package:plus_one/screens/welcome_screen.dart';
import 'package:plus_one/widgets/auth_field.dart';
import 'package:plus_one/widgets/auth_hero.dart';

import 'support/fake_auth.dart';
import 'support/harness.dart';

void main() {
  useOfflineFonts();

  /// The field carrying [label], however the screen has ordered them.
  Finder fieldFor(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(AuthField)),
    matching: find.byType(TextField),
  );

  /// A phone-shaped surface.
  ///
  /// The default test window is 800x600, and these screens are a full-height
  /// hero over a form: at 600 tall the action sits below the fold, which is a
  /// fact about the window rather than about the screen.
  void usePhone(WidgetTester tester, {Size size = const Size(402, 874)}) {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  /// Taps an action on a form, scrolling to it first.
  Future<void> tapAction(WidgetTester tester, String label) async {
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('the welcome screen', () {
    testWidgets('offers all three ways in', (tester) async {
      await tester.pumpWidget(signedOutApp());

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Continue offline'), findsOneWidget);
    });

    testWidgets('opens the sign-in screen', (tester) async {
      await tester.pumpWidget(signedOutApp());

      await tapAction(tester, 'Log in');

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('opens the create-account screen', (tester) async {
      await tester.pumpWidget(signedOutApp());

      await tapAction(tester, 'Create an account');

      expect(find.byType(SignUpNameScreen), findsOneWidget);
    });

    testWidgets('continuing offline goes on to the app itself', (tester) async {
      final auth = AuthProvider(repository: FakeAuth());
      // The app reads the stored session before the first frame; a test that
      // drives the flow has to do the same, or it is looking at a splash.
      await auth.restore();
      await tester.pumpWidget(signedOutApp(auth: auth));

      await tapAction(tester, 'Continue offline');

      // The gate swapped the whole window: no sign-in screen anywhere, and the
      // tabs are up.
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(auth.session?.isGuest, isTrue);
    });
  });

  group('signing in', () {
    late FakeAuth fake;
    late AuthProvider auth;

    Future<void> openSignIn(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(signedOutApp(auth: auth));
      await tapAction(tester, 'Log in');
    }

    setUp(() async {
      fake = FakeAuth();
      auth = AuthProvider(repository: fake);
      await auth.restore();
    });

    testWidgets('an empty form says what is missing, and asks nobody', (
      tester,
    ) async {
      await openSignIn(tester);

      await tapAction(tester, 'Log in');

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(fake.lastEmail, isNull);
    });

    testWidgets('an address that cannot be one is refused before the store', (
      tester,
    ) async {
      await openSignIn(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example');
      await tester.enterText(fieldFor('PASSWORD'), 'one-rep-more');
      await tapAction(tester, 'Log in');

      expect(
        find.text('That does not look like an email address.'),
        findsOneWidget,
      );
      expect(fake.lastEmail, isNull);
    });

    testWidgets('credentials that do not match are reported on the form', (
      tester,
    ) async {
      fake.signInError = const AuthException(AuthFailure.invalidCredentials);
      await openSignIn(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'not-the-password');
      await tapAction(tester, 'Log in');

      expect(
        find.text(
          'That email and password do not match. Check both and try again.',
        ),
        findsOneWidget,
      );
      // Still on the form: a refusal is not a reason to lose what was typed.
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text('not-the-password'), findsOneWidget);
    });

    testWidgets('the right credentials open the app', (tester) async {
      await openSignIn(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'one-rep-more');
      await tapAction(tester, 'Log in');

      expect(fake.lastEmail, 'sam@example.com');
      expect(fake.lastPassword, 'one-rep-more');
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('an address waiting to be confirmed is told what to do', (
      tester,
    ) async {
      // What a store that verifies addresses answers in between: the password
      // is right, and the account is not usable yet.
      fake.signInError = const AuthException(AuthFailure.emailNotConfirmed);
      await openSignIn(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'one-rep-more');
      await tapAction(tester, 'Log in');

      expect(find.textContaining('Confirm your email first'), findsOneWidget);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('shows progress and locks the form while it waits', (
      tester,
    ) async {
      fake.gate = Completer<void>();
      await openSignIn(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'one-rep-more');
      await tester.ensureVisible(find.text('Log in').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log in').last);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // A second tap cannot become a second request.
      final field = tester.widget<TextField>(fieldFor('EMAIL ADDRESS'));
      expect(field.enabled, isFalse);

      fake.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('the eye shows and hides the password', (tester) async {
      await openSignIn(tester);

      expect(find.byTooltip('Show password'), findsOneWidget);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hide password'), findsOneWidget);
      final field = tester.widget<TextField>(fieldFor('PASSWORD'));
      expect(field.obscureText, isFalse);
    });

    testWidgets('links on to creating an account', (tester) async {
      await openSignIn(tester);

      await tapAction(tester, 'Sign up');

      expect(find.byType(SignUpNameScreen), findsOneWidget);
    });

    testWidgets('goes back to the welcome screen', (tester) async {
      await openSignIn(tester);

      await tapAction(tester, 'Back');

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('creating an account', () {
    late FakeAuth fake;
    late AuthProvider auth;

    Future<void> openCreateAccount(WidgetTester tester) async {
      usePhone(tester);
      await tester.pumpWidget(signedOutApp(auth: auth));
      await tapAction(tester, 'Create an account');
    }

    Future<void> fillName(WidgetTester tester) async {
      await tester.enterText(fieldFor('FIRST NAME'), 'Sam');
      await tester.enterText(fieldFor('LAST NAME'), 'Rivera');
    }

    Future<void> continueToAge(WidgetTester tester) async {
      await fillName(tester);
      await tapAction(tester, 'Continue');
    }

    /// Opens a date dropdown and picks one of its entries.
    Future<void> choose(WidgetTester tester, String hint, String value) async {
      // Both the hint and the menu row sit inside a gesture detector, so the
      // text itself is not the hit target; the tap still lands on the button
      // or row, and the caller checks the result. `warnIfMissed` is off for
      // the same reason.
      final button = find.text(hint).last;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The menu item, not the copy the button keeps hidden for its next
      // selection — both carry the same text once a value is chosen.
      final item = find.widgetWithText(DropdownMenuItem<int>, value).last;
      await tester.ensureVisible(item);
      await tester.pumpAndSettle();
      await tester.tap(item, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    /// January 2012 makes the age fourteen today, which is over the floor.
    Future<void> continueToAccount(WidgetTester tester) async {
      await choose(tester, 'Select month', 'January');
      await choose(tester, 'Select day', '1');
      await choose(tester, 'Select year', '2012');
      await tapAction(tester, 'Continue');
    }

    Future<void> reachAccountStep(WidgetTester tester) async {
      await openCreateAccount(tester);
      await continueToAge(tester);
      await continueToAccount(tester);
    }

    setUp(() async {
      fake = FakeAuth();
      auth = AuthProvider(repository: fake);
      await auth.restore();
    });

    testWidgets('the first name is required before the next step', (
      tester,
    ) async {
      await openCreateAccount(tester);

      await tapAction(tester, 'Continue');

      expect(find.text('Tell us your first name.'), findsOneWidget);
      expect(find.byType(SignUpAgeScreen), findsNothing);
    });

    testWidgets('the name survives going back from the age step', (
      tester,
    ) async {
      await openCreateAccount(tester);
      await continueToAge(tester);

      expect(find.byType(SignUpAgeScreen), findsOneWidget);

      await tapAction(tester, 'Back');

      expect(find.byType(SignUpNameScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(fieldFor('FIRST NAME')).controller?.text,
        'Sam',
      );
      expect(
        tester.widget<TextField>(fieldFor('LAST NAME')).controller?.text,
        'Rivera',
      );
    });

    testWidgets('the age step will not continue without a date', (
      tester,
    ) async {
      await openCreateAccount(tester);
      await continueToAge(tester);

      await tapAction(tester, 'Continue');

      expect(find.text('Choose your date of birth.'), findsOneWidget);
      expect(find.byType(SignUpAccountScreen), findsNothing);
    });

    testWidgets('an empty account form says what is missing', (tester) async {
      await reachAccountStep(tester);

      await tapAction(tester, 'Create account');

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Choose a password.'), findsOneWidget);
      expect(fake.lastEmail, isNull);
    });

    testWidgets('a short password says what the floor is', (tester) async {
      await reachAccountStep(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'seven!!');
      await tapAction(tester, 'Create account');

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(fake.lastEmail, isNull);
    });

    testWidgets('an address already taken is refused under the address', (
      tester,
    ) async {
      fake.createError = const AuthException(AuthFailure.emailInUse);
      await reachAccountStep(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'one-rep-more');
      await tapAction(tester, 'Create account');

      expect(
        find.text('That email already has an account. Log in.'),
        findsOneWidget,
      );
      expect(find.byType(SignUpAccountScreen), findsOneWidget);
    });

    testWidgets('both names become the account name', (tester) async {
      await reachAccountStep(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'one-rep-more');
      await tapAction(tester, 'Create account');

      expect(fake.lastDisplayName, 'Sam Rivera');
      expect(fake.lastDateOfBirth, DateTime(2012, 1, 1));
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('a sign-up that needs confirmation says where the link went', (
      tester,
    ) async {
      // What a server-backed store answers when it verifies addresses.
      fake.confirmationRequired = true;
      await reachAccountStep(tester);

      await tester.enterText(fieldFor('EMAIL ADDRESS'), 'sam@example.com');
      await tester.enterText(fieldFor('PASSWORD'), 'one-rep-more');
      await tapAction(tester, 'Create account');

      expect(find.text('CONFIRM YOUR EMAIL.'), findsOneWidget);
      expect(find.textContaining('sam@example.com'), findsOneWidget);
      // Nobody is signed in, so the app has not opened and the form is not
      // claiming the account is ready.
      expect(auth.isSignedIn, isFalse);
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(SignUpAccountScreen), findsOneWidget);

      await tapAction(tester, 'Back to log in');

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('logging in from a later step clears the steps', (
      tester,
    ) async {
      await reachAccountStep(tester);

      await tapAction(tester, 'Log in');

      expect(find.byType(SignInScreen), findsOneWidget);

      // Sign-in replaces the flow rather than sitting on top of it, so back
      // returns to the welcome screen, not to a form for an existing account.
      await tapAction(tester, 'Back');

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('the gate', () {
    testWidgets('holds the splash while the session is being read', (
      tester,
    ) async {
      await tester.pumpWidget(checkingApp());

      // The store has not answered yet, so showing the welcome screen would be
      // a claim about who is signed in that is not known to be true.
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('FORM'), findsOneWidget);
    });

    testWidgets('opens on the app when there is a session', (tester) async {
      final auth = AuthProvider(repository: FakeAuth(session: namedSession()));
      await auth.restore();

      await tester.pumpWidget(signedOutApp(auth: auth));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('opens on the welcome screen when there is not', (
      tester,
    ) async {
      final auth = AuthProvider(repository: FakeAuth());
      await auth.restore();

      await tester.pumpWidget(signedOutApp(auth: auth));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('signing out comes back to the welcome screen', (tester) async {
      final fake = FakeAuth(session: namedSession());
      final auth = AuthProvider(repository: fake);
      await auth.restore();
      await tester.pumpWidget(signedOutApp(auth: auth));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();

      // Nothing of the app is left behind: the whole window was replaced.
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });
  });

  group('on a narrow screen', () {
    testWidgets('every screen in the flow lays out on a 320dp phone', (
      tester,
    ) async {
      usePhone(tester, size: const Size(320, 568));

      final auth = AuthProvider(repository: FakeAuth());
      await auth.restore();
      await tester.pumpWidget(signedOutApp(auth: auth));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Welcome');

      await tapAction(tester, 'Log in');
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Sign in');

      await tapAction(tester, 'Back');
      await tapAction(tester, 'Create an account');
      expect(find.byType(SignUpNameScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Sign-up name');

      await tester.enterText(fieldFor('FIRST NAME'), 'Sam');
      await tapAction(tester, 'Continue');
      expect(find.byType(SignUpAgeScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Sign-up age');

      Future<void> choose(int list, String value) async {
        final button = find.byType(DropdownButton<int>).at(list);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button, warnIfMissed: false);
        await tester.pumpAndSettle();
        final item = find.widgetWithText(DropdownMenuItem<int>, value).last;
        await tester.ensureVisible(item);
        await tester.pumpAndSettle();
        await tester.tap(item, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      await choose(0, 'January');
      await choose(1, '1');
      await choose(2, '2012');
      await tapAction(tester, 'Continue');
      expect(find.byType(SignUpAccountScreen), findsOneWidget);
      // Two labels, two fields and a note on a 568-tall screen: the form
      // scrolls rather than overflowing.
      expect(tester.takeException(), isNull, reason: 'Sign-up account');
    });
  });

  group('the welcome hero', () {
    testWidgets('takes more of a tall screen, where no form fills it', (
      tester,
    ) async {
      usePhone(tester, size: const Size(402, 874));

      final auth = AuthProvider(repository: FakeAuth());
      await auth.restore();
      await tester.pumpWidget(signedOutApp(auth: auth));
      await tester.pumpAndSettle();

      // 56% of the viewport. With no fields between the photograph and the
      // actions, anything less leaves the middle third of the screen empty.
      expect(
        tester.getSize(find.byType(AuthHero)).height,
        moreOrLessEquals(874 * 0.56, epsilon: 0.01),
      );
    });

    testWidgets('keeps the design height on a small phone', (tester) async {
      usePhone(tester, size: const Size(320, 568));

      final auth = AuthProvider(repository: FakeAuth());
      await auth.restore();
      await tester.pumpWidget(signedOutApp(auth: auth));
      await tester.pumpAndSettle();

      // 56% of 568 is just over the floor, so the clamp is what keeps the
      // headline from being pushed under the crop on a short screen.
      expect(
        tester.getSize(find.byType(AuthHero)).height,
        inInclusiveRange(318.0, 320.0),
      );
    });
  });
}
