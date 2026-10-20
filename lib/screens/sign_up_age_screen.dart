import 'package:flutter/material.dart';

import '../models/sign_up_draft.dart';
import '../theme/app_typography.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/date_of_birth_field.dart';
import '../widgets/sign_up_steps.dart';
import 'sign_up_account_screen.dart';
import 'sign_up_footer.dart';

/// Sign-up, step two: the date of birth behind the athlete profile.
///
/// The design calls this step "Age" and asks for a date of birth. The date is
/// the input because an age is a number that stops being true tomorrow; a
/// birthday stays a fact.
class SignUpAgeScreen extends StatefulWidget {
  const SignUpAgeScreen({super.key, required this.draft});

  final SignUpDraft draft;

  @override
  State<SignUpAgeScreen> createState() => _SignUpAgeScreenState();
}

class _SignUpAgeScreenState extends State<SignUpAgeScreen> {
  DateTime? _dateOfBirth;
  String? _error;

  /// The same floor the year list offers, checked again because the list can
  /// produce somebody whose birthday later this year makes them twelve.
  static const int minimumAge = 13;

  void _continue() {
    final problem = _problemFor(_dateOfBirth);
    setState(() => _error = problem);
    if (problem != null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpAccountScreen(
          draft: widget.draft.withDateOfBirth(_dateOfBirth!),
        ),
      ),
    );
  }

  static String? _problemFor(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return 'Choose your date of birth.';

    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    if (age < minimumAge) return 'You must be at least $minimumAge.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

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
                const AuthIntro(
                  title: 'A LITTLE ABOUT YOU.',
                  subtitle: 'Add your age to your athlete profile.',
                ),
                const SizedBox(height: 24),
                DateOfBirthField(
                  label: 'DATE OF BIRTH',
                  initialDate: _dateOfBirth,
                  errorText: _error,
                  onChanged: (date) {
                    setState(() {
                      _dateOfBirth = date;
                      if (date != null) _error = null;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your date of birth from the dropdowns.',
                  style: text.exerciseMeta.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'One more step: create your account.',
                  style: text.annotation.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
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
