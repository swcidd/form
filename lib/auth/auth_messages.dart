import 'auth_repository.dart';
import 'credentials.dart';

/// What a refusal says to whoever caused it.
///
/// One place, because the same failure is reachable from more than one screen,
/// and three copies of "that password is not right" are three chances for them
/// to disagree about what happened.
abstract final class AuthMessages {
  /// For a failure the store reported.
  static String forFailure(AuthFailure failure) => switch (failure) {
    AuthFailure.invalidEmail => 'That does not look like an email address.',
    AuthFailure.weakPassword =>
      'Use at least ${Credentials.minPasswordLength} characters.',
    AuthFailure.emailInUse => 'That email already has an account. Log in.',
    AuthFailure.invalidCredentials =>
      'That email and password do not match. Check both and try again.',
  };

  /// For anything the store did not describe — a file that cannot be written,
  /// say. Deliberately vague: the person cannot act on the detail, and the
  /// detail is already in the log.
  static const String unexpected = 'Something went wrong. Please try again.';
}
