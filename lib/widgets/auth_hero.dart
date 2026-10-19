import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The dark photographic header the sign-in screens open with.
///
/// One widget for all three of them, so the wordmark, the kicker and the
/// display line cannot drift apart: they sit in the same place at the same size
/// whether the screen below is asking for a password or offering to make an
/// account.
///
/// The photograph is the same frame the library uses for a program. It is a
/// real session, which is the whole point of the header — and it is covered by
/// a scrim that is darkest at the bottom left, where the copy sits, so the
/// words are never laid over the bright part of the picture.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.kicker,
    required this.headline,
    this.onBack,
    this.height = 318,
  });

  /// The small line above the display text.
  final String kicker;

  /// The display text. It carries its own line break, the way the design sets
  /// it, because where a headline breaks is part of how it reads.
  final String headline;

  /// Shows a back action when this screen was pushed. The welcome screen is the
  /// first thing anybody sees, so it has nowhere to go back to and passes null.
  final VoidCallback? onBack;

  /// Shorter on the sign-up steps, where the form below needs the room.
  final double height;

  static const String _image = 'assets/images/program_hero.png';

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _image,
            fit: BoxFit.cover,
            // Decorative: a screen reader gains nothing from being told there
            // is a photograph of somebody lifting.
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.ink),
          ),
          // The 42deg gradient from the design, which is darkest at the bottom
          // left and all but transparent at the top right.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xFA121512),
                  Color(0x88121512),
                  Color(0x54121512),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _wordmark(text),
                    if (onBack != null) _back(context, text),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      kicker,
                      style: text.labelCaps.copyWith(color: AppColors.lime),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      headline,
                      style: text.exerciseName.copyWith(
                        fontSize: 48,
                        letterSpacing: -1.92,
                        height: 0.98,
                        color: AppColors.warmCream,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The mark, with the lime square the design sets beside it.
  Widget _wordmark(AppText text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'FORM',
          style: text.exerciseName.copyWith(
            fontSize: 32,
            letterSpacing: -1.28,
            color: AppColors.warmCream,
          ),
        ),
        const SizedBox(width: 10),
        const SizedBox(
          width: 6,
          height: 6,
          child: ColoredBox(color: AppColors.lime),
        ),
      ],
    );
  }

  Widget _back(BuildContext context, AppText text) {
    return TextButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 16),
      label: Text(
        'Back',
        style: text.labelCaps.copyWith(
          fontSize: 12,
          color: AppColors.warmCream,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.warmCream,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(44, 32),
      ),
    );
  }
}
