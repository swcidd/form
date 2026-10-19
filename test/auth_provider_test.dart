import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/auth/auth_repository.dart';
import 'package:plus_one/models/session.dart';
import 'package:plus_one/providers/auth_provider.dart';

import 'support/fake_auth.dart';

void main() {
  late FakeAuth fake;
  late AuthProvider auth;

  setUp(() {
    fake = FakeAuth();
    auth = AuthProvider(repository: fake);
  });

  test('starts out not knowing, so no screen shows a decision yet', () {
    expect(auth.status, AuthStatus.checking);
    expect(auth.isResolved, isFalse);
    expect(auth.isSignedIn, isFalse);
    expect(auth.session, isNull);
    expect(auth.repository, same(fake));
  });

  group('restoring', () {
    test('lands signed out when the store holds no session', () async {
      await auth.restore();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.isResolved, isTrue);
      expect(fake.restoreCount, 1);
    });

    test('lands signed in when the store holds one', () async {
      fake.session = namedSession();

      await auth.restore();

      expect(auth.isSignedIn, isTrue);
      expect(auth.session?.email, 'sam@example.com');
      expect(auth.busy, isFalse);
    });

    test('a store that cannot be read is signed out, not broken', () async {
      fake.restoreError = StateError('the file is gone');

      await auth.restore();

      // Somebody who cannot get at their account should still have a working
      // app that lets them make another.
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.session, isNull);
    });

    test('tells the UI as soon as there is an answer', () async {
      var notifications = 0;
      auth.addListener(() => notifications++);

      await auth.restore();

      expect(notifications, 1);
    });
  });

  group('signing in', () {
    test(
      'hands the credentials to the store and comes back signed in',
      () async {
        await auth.signIn(email: 'sam@example.com', password: 'one-rep-more');

        expect(fake.lastEmail, 'sam@example.com');
        expect(fake.lastPassword, 'one-rep-more');
        expect(auth.isSignedIn, isTrue);
        expect(auth.session?.userId, 'acct_1');
      },
    );

    test('passes a refusal on and leaves the app signed out', () async {
      await auth.restore();
      fake.signInError = const AuthException(AuthFailure.invalidCredentials);

      await expectLater(
        auth.signIn(email: 'sam@example.com', password: 'nope'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.invalidCredentials,
          ),
        ),
      );

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.session, isNull);
    });

    test('keeps the form free to try again after a refusal', () async {
      fake.signInError = const AuthException(AuthFailure.invalidCredentials);

      await expectLater(
        auth.signIn(email: 'sam@example.com', password: 'nope'),
        throwsA(isA<AuthException>()),
      );

      // A busy flag left standing after a failure would disable the button
      // that has to be pressed to fix the mistake.
      expect(auth.busy, isFalse);
    });

    test('creating an account signs the new one in', () async {
      await auth.createAccount(
        email: 'sam@example.com',
        password: 'one-rep-more',
        displayName: 'Sam',
      );

      expect(auth.isSignedIn, isTrue);
      expect(auth.session?.name, 'Sam');
      expect(auth.session?.isGuest, isFalse);
    });

    test('continuing offline signs in as the device account', () async {
      await auth.continueOffline();

      expect(auth.isSignedIn, isTrue);
      expect(auth.session?.isGuest, isTrue);
      expect(auth.session?.userId, Session.deviceUserId);
    });
  });

  group('signing out', () {
    test('ends the session and asks nothing else of the store', () async {
      fake.session = namedSession();
      await auth.restore();

      await auth.signOut();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.session, isNull);
      expect(fake.signOutCount, 1);
    });
  });

  group('the account behind the session', () {
    setUp(() async {
      fake.session = namedSession(id: 'acct_7');
      await auth.restore();
    });

    test('changing a password names the account that is signed in', () async {
      await auth.changePassword(
        currentPassword: 'one-rep-more',
        newPassword: 'two-reps-more',
      );

      expect(fake.lastUserId, 'acct_7');
      expect(fake.lastCurrentPassword, 'one-rep-more');
      expect(fake.lastNewPassword, 'two-reps-more');
      // Still signed in: a password change does not end the session.
      expect(auth.isSignedIn, isTrue);
    });

    test('a wrong current password is passed on and changes nothing', () async {
      fake.changeError = const AuthException(AuthFailure.invalidCredentials);

      await expectLater(
        auth.changePassword(
          currentPassword: 'nope',
          newPassword: 'two-reps-more',
        ),
        throwsA(isA<AuthException>()),
      );

      expect(auth.isSignedIn, isTrue);
      expect(auth.busy, isFalse);
    });

    test('deleting an account ends the session', () async {
      await auth.deleteAccount();

      expect(fake.lastUserId, 'acct_7');
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.session, isNull);
    });
  });

  test('nobody signed in means no account to act on', () async {
    await auth.restore();

    // A programming error rather than something a user can cause: the screens
    // that call these are only reachable while signed in.
    await expectLater(auth.deleteAccount(), throwsA(isA<StateError>()));
    expect(auth.busy, isFalse);
  });

  group('busy', () {
    test('is held for the length of an operation', () async {
      fake.gate = Completer<void>();

      final pending = auth.signIn(
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      // A tap that takes a moment has to disable the button, or the second tap
      // is a second attempt.
      await Future<void>.delayed(Duration.zero);
      expect(auth.busy, isTrue);

      fake.gate!.complete();
      await pending;

      expect(auth.busy, isFalse);
      expect(auth.isSignedIn, isTrue);
    });

    test('is announced, so the form can redraw either way', () async {
      var notifications = 0;
      auth.addListener(() => notifications++);
      fake.gate = Completer<void>();

      final pending = auth.continueOffline();
      await Future<void>.delayed(Duration.zero);
      expect(auth.busy, isTrue);
      final whileBusy = notifications;
      expect(whileBusy, greaterThanOrEqualTo(1));

      fake.gate!.complete();
      await pending;

      // Clearing it has to be announced too, or the form stays disabled for
      // good after the operation it was waiting on finished.
      expect(auth.busy, isFalse);
      expect(notifications, greaterThan(whileBusy));
    });
  });

  group('a provider handed an answer rather than a store', () {
    test('reports it straight away, without a startup check', () {
      final resolved = AuthProvider.resolved(session: namedSession());

      expect(resolved.status, AuthStatus.signedIn);
      expect(resolved.isResolved, isTrue);
      expect(resolved.repository, isNull);
    });

    test('starts signed out when handed nothing', () {
      expect(AuthProvider.resolved().status, AuthStatus.signedOut);
    });

    test('refuses to act, rather than pretending', () async {
      final resolved = AuthProvider.resolved(session: namedSession());

      await expectLater(
        resolved.signIn(email: 'sam@example.com', password: 'one-rep-more'),
        throwsA(isA<StateError>()),
      );
      // Nothing to read, so nothing to wait for.
      await resolved.restore();
      expect(resolved.isSignedIn, isTrue);
    });
  });
}
