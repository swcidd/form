/// An account that lives on this device.
///
/// [passwordHash] is a verifier, not a password — see [PasswordHasher] for what
/// it is and what it is not. Nothing reads it back out except the store that
/// checks it, and there is no getter that returns anything derived from the
/// password, so no screen can accidentally show one.
class Account {
  const Account({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.displayName = '',
  });

  /// The stable identifier every other row attributes itself to.
  ///
  /// Generated once and never derived from the address, so the day an account
  /// changes its email is not the day its training history has to be rewritten.
  final String id;

  /// Already normalised — see [Credentials.normaliseEmail].
  final String email;

  final String displayName;

  /// The stored verifier for this account's password.
  final String passwordHash;

  final DateTime createdAt;

  /// What to call this account: the name they gave, or the part of the address
  /// in front of the `@`, which is what a person recognises more readily than
  /// their own full address.
  String get name {
    final given = displayName.trim();
    if (given.isNotEmpty) return given;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  Account copyWith({String? displayName, String? passwordHash}) => Account(
    id: id,
    email: email,
    displayName: displayName ?? this.displayName,
    passwordHash: passwordHash ?? this.passwordHash,
    createdAt: createdAt,
  );
}
