import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The app's page transition: a fade with a short rise.
///
/// Android's default builder zooms both pages, which reads as the platform
/// switching windows rather than as FORM opening a screen. A fade plus an 8%
/// lift is quiet enough to survive being seen twenty times a session, and it
/// animates only opacity and transform, so it does not touch layout.
///
/// Cupertino is deliberately not replaced. The iOS back-swipe depends on
/// Apple's builder, and a custom page transition would break a gesture users
/// already expect.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.routeIn;

  @override
  Duration get reverseTransitionDuration => AppMotion.routeOut;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The route still takes its duration to settle; it simply does not move.
    // Zeroing the duration here is not possible, because the duration getters
    // have no context, and a still frame for 260 ms is indistinguishable from
    // an instant one.
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final curved = animation.drive(CurveTween(curve: AppMotion.easeOut));

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(
          Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
