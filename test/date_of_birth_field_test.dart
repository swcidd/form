import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/date_of_birth_field.dart';

import 'support/harness.dart';

/// Three lists have to agree before the field has a date. These tests hold it
/// to reporting null until they do — and to letting go of a day that the new
/// month does not have.
void main() {
  setUpAll(useOfflineFonts);

  /// The three lists, in the order the field lays them out.
  const month = 0;
  const day = 1;
  const year = 2;

  Future<void> pick(
    WidgetTester tester,
    int list,
    String value, {
    bool scroll = false,
  }) async {
    // The button by position rather than by its current text: once a month is
    // chosen the prompt is gone, and the test still has to open it again.
    final button = find.byType(DropdownButton<int>).at(list);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button, warnIfMissed: false);
    await tester.pumpAndSettle();

    final items = find.widgetWithText(DropdownMenuItem<int>, value);
    if (scroll) {
      // The menu builds its rows lazily, so a day near the end does not exist
      // until the list has been dragged to it.
      await tester.scrollUntilVisible(
        items,
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    final item = items.last;
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<ValueNotifier<DateTime?>> pumpField(WidgetTester tester) async {
    final reported = ValueNotifier<DateTime?>(null);
    addTearDown(reported.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: DateOfBirthField(
              label: 'DATE OF BIRTH',
              onChanged: (date) => reported.value = date,
            ),
          ),
        ),
      ),
    );

    return reported;
  }

  testWidgets('reports nothing until month, day and year all agree', (
    tester,
  ) async {
    final reported = await pumpField(tester);
    final yearOfBirth = DateTime.now().year - 13;

    await pick(tester, month, 'January');
    expect(reported.value, isNull);

    await pick(tester, day, '1');
    expect(reported.value, isNull);

    await pick(tester, year, '$yearOfBirth');
    expect(reported.value, DateTime(yearOfBirth));
  });

  testWidgets('drops a day the new month does not have', (tester) async {
    final reported = await pumpField(tester);
    final yearOfBirth = DateTime.now().year - 13;

    await pick(tester, month, 'March');
    await pick(tester, day, '31', scroll: true);
    await pick(tester, year, '$yearOfBirth');
    expect(reported.value, DateTime(yearOfBirth, 3, 31));

    await pick(tester, month, 'February');

    // 31 February is not a date, so the field reports nothing rather than
    // rolling it forward into March.
    expect(reported.value, isNull);
    expect(find.text('Select day'), findsOneWidget);
  });

  testWidgets('a disabled field does not open its lists', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DateOfBirthField(
            label: 'DATE OF BIRTH',
            enabled: false,
            onChanged: (_) => changes++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Select month'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('January'), findsNothing);
    expect(changes, 0);
  });
}
