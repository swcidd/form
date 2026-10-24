import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Where a four-step sign-up has got to.
///
/// Four equal columns, each a rule over a label. Only the current step is
/// dark: a completed step is not ticked, because the form has not submitted
/// anything yet and a tick would claim it had.
class SignUpSteps extends StatelessWidget {
  const SignUpSteps({super.key, required this.current});

  /// Zero-based index of the step being shown.
  final int current;

  static const List<String> _labels = [
    '01  NAME',
    '02  AGE',
    '03  MEASUREMENTS',
    '04  ACCOUNT',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Row(
      children: [
        for (var index = 0; index < _labels.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 2,
                  color: index == current
                      ? scheme.onSurface
                      : scheme.outlineVariant,
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _labels[index],
                    maxLines: 1,
                    style: text.labelCaps.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.45,
                      color: index == current
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: index == current
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
