/// Whole years between [dateOfBirth] and [today].
///
/// A birthday that has not arrived this year does not count yet, which is why
/// this cannot be just a subtraction of years.
int ageInYears(DateTime dateOfBirth, {DateTime? today}) {
  final now = today ?? DateTime.now();
  var age = now.year - dateOfBirth.year;
  final hadBirthday =
      now.month > dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
  if (!hadBirthday) age -= 1;
  return age;
}
