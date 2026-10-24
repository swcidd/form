import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/auth/auth_repository.dart';
import 'package:plus_one/auth/local_auth_repository.dart';
import 'package:plus_one/auth/password_hasher.dart';
import 'package:plus_one/data/app_database.dart';
import 'package:plus_one/data/workout_repository.dart';
import 'package:plus_one/models/session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/sign_up.dart';

void main() {
  // sqflite's default factory talks to the platform channel, which does not
  // exist in the test VM. The FFI build runs the real SQLite engine, so the
  // schema, the constraints and the SQL are genuinely under test.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase app;
  late LocalAuthRepository auth;

  setUp(() async {
    app = AppDatabase();
    // A cheap cost, so the suite is not paying the shipping one a few dozen
    // times: what the cost buys is the subject of password_hasher_test.
    auth = LocalAuthRepository(
      app,
      hasher: const PasswordHasher(iterations: 50),
    );
    await app.open(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await app.close();
  });

  /// The failure an operation threw, so a test can name what it expects rather
  /// than matching on a string.
  Future<AuthFailure> failureOf(Future<void> Function() operation) async {
    try {
      await operation();
    } on AuthException catch (error) {
      return error.failure;
    }
    fail('expected the operation to be refused');
  }

  group('a fresh install', () {
    test('is signed in to nobody', () async {
      expect(await auth.restoreSession(), isNull);
    });

    test('keeps using the app offline under one device account', () async {
      final session = await auth.continueOffline();

      expect(session.userId, Session.deviceUserId);
      expect(session.isGuest, isTrue);
      expect(session.email, isNull);
      // And it survives a restart, or "continue offline" would be a decision
      // the app forgets every time it is closed.
      expect(await auth.restoreSession(), isNotNull);
    });
  });

  group('creating an account', () {
    test('signs the new account in', () async {
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      expect(session.email, 'sam@example.com');
      expect(session.isGuest, isFalse);
      expect(session.userId, startsWith('acct_'));
      // The id is an id, not the address it belongs to: it is written into
      // every row this account goes on to train.
      expect(session.userId, isNot(contains('example')));
      expect((await auth.restoreSession())?.userId, session.userId);
    });

    test('seeds the profile with the sign-up measurements', () async {
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
        displayName: 'Sam Rivera',
        age: 24,
        heightCm: 178,
        weightKg: 75,
      );

      final profile = await WorkoutRepository(
        app,
        userId: session.userId,
      ).loadProfile();
      expect(profile?.name, 'Sam Rivera');
      expect(profile?.age, 24);
      expect(profile?.heightCm, 178);
      expect(profile?.weightKg, 75);
    });

    test('answers with a session, because nothing needs confirming', () async {
      final outcome = await auth.createAccount(
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      // The device is the authority on its own accounts, so there is no inbox
      // for a link to arrive in: the sign-up is also the sign-in.
      expect(outcome, isA<SignedUp>());
      expect((outcome as SignedUp).session.email, 'sam@example.com');
    });

    test('stores a verifier and not the password', () async {
      await signUp(auth, email: 'sam@example.com', password: 'one-rep-more');

      final db = await app.open();
      final row = (await db.query(AppDatabase.accountsTable)).single;
      final stored = row['passwordHash']! as String;

      expect(stored, isNot(contains('one-rep-more')));
      expect(stored, startsWith(PasswordHasher.scheme));
    });

    test(
      'normalises the address, so it is found however it is typed',
      () async {
        final session = await signUp(
          auth,
          email: '  Sam@Example.COM ',
          password: 'one-rep-more',
        );

        expect(session.email, 'sam@example.com');
        // The spelling is what the person typed; the account is what it means.
        expect(
          (await auth.signIn(
            email: 'SAM@example.com',
            password: 'one-rep-more',
          )).userId,
          session.userId,
        );
      },
    );

    test('refuses an address that already has an account', () async {
      await signUp(auth, email: 'sam@example.com', password: 'one-rep-more');

      expect(
        await failureOf(
          () => auth.createAccount(
            email: 'Sam@Example.com',
            password: 'a-different-one',
          ),
        ),
        AuthFailure.emailInUse,
      );
    });

    test('refuses an address that cannot be one', () async {
      for (final email in ['', '   ', 'sam', 'sam@example', '@example.com']) {
        expect(
          await failureOf(
            () => signUp(auth, email: email, password: 'one-rep-more'),
          ),
          AuthFailure.invalidEmail,
          reason: 'should refuse "$email"',
        );
      }
    });

    test('refuses a password under the floor', () async {
      for (final password in ['', 'short', 'seven!!']) {
        expect(
          await failureOf(
            () => auth.createAccount(
              email: 'sam@example.com',
              password: password,
            ),
          ),
          AuthFailure.weakPassword,
          reason: 'should refuse "$password"',
        );
      }
    });

    test('gives two accounts two ids', () async {
      final first = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );
      final second = await signUp(
        auth,
        email: 'alex@example.com',
        password: 'one-rep-more',
      );

      expect(first.userId, isNot(second.userId));
    });

    test('keeps a name, and falls back to the address', () async {
      final named = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
        displayName: '  Sam  ',
      );
      final unnamed = await signUp(
        auth,
        email: 'alex@example.com',
        password: 'one-rep-more',
      );

      expect(named.name, 'Sam');
      expect(unnamed.name, 'alex');
    });
  });

  group('signing in', () {
    test('with the right password returns the account', () async {
      final created = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );
      await auth.signOut();

      final session = await auth.signIn(
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      expect(session.userId, created.userId);
      expect(session.email, 'sam@example.com');
    });

    test('with the wrong password is refused', () async {
      await signUp(auth, email: 'sam@example.com', password: 'one-rep-more');

      expect(
        await failureOf(
          () => auth.signIn(email: 'sam@example.com', password: 'one-rep-les'),
        ),
        AuthFailure.invalidCredentials,
      );
      // And it did not sign anybody in on the way past.
      expect(await auth.restoreSession(), isNotNull);
    });

    test('with an address nobody registered fails the same way', () async {
      await signUp(auth, email: 'sam@example.com', password: 'one-rep-more');

      // The same failure as a wrong password on purpose: telling the two apart
      // would turn the sign-in screen into a way of finding out which
      // addresses have accounts.
      expect(
        await failureOf(
          () => auth.signIn(
            email: 'nobody@example.com',
            password: 'one-rep-more',
          ),
        ),
        AuthFailure.invalidCredentials,
      );
    });

    test('a damaged verifier is a refusal, not a crash', () async {
      await signUp(auth, email: 'sam@example.com', password: 'one-rep-more');
      final db = await app.open();
      await db.update(AppDatabase.accountsTable, {
        'passwordHash': 'half a row',
      });

      expect(
        await failureOf(
          () => auth.signIn(email: 'sam@example.com', password: 'one-rep-more'),
        ),
        AuthFailure.invalidCredentials,
      );
    });
  });

  group('signing out', () {
    test('ends the session and keeps the account', () async {
      await signUp(auth, email: 'sam@example.com', password: 'one-rep-more');

      await auth.signOut();

      expect(await auth.restoreSession(), isNull);
      // Signing out is about who is looking, not about what is kept.
      expect(
        (await auth.signIn(
          email: 'sam@example.com',
          password: 'one-rep-more',
        )).isGuest,
        isFalse,
      );
    });
  });

  group('changing a password', () {
    test('takes the current one and swaps which password works', () async {
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      await auth.changePassword(
        userId: session.userId,
        currentPassword: 'one-rep-more',
        newPassword: 'two-reps-more',
      );
      await auth.signOut();

      expect(
        await failureOf(
          () => auth.signIn(email: 'sam@example.com', password: 'one-rep-more'),
        ),
        AuthFailure.invalidCredentials,
        reason: 'the old password should be gone',
      );
      expect(
        (await auth.signIn(
          email: 'sam@example.com',
          password: 'two-reps-more',
        )).userId,
        session.userId,
      );
    });

    test('refuses a wrong current password', () async {
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      expect(
        await failureOf(
          () => auth.changePassword(
            userId: session.userId,
            currentPassword: 'not-it-at-all',
            newPassword: 'two-reps-more',
          ),
        ),
        AuthFailure.invalidCredentials,
      );
    });

    test('refuses a new password under the floor', () async {
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      expect(
        await failureOf(
          () => auth.changePassword(
            userId: session.userId,
            currentPassword: 'one-rep-more',
            newPassword: 'short',
          ),
        ),
        AuthFailure.weakPassword,
      );
    });
  });

  group('deleting an account', () {
    test('takes the account and the session with it', () async {
      final session = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );

      await auth.deleteAccount(session.userId);

      expect(await auth.restoreSession(), isNull);
      expect(
        await failureOf(
          () => auth.signIn(email: 'sam@example.com', password: 'one-rep-more'),
        ),
        AuthFailure.invalidCredentials,
      );
    });

    test('leaves the other accounts alone', () async {
      final first = await signUp(
        auth,
        email: 'sam@example.com',
        password: 'one-rep-more',
      );
      final second = await signUp(
        auth,
        email: 'alex@example.com',
        password: 'one-rep-more',
      );

      // The second sign-up is the one that is signed in, so this is the
      // deletion that has to end a session on the way past.
      await auth.deleteAccount(second.userId);

      expect(await auth.restoreSession(), isNull);
      // But the other account is not collateral damage.
      expect(
        (await auth.signIn(
          email: 'sam@example.com',
          password: 'one-rep-more',
        )).userId,
        first.userId,
      );
    });
  });
}
