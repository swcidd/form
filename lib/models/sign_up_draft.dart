/// What the three sign-up steps have collected so far.
///
/// The name is asked for first, the date of birth second and the credentials
/// last, so the first two steps have to survive two route pushes. One small
/// immutable object passed as the route argument does that without a provider:
/// nothing outside the flow reads it, and popping a step throws it away with
/// the route.
class SignUpDraft {
  const SignUpDraft({
    required this.firstName,
    this.lastName = '',
    this.dateOfBirth,
  });

  final String firstName;
  final String lastName;

  /// Null until the age step has a complete, valid date.
  final DateTime? dateOfBirth;

  /// The single line an account is stored under.
  ///
  /// The account has one display name and the design asks for two fields; the
  /// two are joined here rather than carried separately into a store that has
  /// no second column for them.
  String get fullName => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  SignUpDraft withDateOfBirth(DateTime value) =>
      SignUpDraft(firstName: firstName, lastName: lastName, dateOfBirth: value);
}
