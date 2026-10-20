/// Who the app is currently showing, and when they arrived.
///
/// A session with no email is the device account — what "continue offline"
/// creates: the same store the app had before it had accounts at all, under
/// [deviceUserId]. A session with an email belongs to an account, and its
/// training is that account's alone.
///
/// There is deliberately no token and no expiry field. A device session has
/// neither, and both are the shape a *server* would need — they arrive with the
/// single class that talks to one, rather than sitting here now as fields
/// nothing sets and no test can reach.
class Session {
  const Session({
    required this.userId,
    required this.issuedAt,
    this.email,
    this.displayName,
    this.dateOfBirth,
  });

  /// The device account's id.
  ///
  /// Also the value the v4 migration writes into every row that existed before
  /// accounts did, which is what makes an upgrade land in "continue offline"
  /// with its training intact rather than in an empty app.
  static const String deviceUserId = 'local';

  /// The device account, started now.
  static Session device({required DateTime issuedAt}) =>
      Session(userId: deviceUserId, issuedAt: issuedAt);

  /// The id every row this session writes is attributed to.
  final String userId;

  /// When this session was established — a restart keeps the original moment,
  /// so "signed in since" stays true rather than resetting on every launch.
  final DateTime issuedAt;

  /// The account's address, or null for the device account.
  final String? email;

  final String? displayName;

  /// The date of birth given at sign-up, or null when there was none to give.
  final DateTime? dateOfBirth;

  /// Whether this is the device account rather than a named one.
  bool get isGuest => email == null;

  /// What to call whoever is signed in, or the empty string for the device
  /// account — which has no name to show and says so with its own copy.
  String get name {
    final given = displayName?.trim() ?? '';
    if (given.isNotEmpty) return given;
    final address = email;
    if (address == null) return '';
    final at = address.indexOf('@');
    return at > 0 ? address.substring(0, at) : address;
  }
}
