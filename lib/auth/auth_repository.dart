import '../models/session.dart';

/// Why an account operation did not happen.
///
/// A reason rather than a message: the screens own the words, and the same
/// failure reads differently on a sign-in screen than in a settings sheet.
enum AuthFailure {
  /// The address is not usable as one — see [Credentials.emailProblem].
  invalidEmail,

  /// The password does not meet the floor — see [Credentials.passwordProblem].
  weakPassword,

  /// An account already exists for that address.
  emailInUse,

  /// The address and password do not match an account.
  ///
  /// Deliberately one failure for both halves. Telling a caller that the
  /// address exists but the password is wrong would turn the sign-in screen
  /// into a way of finding out which addresses are registered.
  invalidCredentials,

  /// The identity store could not be reached — no network, or a server that is
  /// down.
  ///
  /// The device-local implementation has nothing to reach, so it never raises
  /// this. It is in the vocabulary so a server-backed one has somewhere to put
  /// the failure that is not a stack trace and not a lie about the password.
  unavailable,

  /// The account exists, but its address has not been confirmed yet.
  ///
  /// What a server that verifies addresses answers when somebody tries to log
  /// in before following the link. A local account has nothing to confirm, so
  /// only a server-backed implementation raises it — but the sign-in screen
  /// has to be able to say it, and saying "that password is wrong" to somebody
  /// whose password is right is worse than adding the reason now.
  emailNotConfirmed,
}

/// What came of a sign-up.
///
/// A sign-up is not always a sign-in. A store that verifies addresses —
/// Supabase's default — creates the account and sends a link, and hands back no
/// session until that link is followed; a local one can sign the new account in
/// immediately. Returning a [Session] would force the first implementation to
/// pretend, so the caller is given the outcome and switches on it.
sealed class SignUpOutcome {
  const SignUpOutcome();
}

/// The account exists and its owner is signed in.
final class SignedUp extends SignUpOutcome {
  const SignedUp(this.session);

  final Session session;
}

/// The account exists but cannot be used until its address is confirmed.
///
/// [email] is the address as it was stored, so the screen can name the inbox
/// the message went to rather than saying "your email" to somebody who may
/// have typed a different one than they think.
final class ConfirmationSent extends SignUpOutcome {
  const ConfirmationSent(this.email);

  final String email;
}

/// Thrown by [AuthRepository] when a request cannot be satisfied.
class AuthException implements Exception {
  const AuthException(this.failure, [this.cause]);

  final AuthFailure failure;

  /// The underlying error, when there was one. Kept for the log rather than
  /// the UI.
  final Object? cause;

  @override
  String toString() =>
      'AuthException(${failure.name}${cause == null ? '' : ': $cause'})';
}

/// What the app asks of whoever holds the identity.
///
/// This is the seam the feature is built around. Screens and the provider call
/// these verbs and read a [Session]; nothing above knows where the identity
/// lives or how a password is checked. Replacing the device-local
/// implementation with one that talks to a server — an API of our own,
/// Firebase, Supabase — is a new class implementing this and a line in `main`,
/// with no screen, no provider and no test touched. The two answers a verifying
/// server gives that a local store does not — a sign-up that needs a link
/// followed, and an address that has not been confirmed — are already part of
/// the vocabulary, so the screens have somewhere to put them.
///
/// Every method that can fail on what somebody typed throws an [AuthException]
/// carrying why, so a caller has to decide what to show rather than quietly
/// doing nothing.
abstract interface class AuthRepository {
  /// Who was signed in when the app last closed, or null for nobody.
  ///
  /// Called before the first frame, so the app opens on the right account
  /// instead of flashing the welcome screen on every launch.
  Future<Session?> restoreSession();

  /// Registers a new account.
  ///
  /// Returns what came of it: a signed-in session, or — on a store that
  /// verifies addresses — the confirmation that has to happen first.
  ///
  /// Throws [AuthFailure.invalidEmail], [AuthFailure.weakPassword],
  /// [AuthFailure.emailInUse] or [AuthFailure.unavailable].
  Future<SignUpOutcome> createAccount({
    required String email,
    required String password,
    String? displayName,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
  });

  /// Signs an existing account in.
  ///
  /// Throws [AuthFailure.invalidCredentials] — for an unknown address as well
  /// as a wrong password.
  Future<Session> signIn({required String email, required String password});

  /// Keeps using the app without an account, as the device account.
  Future<Session> continueOffline();

  /// Ends the session. The account and everything it trained stay put.
  Future<void> signOut();

  /// Replaces the password, given the current one.
  ///
  /// Throws [AuthFailure.invalidCredentials] when the current password is
  /// wrong and [AuthFailure.weakPassword] when the new one is too short.
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  /// Removes the account and everything attributed to it.
  ///
  /// Irreversible, which is why the screen asks twice. Signing out first is the
  /// caller's job: this is about the data, not the session.
  Future<void> deleteAccount(String userId);
}
