import 'package:plus_one/auth/auth_repository.dart';
import 'package:plus_one/models/session.dart';

/// Signs up and hands back the session.
///
/// [AuthRepository.createAccount] returns an outcome, because a store that
/// verifies addresses makes the account without signing anyone in. The local
/// store always signs in, so the tests whose subject is the account — rather
/// than what a sign-up answered — would otherwise unwrap the same result in
/// every one of them.
///
/// Fails loudly if a store that cannot sign in immediately is used here, which
/// is a test that meant to cover the other branch.
Future<Session> signUp(
  AuthRepository auth, {
  required String email,
  required String password,
  String? displayName,
  DateTime? dateOfBirth,
  double? heightCm,
  double? weightKg,
}) async {
  final outcome = await auth.createAccount(
    email: email,
    password: password,
    displayName: displayName,
    dateOfBirth: dateOfBirth,
    heightCm: heightCm,
    weightKg: weightKg,
  );
  return switch (outcome) {
    SignedUp(:final session) => session,
    ConfirmationSent() => throw StateError(
      'This store asked for confirmation, so there is no session to check.',
    ),
  };
}
