import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/account.dart';
import '../models/session.dart';
import 'auth_repository.dart';
import 'credentials.dart';
import 'password_hasher.dart';

/// Holds the identity in the app's own SQLite file.
///
/// The device-local implementation of [AuthRepository]: accounts and the
/// current session are two tables beside the training data, so a backup is
/// still a file copy and the app still works with the radio off. Nothing here
/// reaches the network, and nothing above here knows that.
///
/// The password work happens on a background isolate. At the cost this app
/// chooses, the derivation is long enough to be felt — and synchronously it is
/// worse than slow: the frame that would draw the loading state never gets to
/// run before the work starts, so a sign-in looks like nothing happening until
/// it is over.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._app, {this.hasher = const PasswordHasher()});

  final AppDatabase _app;

  /// Injected so tests can use a cheap cost. The default is the one that ships.
  final PasswordHasher hasher;

  Future<Database> get _db => _app.open();

  /// A verifier that belongs to no account, used when the address given has no
  /// account behind it.
  ///
  /// Sign-in spends the same time whether or not the address exists, so the
  /// time a reply takes does not say which addresses are registered. Its salt
  /// and key are all zeroes: nothing can match it and nothing needs to.
  static const String _noAccountVerifier =
      '${PasswordHasher.scheme}\$${PasswordHasher.defaultIterations}'
      '\$$_zeroSalt\$$_zeroKey';
  static const String _zeroSalt = 'AAAAAAAAAAAAAAAAAAAAAA==';
  static const String _zeroKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

  // --- Reads -----------------------------------------------------------------

  @override
  Future<Session?> restoreSession() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.sessionTable,
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _sessionFromRow(rows.first);
  }

  // --- Writes ----------------------------------------------------------------

  @override
  Future<SignUpOutcome> createAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _requireUsableEmail(email);
    _requireUsablePassword(password);

    final db = await _db;
    final normalised = Credentials.normaliseEmail(email);
    if (await _accountByEmail(db, normalised) != null) {
      throw const AuthException(AuthFailure.emailInUse);
    }

    final account = Account(
      id: _newAccountId(),
      email: normalised,
      displayName: displayName?.trim() ?? '',
      passwordHash: await _hash(password),
      createdAt: DateTime.now(),
    );

    try {
      await db.insert(AppDatabase.accountsTable, _accountToRow(account));
    } on DatabaseException catch (error) {
      // The check above is there to give a good error in the ordinary case;
      // the UNIQUE index is what actually guarantees it. Two taps on "create
      // account" landing together are still one account's problem, not a
      // crash, so this is the same failure and not a rethrow.
      if (error.isUniqueConstraintError()) {
        throw AuthException(AuthFailure.emailInUse, error);
      }
      rethrow;
    }

    return SignedUp(await _writeSession(db, _sessionFor(account)));
  }

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    final db = await _db;
    final account = await _accountByEmail(
      db,
      Credentials.normaliseEmail(email),
    );

    // Both halves are checked against something either way — see
    // [_noAccountVerifier] — and the answer is the same whichever half fails.
    final matched = await _verify(
      password,
      account?.passwordHash ?? _noAccountVerifier,
    );
    if (account == null || !matched) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }

    return _writeSession(db, _sessionFor(account));
  }

  @override
  Future<Session> continueOffline() async {
    final db = await _db;
    return _writeSession(db, Session.device(issuedAt: DateTime.now()));
  }

  @override
  Future<void> signOut() async {
    final db = await _db;
    // The account and its training stay exactly where they are. Signing out is
    // about who is looking, not about what is kept, and deleting either here
    // would make the button unsafe to press.
    await db.delete(AppDatabase.sessionTable);
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    _requireUsablePassword(newPassword);

    final db = await _db;
    final account = await _accountById(db, userId);
    final matched = await _verify(
      currentPassword,
      account?.passwordHash ?? _noAccountVerifier,
    );
    if (account == null || !matched) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }

    await db.update(
      AppDatabase.accountsTable,
      {'passwordHash': await _hash(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> deleteAccount(String userId) async {
    final db = await _db;
    // Everything, in one transaction: the account's own training goes with it,
    // and so does the session that named it — an account that no longer exists
    // with a session still pointing at it is not a state to leave anyone in,
    // and rows left behind would be invisible to every query forever.
    //
    // The training tables come from the schema's own list of what has an owner,
    // so a table added later is deleted rather than orphaned.
    await db.transaction((txn) async {
      for (final table in AppDatabase.accountScopedTables) {
        await txn.delete(table, where: 'userId = ?', whereArgs: [userId]);
      }
      await txn.delete(
        AppDatabase.accountsTable,
        where: 'id = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        AppDatabase.sessionTable,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    });
  }

  // --- Hashing ---------------------------------------------------------------

  Future<String> _hash(String password) => compute(_hashOffIsolate, (
    password: password,
    iterations: hasher.iterations,
  ));

  Future<bool> _verify(String password, String encoded) =>
      compute(_verifyOffIsolate, (password: password, encoded: encoded));

  // --- Rows ------------------------------------------------------------------

  Future<Account?> _accountByEmail(Database db, String email) async {
    final rows = await db.query(
      AppDatabase.accountsTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return rows.isEmpty ? null : _accountFromRow(rows.first);
  }

  Future<Account?> _accountById(Database db, String id) async {
    final rows = await db.query(
      AppDatabase.accountsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _accountFromRow(rows.first);
  }

  /// Replaces the session row, of which there is only ever one.
  Future<Session> _writeSession(Database db, Session session) async {
    await db.delete(AppDatabase.sessionTable);
    await db.insert(AppDatabase.sessionTable, {
      'id': 1,
      'userId': session.userId,
      'email': session.email,
      'displayName': session.displayName,
      'issuedAt': session.issuedAt.millisecondsSinceEpoch,
    });
    return session;
  }

  Session _sessionFor(Account account) => Session(
    userId: account.id,
    issuedAt: DateTime.now(),
    email: account.email,
    displayName: account.displayName,
  );

  static Session _sessionFromRow(Map<String, Object?> row) => Session(
    userId: row['userId']! as String,
    issuedAt: DateTime.fromMillisecondsSinceEpoch(row['issuedAt']! as int),
    email: row['email'] as String?,
    displayName: row['displayName'] as String?,
  );

  static Map<String, Object?> _accountToRow(Account account) => {
    'id': account.id,
    'email': account.email,
    'displayName': account.displayName,
    'passwordHash': account.passwordHash,
    'createdAt': account.createdAt.millisecondsSinceEpoch,
  };

  static Account _accountFromRow(Map<String, Object?> row) => Account(
    id: row['id']! as String,
    email: row['email']! as String,
    displayName: row['displayName']! as String,
    passwordHash: row['passwordHash']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt']! as int),
  );

  // --- Rules -----------------------------------------------------------------

  static void _requireUsableEmail(String email) {
    if (Credentials.emailProblem(email) != null) {
      throw const AuthException(AuthFailure.invalidEmail);
    }
  }

  static void _requireUsablePassword(String password) {
    if (Credentials.passwordProblem(password) != null) {
      throw const AuthException(AuthFailure.weakPassword);
    }
  }

  /// A fresh account id.
  ///
  /// Random rather than sequential. Ids are readable in a store the user can
  /// copy off the device, and `acct_1`, `acct_2` would also tell a reader how
  /// many accounts have ever been made here.
  static String _newAccountId() {
    final random = Random.secure();
    final buffer = StringBuffer('acct_');
    for (var i = 0; i < 16; i++) {
      buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

/// Runs the derivation on a background isolate.
///
/// Top-level because that is what an isolate can be handed: the request travels
/// as a record, which is all the function needs to rebuild an equal hasher on
/// the other side.
String _hashOffIsolate(({String password, int iterations}) request) =>
    PasswordHasher(iterations: request.iterations).hash(request.password);

bool _verifyOffIsolate(({String password, String encoded}) request) =>
    PasswordHasher().verify(request.password, request.encoded);
