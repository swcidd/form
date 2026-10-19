import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_messages.dart';
import '../providers/auth_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import 'create_account_screen.dart';
import 'sign_in_screen.dart';

/// The first thing a new install shows.
///
/// Three ways in, and the third one is the point: this app worked before it had
/// accounts, so somebody who does not want one should not have to invent an
/// email address to keep training. "Continue offline" is that path — the device
/// account, no password, nothing to remember, and every screen behind it works
/// exactly as it always did.
///
/// It is part of the sign-in flow and so is only reachable while signed out:
/// a launch that finds a session goes straight to the app.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          const AuthHero(
            kicker: 'YOUR TRAINING / STARTS HERE',
            headline: 'YOUR STRONG.\nSTARTS HERE.',
          ),
          // One group, pinned to the bottom of the screen rather than to the
          // foot of the hero: these three are the reason the screen exists, and
          // the bottom of the screen is where a thumb already is.
          AuthFormArea(
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthAction(
                  label: 'Create an account',
                  busy: auth.busy,
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(CreateAccountScreen.routeName),
                ),
                const SizedBox(height: 12),
                AuthAction(
                  label: 'Log in',
                  filled: false,
                  onPressed: auth.busy
                      ? null
                      : () =>
                            Navigator.of(context)
                                .pushNamed(SignInScreen.routeName),
                ),
                const SizedBox(height: 20),
                _offline(context, auth),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'An account is not required to train.',
                    style: text.annotation.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _offline(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TextButton(
            onPressed: auth.busy ? null : () => _continueOffline(context, auth),
            child: const Text('Continue offline'),
          ),
        ),
        // Said once, here, rather than promised on every screen: nothing about
        // a session or a workout leaves this device, and the network the app
        // does use is the exercise catalogue.
        Center(
          child: Text(
            'Your training stays on this device.',
            style: context.text.annotation.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _continueOffline(BuildContext context, AuthProvider auth) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.continueOffline();
    } catch (error) {
      debugPrint('Could not start offline: $error');
      // The store refused to write. There is no field to put this against, so
      // it goes where the app puts everything with nowhere else to go.
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AuthMessages.unexpected)),
      );
    }
  }
}
