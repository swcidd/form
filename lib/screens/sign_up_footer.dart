import 'package:flutter/material.dart';

import '../widgets/auth_link.dart';
import 'sign_in_screen.dart';

/// The quiet line at the foot of every sign-up step.
///
/// One widget because the answer is the same on all three: leave the flow and
/// log in. It clears the steps rather than replacing the top one — replacing
/// would leave "age" or "name" underneath a sign-in screen, and the back button
/// would walk back into a form for an account that already exists.
class SignUpFooter extends StatelessWidget {
  const SignUpFooter({super.key, this.enabled = true});

  /// False while a request is in flight, which is also when the fields are
  /// locked.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: scheme.outlineVariant, height: 24),
        AuthLink(
          prompt: 'Already on FORM?',
          action: 'Log in',
          onPressed: enabled ? () => _toSignIn(context) : null,
        ),
      ],
    );
  }

  static void _toSignIn(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(SignInScreen.routeName, (route) => route.isFirst);
  }
}
