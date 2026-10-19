import 'package:flutter/material.dart';

/// The area under the hero, where a sign-in screen's content lives.
///
/// The design puts the fields at the top of it and the action at the bottom,
/// with whatever room is left in between. That gap is the thing that gives: the
/// content is laid out to fill the height it is handed and scrolls when there is
/// not enough of it, so a 320dp phone scrolls to the action instead of clipping
/// it, and a tall one does not leave the action floating halfway down the
/// screen.
///
/// [top] and [bottom] are groups rather than a list of children, because the
/// gap between them is the point: a heading with its fields, and the action with
/// whatever explains it.
class AuthFormArea extends StatelessWidget {
  const AuthFormArea({super.key, this.top, this.bottom});

  /// Pinned under the hero. Null on a screen with nothing above the action.
  final Widget? top;

  /// Pinned above the bottom edge. Null on a screen whose content is all one
  /// group.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final above = top;
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            // At least as tall as the room available, so the two groups can be
            // pushed to its edges; taller when the content needs it, which is
            // when the scroll view starts doing something.
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: above == null
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                children: [?above, ?bottom],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
