/// What the four sign-up steps have collected so far.
///
/// The name is asked for first, the age second, the measurements third and
/// the credentials last, so the first three steps have to survive three route
/// pushes. One small immutable object passed as the route argument does that
/// without a provider: nothing outside the flow reads it, and popping a step
/// throws it away with the route.
class SignUpDraft {
  const SignUpDraft({
    required this.firstName,
    this.lastName = '',
    this.dateOfBirth,
    this.heightCm,
    this.weightKg,
    this.heightImperial = false,
    this.weightImperial = false,
  });

  final String firstName;
  final String lastName;

  /// Null until the age step has a real date.
  final DateTime? dateOfBirth;

  /// Null until the measurements step has a valid height.
  final double? heightCm;

  /// Null until the measurements step has a valid weight.
  final double? weightKg;

  /// The unit the measurements step was left in, so the profile can show the
  /// same one after the account is made.
  final bool heightImperial;
  final bool weightImperial;

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

  SignUpDraft withMeasurements({
    required double heightCm,
    required double weightKg,
    required bool heightImperial,
    required bool weightImperial,
  }) => SignUpDraft(
    firstName: firstName,
    lastName: lastName,
    dateOfBirth: dateOfBirth,
    heightCm: heightCm,
    weightKg: weightKg,
    heightImperial: heightImperial,
    weightImperial: weightImperial,
  );
}
