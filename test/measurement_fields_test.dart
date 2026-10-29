import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/theme/app_colors.dart';
import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/measurement_fields.dart';

import 'support/harness.dart';

/// The unit control is two choices, and the chosen one carries the design
/// system's green rather than being only bold or underlined.
void main() {
  setUpAll(useOfflineFonts);

  Color? fill(WidgetTester tester, String label) {
    final material = find
        .ancestor(of: find.text(label).first, matching: find.byType(Material))
        .first;
    return tester.widget<Material>(material).color;
  }

  testWidgets('height highlights centimetres until feet is chosen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: HeightField(onChanged: (_) {})),
      ),
    );

    expect(find.text('FEET'), findsOneWidget);
    expect(find.text('CENTIMETERS'), findsOneWidget);
    expect(fill(tester, 'CENTIMETERS'), AppColors.lime);
    expect(fill(tester, 'FEET'), isNot(AppColors.lime));

    await tester.tap(find.text('FEET'));
    await tester.pumpAndSettle();

    expect(fill(tester, 'FEET'), AppColors.lime);
    expect(fill(tester, 'CENTIMETERS'), isNot(AppColors.lime));
  });

  testWidgets('weight highlights kilograms until pounds is chosen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: WeightField(onChanged: (_) {})),
      ),
    );

    expect(find.text('POUNDS'), findsOneWidget);
    expect(find.text('KILOGRAMS'), findsOneWidget);
    expect(fill(tester, 'KILOGRAMS'), AppColors.lime);
    expect(fill(tester, 'POUNDS'), isNot(AppColors.lime));

    await tester.tap(find.text('POUNDS'));
    await tester.pumpAndSettle();

    expect(fill(tester, 'POUNDS'), AppColors.lime);
    expect(fill(tester, 'KILOGRAMS'), isNot(AppColors.lime));
  });
}
