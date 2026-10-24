import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sign_up_draft.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/sign_up_steps.dart';
import 'sign_up_footer.dart';
import 'sign_up_measurements_screen.dart';

/// Sign-up, step two: how old the athlete is.
class SignUpAgeScreen extends StatefulWidget {
  const SignUpAgeScreen({super.key, required this.draft});

  final SignUpDraft draft;

  @override
  State<SignUpAgeScreen> createState() => _SignUpAgeScreenState();
}

class _SignUpAgeScreenState extends State<SignUpAgeScreen> {
  final _age = TextEditingController();

  String? _error;

  static const int minimumAge = 13;
  static const int maximumAge = 120;

  @override
  void dispose() {
    _age.dispose();
    super.dispose();
  }

  void _continue() {
    final age = int.tryParse(_age.text.trim());
    final problem = switch (age) {
      null => 'Enter your age.',
      < minimumAge => 'You must be at least $minimumAge.',
      > maximumAge => 'Enter an age under $maximumAge.',
      _ => null,
    };
    setState(() => _error = problem);
    if (problem != null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SignUpMeasurementsScreen(draft: widget.draft.withAge(age!)),
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
                AuthField(
                  label: 'AGE',
                  controller: _age,
                  hint: 'Years',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  errorText: _error,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _continue(),
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
