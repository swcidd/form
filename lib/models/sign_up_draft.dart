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
    this.age,
    this.heightCm,
    this.weightKg,
  });

  final String firstName;
  final String lastName;

  /// Null until the age step has a valid number.
  final int? age;

  /// Null until the measurements step has a valid height.
  final double? heightCm;

  /// Null until the measurements step has a valid weight.
  final double? weightKg;

  /// The single line an account is stored under.
  ///
  /// The account has one display name and the design asks for two fields; the
  /// two are joined here rather than carried separately into a store that has
  /// no second column for them.
  String get fullName => [
    firstName.trim(),
    lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  SignUpDraft withAge(int value) =>
      SignUpDraft(firstName: firstName, lastName: lastName, age: value);

  SignUpDraft withMeasurements({
    required double heightCm,
    required double weightKg,
  }) => SignUpDraft(
    firstName: firstName,
    lastName: lastName,
    age: age,
    heightCm: heightCm,
    weightKg: weightKg,
  );
}
