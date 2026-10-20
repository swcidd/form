import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A tappable surface that shrinks slightly while a finger is on it.
///
/// The scale is the only addition to [InkWell], and it is driven by the tap
/// callbacks rather than by `onHighlightChanged`: a highlight also appears on
/// hover and on keyboard focus, and a card that shrinks because a mouse crossed
/// it is a different, worse interaction than one that answers a press.
///
/// The scale is skipped entirely when the platform asks for reduced motion.
/// It is also skipped for disabled surfaces, which is why they receive no tap
/// callbacks at all: a recognizer with nothing to do would still flash a
/// ripple on a row that cannot be tapped.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
    this.scale = 0.97,
  });

  final Widget child;

  /// Null disables the surface.
  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// Clips the material and shapes the ink, matching the surface underneath.
  final BorderRadius? borderRadius;

  /// The surface colour, when this widget is the surface rather than sitting
  /// on one. Null leaves it transparent.
  final Color? color;

  /// How far the surface travels. Small: a press should be felt, not watched.
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setDown(bool value) {
    if (!_enabled || _down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedScale(
      scale: _down && !reduceMotion ? widget.scale : 1,
      duration: _down ? AppMotion.pressDown : AppMotion.pressUp,
      curve: AppMotion.easeOut,
      child: Material(
        color: widget.color ?? Colors.transparent,
        borderRadius: widget.borderRadius,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: _enabled ? (_) => _setDown(true) : null,
          onTapUp: _enabled ? (_) => _setDown(false) : null,
          onTapCancel: _enabled ? () => _setDown(false) : null,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
