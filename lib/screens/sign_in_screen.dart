import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_messages.dart';
import '../auth/auth_repository.dart';
import '../auth/credentials.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_failure_banner.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/auth_link.dart';
import 'sign_up_name_screen.dart';

/// Signs an existing account in.
///
/// Nothing here decides whether a password is right: the screen asks for the
/// shape of an address, sends both halves to [AuthProvider], and shows what
/// comes back. Whether the password is long enough, whether the account exists
/// and whether the password matches are the store's answers, and the store is
/// the only thing that has ever seen the verifier.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const String routeName = '/sign-in';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _emailError;
  String? _passwordError;

  /// A refusal that belongs to the pair rather than to one field: a password
  /// that does not match is not wrong in the password box, the combination is
  /// wrong, and pointing at one of the two would send the person to the wrong
  /// place to fix it.
  String? _banner;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text;
    final password = _password.text;

    // Checked locally first so the obvious mistakes do not cost a round trip,
    // and checked again in the store, which is where it actually matters.
    final emailProblem = Credentials.emailProblem(email);
    final passwordProblem = password.isEmpty ? 'Enter your password.' : null;

    setState(() {
      _emailError = emailProblem;
      _passwordError = passwordProblem;
      _banner = null;
    });
    if (emailProblem != null || passwordProblem != null) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signIn(email: email, password: password);
      // Succeeding here swaps the whole app out from under this screen, so
      // there is nothing left to navigate to and nobody left to tell.
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _banner = AuthMessages.forFailure(error.failure));
    } catch (error) {
      debugPrint('Sign-in failed: $error');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AuthMessages.unexpected)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final busy = auth.busy;

    return Scaffold(
      body: Column(
        children: [
          AuthHero(
            kicker: 'WELCOME BACK / KEEP BUILDING',
            headline: 'BACK TO\nYOUR STRONG.',
            onBack: () => Navigator.of(context).maybePop(),
            height: 318,
          ),
          AuthFormArea(
            top: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthIntro(
                    title: 'LOG IN',
                    subtitle: 'Your training. Your progress. Right where you left it.',
                  ),
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
                    hint: 'Your password',
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    errorText: _passwordError,
                    enabled: !busy,
                    onSubmitted: (_) => _submit(),
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
                AuthAction(label: 'Log in', busy: busy, onPressed: _submit),
                const SizedBox(height: 12),
                Divider(color: scheme.outlineVariant, height: 24),
                AuthLink(
                  prompt: 'New to FORM?',
                  action: 'Sign up',
                  onPressed: busy
                      ? null
                      : () =>
                            Navigator.of(context)
                                .pushNamed(SignUpNameScreen.routeName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
