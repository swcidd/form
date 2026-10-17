import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/screens/workout_details_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/fixtures.dart';

void main() {
  setUpAll(() {
    // Tests run offline; letting google_fonts hit the network makes them
    // flaky and slow. The platform font is enough to assert layout.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final today = DateTime(2026, 10, 6);

  /// Minimal shell around the route so the test owns the provider and can
  /// reach a known fixture instead of whatever the live app seeds.
  Widget harness({String? id}) {
    return ChangeNotifierProvider(
      create: (_) => seededProvider(today: today),
      child: MaterialApp(
        theme: AppTheme.light(),
        routes: {
          WorkoutDetailsScreen.routeName: (_) => const WorkoutDetailsScreen(),
        },
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                Navigator.of(context)
                    .pushNamed(WorkoutDetailsScreen.routeName, arguments: id),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, {String? id}) async {
    await tester.pumpWidget(harness(id: id));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('workout detail', () {
    testWidgets('renders the session passed through the route', (tester) async {
      await open(tester, id: 'upper-body');

      expect(find.text('Workout Detail'), findsOneWidget);
      expect(find.text('Upper Body Hypertrophy & Core'), findsWidgets);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Finish Workout'), findsOneWidget);

      // Summary pills are derived from the same object the list renders.
      expect(find.text('MIN TOTAL'), findsOneWidget);
      expect(find.text('SETS'), findsOneWidget);
    });

    testWidgets('shows an escape hatch when the workout is gone', (
      tester,
    ) async {
      await open(tester, id: 'does-not-exist');

      expect(find.text('Session not found'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('starts on a session when no route arguments are given', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Session not found'), findsOneWidget);
    });

    testWidgets('logging a set recalculates the exercise volume', (
      tester,
    ) async {
      await open(tester, id: 'upper-body');

      // Two of the four bench sets are seeded as done: 2 x 8 x 60kg.
      expect(find.text('VOLUME: 960 KG'), findsOneWidget);

      final benchSets = find.descendant(
        of: find.byType(ExpansionTile).first,
        matching: find.byType(Checkbox),
      );
      expect(benchSets, findsNWidgets(4));

      final thirdSet = benchSets.at(2);
      await tester.ensureVisible(thirdSet);
      await tester.pumpAndSettle();
      await tester.tap(thirdSet);
      await tester.pumpAndSettle();

      // The third set is 8 reps at 65kg, so 960 becomes 1480.
      expect(find.text('VOLUME: 1480 KG'), findsOneWidget);
    });

    testWidgets('finishing the session disables the finish button', (
      tester,
    ) async {
      await open(tester, id: 'upper-body');

      await tester.tap(find.text('Finish Workout'));
      await tester.pumpAndSettle();

      expect(find.text('Finished'), findsOneWidget);
      expect(find.text('Workout finished. Nice work.'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Finished'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
