import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/exercise_library.dart';
import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/exercise_picker_sheet.dart';

import 'support/harness.dart';

const _bench = LibraryExercise(
  name: 'Bench Press',
  primaryMuscles: ['Chest'],
  equipment: ['Barbell'],
  category: 'strength',
);

const _curl = LibraryExercise(
  name: 'Dumbbell Curl',
  primaryMuscles: ['Biceps'],
  equipment: ['Dumbbell'],
  category: 'strength',
);

void main() {
  setUpAll(useOfflineFonts);

  testWidgets('filters the catalogue and returns the chosen exercise', (
    tester,
  ) async {
    LibraryExercise? picked;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await ExercisePickerSheet.show(
                    context,
                    loadExercises: () async => [_bench, _curl],
                  );
                },
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Curl'), findsOneWidget);

    // Equipment is searchable too, so "barbell" does not require knowing the
    // exercise's exact name.
    await tester.enterText(find.byType(TextField), 'barbell');
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Curl'), findsNothing);

    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    expect(picked?.name, 'Bench Press');
    expect(find.text('Open picker'), findsOneWidget);
  });

  testWidgets('says when the search has no match', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => ExercisePickerSheet.show(
                  context,
                  loadExercises: () async => [_bench, _curl],
                ),
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'not an exercise');
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
    expect(
      find.text('Try a different name, muscle or piece of equipment.'),
      findsOneWidget,
    );
  });
}
