import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_messages.dart';
import '../auth/auth_repository.dart';
import '../auth/credentials.dart';
import '../providers/auth_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_failure_banner.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/auth_link.dart';
import 'sign_in_screen.dart';

/// Makes an account and signs it in.
///
/// The design splits this over three steps — name, date of birth, then the
/// credentials — and this screen is the third one with the first one's field at
/// the top. The step in between asked for a date of birth to put in an athlete
/// profile, and this app keeps no date of birth anywhere: there is no column
/// for it and nothing that would read one, so a screen collecting it would be
/// collecting it for nobody. Name is here because the account does use it —
/// every greeting in the app goes through it — and it is optional because an
/// account works without one, falling back to the part of the address in front
/// of the `@`.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  static const String routeName = '/create-account';

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _name = TextEditingController();
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
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text;
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
        displayName: name,
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
              onPressed: () =>
                  Navigator.of(context)
                      .pushReplacementNamed(SignInScreen.routeName),
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
            headline: 'YOUR STRONG.\nSTARTS HERE.',
            onBack: () => Navigator.of(context).maybePop(),
            height: 240,
          ),
          AuthFormArea(
            top: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthIntro(
                    title: 'CREATE YOUR ACCOUNT.',
                    subtitle: 'Your training. Your progress. All in one place.',
                  ),
                  const SizedBox(height: 24),
                  AuthField(
                    label: 'NAME',
                    controller: _name,
                    hint: 'What should we call you?',
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
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
                    'Use a password you do not use anywhere else, and at '
                    'least ${Credentials.minPasswordLength} characters.',
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
                Divider(color: scheme.outlineVariant, height: 24),
                AuthLink(
                  prompt: 'Already training?',
                  action: 'Log in',
                  onPressed: busy
                      ? null
                      : () =>
                            Navigator.of(context)
                                .pushReplacementNamed(SignInScreen.routeName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
