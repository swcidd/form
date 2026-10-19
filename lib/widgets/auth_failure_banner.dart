import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A refusal that belongs to a form rather than to one field.
///
/// "That email and password do not match" is not wrong in either box — the
/// combination is wrong — so it needs somewhere to live that is not a field
/// error. Peach in the light theme with the icon in rust, so it reads as a
/// warning without shouting over the field it is about.
class AuthFailureBanner extends StatelessWidget {
  const AuthFailureBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadius.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.text.exerciseMeta.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
