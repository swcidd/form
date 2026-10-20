import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/theme/app_page_transitions.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/harness.dart';

/// Page transitions are a theme-level decision, so they are tested at the
/// theme: which builders the platforms get, how long they take, and whether
/// reduced motion turns them off without turning the route off.
void main() {
  setUpAll(useOfflineFonts);

  const builder = AppPageTransitionsBuilder();

  test('arriving is slower than leaving', () {
    expect(builder.transitionDuration, AppMotion.routeIn);
    expect(builder.reverseTransitionDuration, AppMotion.routeOut);
    expect(
      builder.transitionDuration,
      greaterThan(builder.reverseTransitionDuration),
    );
  });

  test('Android and desktop fade; Apple keeps its back-swipe', () {
    final builders = AppTheme.light().pageTransitionsTheme.builders;

    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.fuchsia,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      expect(builders[platform], isA<AppPageTransitionsBuilder>());
    }

    expect(
      builders[TargetPlatform.iOS],
      isA<CupertinoPageTransitionsBuilder>(),
    );
    expect(
      builders[TargetPlatform.macOS],
      isA<CupertinoPageTransitionsBuilder>(),
    );
  });

  testWidgets('the transition is a fade over a slide', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox();
          },
        ),
      ),
    );

    const child = SizedBox(key: Key('child'));
    final route = MaterialPageRoute<void>(builder: (_) => child);
    final transition = builder.buildTransitions(
      route,
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
      child,
    );

    expect(transition, isA<FadeTransition>());
    expect((transition as FadeTransition).child, isA<SlideTransition>());
  });

  testWidgets('reduced motion shows the page with no movement', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (reduced) {
              context = reduced;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    const child = SizedBox(key: Key('child'));
    final route = MaterialPageRoute<void>(builder: (_) => child);
    final transition = builder.buildTransitions(
      route,
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
      child,
    );

    expect(transition, same(child));
  });
}
