import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/pressable.dart';

import 'support/harness.dart';

/// The press scale is the one motion the app adds to a control, so it is held
/// to four promises: it answers a finger, it lets go, it does nothing when the
/// surface is disabled, and it disappears when the platform asks for reduced
/// motion.
void main() {
  setUpAll(useOfflineFonts);

  Widget wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  double targetScale(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('shrinks while held and returns on release', (tester) async {
    await tester.pumpWidget(
      wrap(
        Pressable(onTap: () {}, child: const SizedBox(width: 200, height: 56)),
      ),
    );

    expect(targetScale(tester), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Pressable)),
    );
    await tester.pump();

    expect(targetScale(tester), 0.97);

    await gesture.up();
    await tester.pump();

    expect(targetScale(tester), 1);
  });

  testWidgets('still delivers the tap', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      wrap(
        Pressable(
          onTap: () => taps++,
          child: const SizedBox(width: 200, height: 56),
        ),
      ),
    );

    await tester.tap(find.byType(Pressable));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(targetScale(tester), 1);
  });

  testWidgets('a disabled surface neither scales nor flashes', (tester) async {
    await tester.pumpWidget(
      wrap(const Pressable(child: SizedBox(width: 200, height: 56))),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Pressable)),
    );
    await tester.pump();

    expect(targetScale(tester), 1);
    // No recognizer at all, which is what stops the ink as well as the scale.
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTapDown, isNull);

    await gesture.up();
  });

  testWidgets('reduced motion keeps the interaction, drops the movement', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      wrap(
        Pressable(
          onTap: () => taps++,
          child: const SizedBox(width: 200, height: 56),
        ),
        reduceMotion: true,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Pressable)),
    );
    await tester.pump();

    expect(targetScale(tester), 1);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
