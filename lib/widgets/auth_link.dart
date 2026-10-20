import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

/// The quiet line at the foot of a form, offering the other screen.
///
/// A prompt, an action and an arrow in one tappable row rather than a
/// [TextButton]: the whole sentence is the target, and the two halves are set
/// in different weights the way the design draws them.
class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final enabled = onPressed != null;

    return Center(
      child: Pressable(
        onTap: onPressed,
        borderRadius: AppRadius.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prompt,
                style: text.exerciseMeta.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                action,
                style: text.exerciseMeta.copyWith(
                  fontWeight: FontWeight.w700,
                  color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.north_east_rounded, size: 15, color: scheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
