/// What the app accepts as an email and a password, in one place.
///
/// The sign-up screen shows these as field errors and the store refuses
/// anything that fails them. Both call here rather than each keeping a copy: a
/// rule that lives in two places is a rule that will differ in two places, and
/// the store's copy is the one that still applies when the screen is bypassed
/// by a test or a future caller.
abstract final class Credentials {
  /// Shortest password the store will hash.
  ///
  /// Eight is the floor the industry settled on. It is a floor and not a
  /// promise: length is the only thing a device can judge without also
  /// refusing passwords that are fine, so the screen asks for a long one
  /// rather than claiming a short one is strong.
  static const int minPasswordLength = 8;

  /// The address as it will be stored and looked up.
  ///
  /// Trimmed and lower-cased, because a person types their address the way
  /// they think of it — `Sam@Example.com`, on a phone that capitalises the
  /// first letter of everything — and an account that cannot be found by the
  /// address they typed is an account they cannot sign in to. The original is
  /// not kept: nothing needs the capitals, and two spellings of one address
  /// are how a person ends up with two accounts and half their training in
  /// each.
  static String normaliseEmail(String raw) => raw.trim().toLowerCase();

  /// Why [raw] cannot be used as an address, or null when it can.
  ///
  /// Deliberately loose. The only authority on whether an address exists is
  /// the server that receives its mail, so this checks the shape that a
  /// mistyped entry fails — one `@` with something either side, a dot in the
  /// domain, no spaces — and lets the merely unusual through rather than
  /// rejecting an address someone actually has.
  static String? emailProblem(String raw) {
    final email = raw.trim();
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'That does not look like an email address.';
    }
    return null;
  }

  /// Why [password] cannot be used, or null when it can.
  static String? passwordProblem(String password) {
    if (password.isEmpty) return 'Choose a password.';
    if (password.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }
}
