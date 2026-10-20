import 'package:flutter/material.dart';

import '../models/sign_up_draft.dart';
import '../theme/app_typography.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/sign_up_steps.dart';
import 'sign_up_age_screen.dart';
import 'sign_up_footer.dart';

/// Sign-up, step one: the name the app will use.
///
/// The design asks for two fields where the account has one name. They are
/// joined in [SignUpDraft.fullName] rather than stored separately, because the
/// account is stored under one display name and nothing else reads a surname.
/// A first name is required — this step exists for it — and a surname is not,
/// because plenty of people train under one name and the account works either
/// way.
class SignUpNameScreen extends StatefulWidget {
  const SignUpNameScreen({super.key});

  static const String routeName = '/create-account';

  @override
  State<SignUpNameScreen> createState() => _SignUpNameScreenState();
}

class _SignUpNameScreenState extends State<SignUpNameScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  String? _firstNameError;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _continue() {
    final first = _firstName.text.trim();
    setState(() {
      _firstNameError = first.isEmpty ? 'Tell us your first name.' : null;
    });
    if (first.isEmpty) return;

    final draft = SignUpDraft(
      firstName: first,
      lastName: _lastName.text.trim(),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SignUpAgeScreen(draft: draft)),
    );
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
            headline: 'YOUR STRONG.\nSTARTS HERE.',
            onBack: () => Navigator.of(context).maybePop(),
            height: 260,
          ),
          AuthFormArea(
            top: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignUpSteps(current: 0),
                const SizedBox(height: 24),
                const AuthIntro(
                  title: 'LET’S MEET YOU.',
                  subtitle: 'First, the name behind the next personal best.',
                ),
                const SizedBox(height: 24),
                AuthField(
                  label: 'FIRST NAME',
                  controller: _firstName,
                  hint: 'Your first name',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  errorText: _firstNameError,
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'LAST NAME',
                  controller: _lastName,
                  hint: 'Your last name',
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.familyName],
                  onSubmitted: (_) => _continue(),
                ),
              ],
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Next up: a little about you.',
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
