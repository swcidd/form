import 'dart:async';

import 'package:plus_one/auth/auth_repository.dart';
import 'package:plus_one/models/session.dart';

/// A session belonging to a named account.
Session namedSession({
  String id = 'acct_1',
  String email = 'sam@example.com',
}) => Session(userId: id, issuedAt: DateTime(2026, 10, 19), email: email);

/// An identity that lives in memory.
///
/// It is also the point of the seam: everything above [AuthRepository] works
/// against this exactly as it would against a server, so the tests that use it
/// are exercising the code a server-backed implementation would run.
///
/// Failures are set as fields rather than configured per call, because a test
/// that has to say *which* call fails is a test that has decided too much.
class FakeAuth implements AuthRepository {
  FakeAuth({this.session});

  /// The session a restore finds, and the one every verb signs in as.
  Session? session;

  Object? restoreError;
  AuthException? signInError;
  AuthException? createError;
  AuthException? changeError;

  /// Holds every verb open, so a test can look at a screen mid-request.
  Completer<void>? gate;

  int restoreCount = 0;
  int signOutCount = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastDisplayName;
  DateTime? lastDateOfBirth;
  String? lastUserId;
  String? lastCurrentPassword;
  String? lastNewPassword;

  Future<void> _hold() async {
    final gate = this.gate;
    if (gate != null) await gate.future;
  }

  @override
  Future<Session?> restoreSession() async {
    restoreCount++;
    final error = restoreError;
    if (error != null) throw error;
    return session;
  }

  /// Whether a sign-up has to be confirmed by email before it can be used —
  /// the answer a server-backed store gives by default.
  bool confirmationRequired = false;

  @override
  Future<SignUpOutcome> createAccount({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
  }) async {
    await _hold();
    final error = createError;
    if (error != null) throw error;
    lastEmail = email;
    lastPassword = password;
    lastDisplayName = displayName;
    lastDateOfBirth = dateOfBirth;
    if (confirmationRequired) return ConfirmationSent(email);
    return SignedUp(
      session = Session(
        userId: 'acct_new',
        issuedAt: DateTime(2026, 10, 19),
        email: email,
        displayName: displayName,
        dateOfBirth: dateOfBirth,
      ),
    );
  }

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    await _hold();
    final error = signInError;
    if (error != null) throw error;
    lastEmail = email;
    lastPassword = password;
    // A session the test already set is the one this signs in as: the fake
    // stands in for a store that knows which account the address belongs to,
    // and a test that set one has said who it is.
    return session ??= Session(
      userId: 'acct_1',
      issuedAt: DateTime(2026, 10, 19),
      email: email,
    );
  }

  @override
  Future<Session> continueOffline() async {
    await _hold();
    return session = Session.device(issuedAt: DateTime(2026, 10, 19));
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    session = null;
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _hold();
    final error = changeError;
    if (error != null) throw error;
    lastUserId = userId;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }

  @override
  Future<void> deleteAccount(String userId) async {
    await _hold();
    lastUserId = userId;
    session = null;
  }
}
