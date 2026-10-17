import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Small uppercase label that opens a section, with an optional inline action.
///
/// Kept as a widget so every screen spells and spaces its labels the same
/// way. The action stays a plain text button rather than a chip, because it
/// navigates rather than filters.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: context.text.labelCaps,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.only(left: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                actionLabel!,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}
