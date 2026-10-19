import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plus_one/widgets/app_nav_bar.dart';

import '../test/support/harness.dart';

/// Renders the app for the README and the paper.
///
/// Run from the project root with `--update-goldens` to rewrite
/// `docs/screenshots/`:
///
/// ```bash
/// flutter test tool/screenshot_test.dart --update-goldens
/// ```
///
/// It lives outside `test/` on purpose: it is a documentation tool, not an
/// assertion, and as a test it would fail the suite every time a screen changed
/// on purpose.
void main() {
  setUpAll(() async {
    useOfflineFonts();

    // The Material icon font is not part of the test asset bundle, and a shot
    // without it is a wall of empty boxes. Its absence is not fatal - the layout
    // is still readable - so a checkout without an SDK cache gets a note rather
    // than a red test.
    final font = _materialIconsFont();
    if (font == null) {
      stdout.writeln(
        'MaterialIcons-Regular.otf not found; icons will render as boxes.',
      );
      return;
    }
    final bytes = font.readAsBytesSync();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  });

  /// A phone-shaped surface at 2x, large enough to print.
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(804, 1748);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  /// Pumps, and gives the asset photographs time to decode: without the real
  /// clock they stay empty in the first frame and the shot catches them empty.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('01 welcome', (tester) async {
    phone(tester);
    await tester.pumpWidget(signedOutApp());
    await settle(tester);
    await shot(tester, '01-welcome');
  });

  testWidgets('02 sign in', (tester) async {
    phone(tester);
    await tester.pumpWidget(signedOutApp());
    await settle(tester);
    await tap(tester, 'Log in');
    await settle(tester);
    await shot(tester, '02-sign-in');
  });

  testWidgets('03 create account', (tester) async {
    phone(tester);
    await tester.pumpWidget(signedOutApp());
    await settle(tester);
    await tap(tester, 'Create an account');
    await settle(tester);
    await shot(tester, '03-create-account');
  });

  testWidgets('04 home', (tester) async {
    phone(tester);
    await tester.pumpWidget(seededApp());
    await settle(tester);
    await shot(tester, '04-home');
  });

  testWidgets('05 progress', (tester) async {
    phone(tester);
    await tester.pumpWidget(seededApp());
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Progress'),
      ),
    );
    await settle(tester);
    await shot(tester, '05-progress');
  });

  testWidgets('06 library', (tester) async {
    phone(tester);
    await tester.pumpWidget(seededApp());
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Library'),
      ),
    );
    await settle(tester);
    await shot(tester, '06-library');
  });

  testWidgets('07 profile', (tester) async {
    phone(tester);
    await tester.pumpWidget(seededApp());
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Profile'),
      ),
    );
    await settle(tester);
    await shot(tester, '07-profile');
  });
}

/// The SDK's Material icon font, if this machine has one.
///
/// `FLUTTER_ROOT` is set by the flutter tool; the fallback walks up from the
/// running Dart executable (`<sdk>/bin/cache/dart-sdk/bin/dart`) for the case
/// where the test was started some other way.
File? _materialIconsFont() {
  final executable = File(Platform.resolvedExecutable);
  final candidates = <String>[
    ?Platform.environment['FLUTTER_ROOT'],
    executable.parent.parent.parent.parent.parent.path,
  ];
  for (final root in candidates) {
    final file = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (file.existsSync()) return file;
  }
  return null;
}
