import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// The full-width action at the foot of a sign-in screen.
///
/// Filled is the one thing the screen wants; outlined is the alternative. One
/// widget for both, so "log in" on the welcome screen and "log in" on the
/// sign-in screen cannot end up looking like two different controls.
class AuthAction extends StatelessWidget {
  const AuthAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.busy = false,
  });

  final String label;

  /// Null disables it. A screen with nothing to submit yet passes null rather
  /// than offering a button that does nothing.
  final VoidCallback? onPressed;

  final bool filled;

  /// Shows progress in place of the arrow and stops accepting taps.
  ///
  /// The spinner replaces the arrow rather than sitting beside it, so the label
  /// does not move when the form goes to work — a button whose text jitters
  /// under the thumb reads as a different button.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final background = filled ? AppColors.lime : Colors.transparent;
    final foreground = filled ? AppColors.ink : scheme.onSurface;

    return Opacity(
      opacity: busy ? 0.72 : 1,
      child: Pressable(
        onTap: busy ? null : onPressed,
        borderRadius: AppRadius.control,
        color: background,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: AppRadius.control,
            border: filled ? null : Border.all(color: scheme.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.labelCaps.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(Icons.arrow_forward_rounded, size: 22, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}
