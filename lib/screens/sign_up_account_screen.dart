import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_messages.dart';
import '../auth/auth_repository.dart';
import '../auth/credentials.dart';
import '../models/sign_up_draft.dart';
import '../providers/auth_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_failure_banner.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/sign_up_steps.dart';
import 'sign_in_screen.dart';
import 'sign_up_footer.dart';

/// Sign-up, step four: the address and the password.
///
/// The name, age and measurements have already been collected, so this step is
/// only what the identity store needs. When the store signs the new account in,
/// the gate swaps the whole window and there is nothing here left to navigate
/// to; when it wants the address confirmed first, this screen turns into the
/// answer.
class SignUpAccountScreen extends StatefulWidget {
  const SignUpAccountScreen({super.key, required this.draft});

  final SignUpDraft draft;

  @override
  State<SignUpAccountScreen> createState() => _SignUpAccountScreenState();
}

class _SignUpAccountScreenState extends State<SignUpAccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _banner;

  /// The address a confirmation link was sent to, or null while the form is
  /// still the thing to show.
  ///
  /// Not a route: the account exists but nobody is signed in, so leaving this
  /// screen would put a form for the same account back under the thumb. The
  /// same screen turns into the answer instead.
  String? _confirmationEmail;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text;
    final password = _password.text;

    final emailProblem = Credentials.emailProblem(email);
    final passwordProblem = Credentials.passwordProblem(password);

    setState(() {
      _emailError = emailProblem;
      _passwordError = passwordProblem;
      _banner = null;
    });
    if (emailProblem != null || passwordProblem != null) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final outcome = await auth.createAccount(
        email: email,
        password: password,
        displayName: widget.draft.fullName,
        dateOfBirth: widget.draft.dateOfBirth,
        heightCm: widget.draft.heightCm,
        weightKg: widget.draft.weightKg,
        heightImperial: widget.draft.heightImperial,
        weightImperial: widget.draft.weightImperial,
      );
      if (!mounted) return;
      switch (outcome) {
        // The gate swaps the whole window out from under this screen, so there
        // is nothing left to navigate to and nobody left to tell.
        case SignedUp():
          break;
        case ConfirmationSent(:final email):
          setState(() => _confirmationEmail = email);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _showRefusal(error.failure));
    } catch (error) {
      debugPrint('Creating an account failed: $error');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AuthMessages.unexpected)),
      );
    }
  }

  /// Puts a refusal where it can be acted on.
  ///
  /// An address already being taken is a problem with the address, and a
  /// password below the floor is a problem with the password, so both go under
  /// the field that caused them. Anything else is about the pair.
  void _showRefusal(AuthFailure failure) {
    switch (failure) {
      case AuthFailure.invalidEmail:
      case AuthFailure.emailInUse:
        _emailError = AuthMessages.forFailure(failure);
      case AuthFailure.weakPassword:
        _passwordError = AuthMessages.forFailure(failure);
      case AuthFailure.invalidCredentials:
      case AuthFailure.unavailable:
      case AuthFailure.emailNotConfirmed:
        _banner = AuthMessages.forFailure(failure);
    }
  }

  /// The answer when the store wants the address confirmed first.
  ///
  /// One screen rather than two, because the account has just been made and the
  /// only useful next act is to go and confirm it. The address is named so
  /// somebody who mistyped it can see that now, rather than waiting for mail
  /// that is going to a stranger.
  Widget _confirmation(BuildContext context, String email) {
    return Scaffold(
      body: Column(
        children: [
          AuthHero(
            kicker: 'ONE MORE STEP / CHECK YOUR INBOX',
            headline: 'CHECK YOUR\nINBOX.',
            onBack: () => Navigator.of(context).maybePop(),
            height: 300,
          ),
          AuthFormArea(
            top: AuthIntro(
              title: 'CONFIRM YOUR EMAIL.',
              subtitle:
                  'The account is made. Open the link sent to $email, then '
                  'log in.',
            ),
            bottom: AuthAction(
              label: 'Back to log in',
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                SignInScreen.routeName,
                (route) => route.isFirst,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmation = _confirmationEmail;
    if (confirmation != null) return _confirmation(context, confirmation);

    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final auth = context.watch<AuthProvider>();
    final busy = auth.busy;

    return Scaffold(
      body: Column(
        children: [
          AuthHero(
            kicker: 'YOUR TRAINING / STARTS HERE',
            headline: 'MAKE IT\nYOUR STRONG.',
            onBack: () => Navigator.of(context).maybePop(),
            height: 260,
          ),
          AuthFormArea(
            top: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SignUpSteps(current: 3),
                  const SizedBox(height: 24),
                  const AuthIntro(title: 'CREATE YOUR ACCOUNT.'),
                  const SizedBox(height: 24),
                  AuthField(
                    label: 'EMAIL ADDRESS',
                    controller: _email,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    errorText: _emailError,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    label: 'PASSWORD',
                    controller: _password,
                    hint: 'Create a password',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: _passwordError,
                    enabled: !busy,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use a password you don’t use elsewhere, and at least '
                    '${Credentials.minPasswordLength} characters.',
                    style: text.annotation.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (_banner != null) ...[
                    const SizedBox(height: 16),
                    AuthFailureBanner(message: _banner!),
                  ],
                ],
              ),
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthAction(
                  label: 'Create account',
                  busy: busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                SignUpFooter(enabled: !busy),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
