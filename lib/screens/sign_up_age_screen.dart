import 'package:flutter/material.dart';

import '../models/age.dart';
import '../models/sign_up_draft.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/date_of_birth_field.dart';
import '../widgets/sign_up_steps.dart';
import 'sign_up_footer.dart';
import 'sign_up_measurements_screen.dart';

/// Sign-up, step two: the date of birth the age is read from.
class SignUpAgeScreen extends StatefulWidget {
  const SignUpAgeScreen({super.key, required this.draft});

  final SignUpDraft draft;

  @override
  State<SignUpAgeScreen> createState() => _SignUpAgeScreenState();
}

class _SignUpAgeScreenState extends State<SignUpAgeScreen> {
  DateTime? _dateOfBirth;
  String? _error;

  static const int minimumAge = 13;
  static const int maximumAge = 120;

  void _continue() {
    final dateOfBirth = _dateOfBirth;
    if (dateOfBirth == null) {
      setState(() => _error = 'Choose your date of birth.');
      return;
    }

    final age = ageInYears(dateOfBirth);
    final problem = switch (age) {
      < minimumAge => 'You must be at least $minimumAge.',
      > maximumAge => 'Enter a date under $maximumAge years ago.',
      _ => null,
    };
    setState(() => _error = problem);
    if (problem != null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpMeasurementsScreen(
          draft: widget.draft.withDateOfBirth(dateOfBirth),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AuthHero(
            kicker: 'YOUR TRAINING / STARTS HERE',
            headline: 'YOUR PACE.\nYOUR PROGRESS.',
            onBack: () => Navigator.of(context).maybePop(),
            height: 260,
          ),
          AuthFormArea(
            top: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignUpSteps(current: 1),
                const SizedBox(height: 24),
                const AuthIntro(title: 'A LITTLE ABOUT YOU.'),
                const SizedBox(height: 24),
                DateOfBirthField(
                  label: 'DATE OF BIRTH',
                  errorText: _error,
                  onChanged: (value) {
                    setState(() {
                      _dateOfBirth = value;
                      if (value != null) _error = null;
                    });
                  },
                ),
              ],
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthAction(label: 'Continue', onPressed: _continue),
                const SizedBox(height: 12),
                const SignUpFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
