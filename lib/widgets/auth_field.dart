import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A labelled field on a sign-in screen.
///
/// Label above, box below, and the box is a white hairline rectangle rather
/// than a Material field: the design sets every input on these screens the same
/// way, and a themed `TextField` would arrive with its own fill, its own radius
/// and its own idea of padding.
///
/// The password variant brings its own show/hide control, because that state is
/// nobody else's business — a caller that had to hold it would be a caller that
/// could forget to clear it when the screen is reused for another field.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.onSubmitted,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  /// Whether this is a password: hides what is typed and offers the eye.
  final bool obscure;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// What is wrong with what is in the field, or null. Shown under the box and
  /// echoed by a red hairline, so the message is not the only signal.
  final String? errorText;

  final ValueChanged<String>? onSubmitted;

  /// False while the form is in flight, so the fields cannot be edited under a
  /// request that is already using their contents.
  final bool enabled;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _hidden = widget.obscure;

  @override
  void didUpdateWidget(AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A screen that swaps a field between password and plain — none do today —
    // would otherwise inherit the previous field's visibility.
    if (widget.obscure != oldWidget.obscure) _hidden = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final text = context.text;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: text.labelCaps),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.only(left: 16, right: 6),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.control,
            border: Border.all(
              color: hasError ? scheme.error : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: widget.obscure && _hidden,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onSubmitted: widget.onSubmitted,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (widget.obscure)
                IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: text.annotation.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
