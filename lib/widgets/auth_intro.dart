import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// The heading over a sign-in form.
///
/// Two lines in two different scales — a display line and a sentence
/// underneath — which is the same pair the app uses for a section heading
/// anywhere else. Shared so the sign-in and create-account screens cannot set
/// them at different sizes.
class AuthIntro extends StatelessWidget {
  const AuthIntro({super.key, required this.title, this.subtitle});

  final String title;

  /// The sentence under the heading. Sign-up omits it.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.exerciseName.copyWith(
            fontSize: 32,
            letterSpacing: -1.28,
            height: 1.1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: text.exerciseMeta.copyWith(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
