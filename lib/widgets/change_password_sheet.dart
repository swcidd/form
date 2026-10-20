import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_messages.dart';
import '../auth/auth_repository.dart';
import '../auth/credentials.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'auth_action.dart';
import 'auth_failure_banner.dart';
import 'auth_field.dart';

/// The form for replacing a password, opened from the profile's account card.
///
/// A sheet rather than a screen of its own: it is three fields and one verb,
/// and the design has no settings page for it to belong to. The fields are the
/// same [AuthField] the sign-in screens use, so a password is entered into the
/// same control everywhere it is asked for.
Future<void> showChangePasswordSheet(BuildContext context) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final animationStyle = reduceMotion
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: AppMotion.sheetIn,
          reverseDuration: AppMotion.sheetOut,
        );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: animationStyle,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const ChangePasswordSheet(),
  );
}

/// Current password and new password.
///
/// No confirmation field, for the same reason the sign-up screen has none: the
/// second entry is a second copy of a value the app is about to hash, and the
/// eye already lets somebody check what they typed. Asking twice on one screen
/// and once on the other would be two answers to the same question.
///
/// The check for the current password is the store's, not this screen's: the
/// screen can see that the field is not empty, and nothing else. A wrong
/// current password is reported under that field, in words about *this* form —
/// "that is not your current password" rather than the sign-in screen's "that
/// email and password do not match", which would be answerable and wrong.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _updated = TextEditingController();

  String? _currentError;
  String? _updatedError;
  String? _banner;

  @override
  void dispose() {
    _current.dispose();
    _updated.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _current.text;
    final updated = _updated.text;

    final currentProblem = current.isEmpty
        ? 'Enter your current password.'
        : null;
    final updatedProblem = Credentials.passwordProblem(updated);

    setState(() {
      _currentError = currentProblem;
      _updatedError = updatedProblem;
      _banner = null;
    });
    if (currentProblem != null || updatedProblem != null) return;

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.changePassword(currentPassword: current, newPassword: updated);
      // The sheet is closed by the caller's navigator, not by the provider:
      // the password changed, and there is nothing left for the form to do.
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _showRefusal(error.failure));
    } catch (error) {
      debugPrint('Changing the password failed: $error');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text(AuthMessages.unexpected)),
      );
    }
  }

  /// Puts a refusal where it can be acted on.
  ///
  /// A wrong current password is a problem with the first field; a rejected new
  /// one is a problem with the second. The rest are about the request, and go
  /// in the banner — a server-backed store can answer `unavailable`, and a
  /// local one cannot, but the form has to say something either way.
  void _showRefusal(AuthFailure failure) {
    switch (failure) {
      case AuthFailure.invalidCredentials:
        _currentError = 'That is not your current password.';
      case AuthFailure.weakPassword:
        _updatedError = AuthMessages.forFailure(failure);
      case AuthFailure.invalidEmail:
      case AuthFailure.emailInUse:
      case AuthFailure.unavailable:
      case AuthFailure.emailNotConfirmed:
        _banner = AuthMessages.forFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final busy = context.watch<AuthProvider>().busy;

    return Padding(
      // The keyboard pushes the sheet up rather than covering the action: the
      // inset is measured here because the sheet is scroll-controlled.
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CHANGE PASSWORD.',
                style: text.exerciseName.copyWith(
                  fontSize: 32,
                  letterSpacing: -1.28,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your current password, then choose a new one.',
                style: text.exerciseMeta.copyWith(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              AuthField(
                label: 'CURRENT PASSWORD',
                controller: _current,
                hint: 'Your current password',
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                errorText: _currentError,
                enabled: !busy,
              ),
              const SizedBox(height: 16),
              AuthField(
                label: 'NEW PASSWORD',
                controller: _updated,
                hint: 'At least ${Credentials.minPasswordLength} characters',
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                errorText: _updatedError,
                enabled: !busy,
                onSubmitted: (_) => _submit(),
              ),
              if (_banner != null) ...[
                const SizedBox(height: 16),
                AuthFailureBanner(message: _banner!),
              ],
              const SizedBox(height: 24),
              AuthAction(
                label: 'Change password',
                busy: busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
