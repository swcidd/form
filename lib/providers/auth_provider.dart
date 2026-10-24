import 'package:flutter/foundation.dart';

import '../auth/auth_repository.dart';
import '../models/session.dart';

/// Where the app stands with sign-in.
enum AuthStatus {
  /// The stored session is still being read. Before that answer arrives there
  /// is nothing honest to show but a splash: showing the welcome screen and
  /// then replacing it would flash a decision at somebody who is signed in.
  checking,

  signedOut,

  signedIn,
}

/// What the UI knows about who is signed in.
///
/// Screens read [status], [session] and [busy], and call the verbs; the
/// provider holds no copy of anyone's training, which is
/// [WorkoutProvider]'s job — this only answers who is looking.
///
/// Failures are thrown, not stored. The same failure reads differently on a
/// sign-in screen than in a settings sheet ("that password is not right"
/// against "that is not your current password"), so the words belong to the
/// screen and this hands it the reason.
class AuthProvider extends ChangeNotifier {
  /// Asks [repository] who is signed in — on [restore].
  AuthProvider({required this.repository}) : _status = AuthStatus.checking;

  /// Already resolved, with no store behind it.
  ///
  /// For widget tests whose subject is a screen rather than sign-in itself, and
  /// for a preview. The verbs refuse rather than pretend: there is nothing here
  /// to sign anyone in with.
  AuthProvider.resolved({Session? session})
    : repository = null,
      _session = session,
      _status = session == null ? AuthStatus.signedOut : AuthStatus.signedIn;

  /// Where the identity lives, or null when this provider was handed an answer
  /// rather than asked for one.
  final AuthRepository? repository;

  Session? _session;
  AuthStatus _status;
  bool _busy = false;

  AuthStatus get status => _status;

  /// Who is signed in, or null for nobody.
  Session? get session => _session;

  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// Whether there is an answer yet. False only while [restore] is running.
  bool get isResolved => _status != AuthStatus.checking;

  /// Whether an account operation is in flight, so a screen can disable its
  /// form and show a spinner instead of letting a second tap through.
  bool get busy => _busy;

  /// Reads the stored session. Called before the first frame.
  ///
  /// A store that cannot be read leaves the app signed out rather than broken:
  /// somebody who cannot get at their account has a working app that can make
  /// another, which is better than a crash on launch.
  Future<void> restore() async {
    final repository = this.repository;
    if (repository == null) return;

    try {
      _apply(await repository.restoreSession());
    } catch (error) {
      debugPrint('Could not read the session, starting signed out: $error');
      _apply(null);
    }
  }

  /// Registers an account.
  ///
  /// Returns what came of it — [SignedUp] when there is a session now,
  /// [ConfirmationSent] when the store wants the address confirmed first, in
  /// which case nobody is signed in yet. Throws [AuthException] — see
  /// [AuthRepository.createAccount] — for everything that can be wrong with
  /// what was typed.
  Future<SignUpOutcome> createAccount({
    required String email,
    required String password,
    String? displayName,
    int? age,
    double? heightCm,
    double? weightKg,
  }) async {
    final outcome = await _run(
      () => _auth.createAccount(
        email: email,
        password: password,
        displayName: displayName,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
      ),
    );
    if (outcome case SignedUp(:final session)) _apply(session);
    return outcome;
  }

  /// Signs an existing account in. Throws [AuthException].
  Future<void> signIn({required String email, required String password}) =>
      _run(
        () async =>
            _apply(await _auth.signIn(email: email, password: password)),
      );

  /// Keeps using the app without an account.
  Future<void> continueOffline() =>
      _run(() async => _apply(await _auth.continueOffline()));

  /// Ends the session. The account and its training stay put.
  Future<void> signOut() => _run(() async {
    await _auth.signOut();
    _apply(null);
  });

  /// Replaces the password of whoever is signed in. Throws [AuthException].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _run(
    () async => _auth.changePassword(
      userId: _requireSession().userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  /// Deletes the signed-in account and everything attributed to it.
  Future<void> deleteAccount() => _run(() async {
    await _auth.deleteAccount(_requireSession().userId);
    _apply(null);
  });

  /// Records who is signed in and tells the UI.
  void _apply(Session? session) {
    _session = session;
    _status = session == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  /// Runs one operation with [busy] held around it.
  ///
  /// In a `finally`, so a refusal does not leave the form disabled for good —
  /// a validator that can wedge the screen is worse than the mistake it caught.
  ///
  /// Generic because a verb can have an answer worth returning — a sign-up
  /// says whether it produced a session — and dropping that answer to fit a
  /// `void` would push the same knowledge into a field.
  Future<T> _run<T>(Future<T> Function() operation) async {
    _busy = true;
    notifyListeners();
    try {
      return await operation();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  AuthRepository get _auth {
    final repository = this.repository;
    if (repository == null) {
      throw StateError('This provider was given a session, not a store.');
    }
    return repository;
  }

  Session _requireSession() {
    final session = _session;
    if (session == null) {
      throw StateError('Nobody is signed in.');
    }
    return session;
  }
}
