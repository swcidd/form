import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/set_logging_screen.dart';
import 'package:plus_one/screens/workout_summary_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

Widget _withProvider(WorkoutProvider provider, Widget screen) =>
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.light(), home: screen),
    );

/// These two screens sat behind navigation with no test ever rendering them,
/// which is how the library screen once kept a crash it could not show. Plain
/// pumps (no settle) in case the rest timer keeps a periodic clock running.
void main() {
  setUpAll(useOfflineFonts);

  testWidgets('set logging renders its session without mock chrome', (
    tester,
  ) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(
      _withProvider(
        provider,
        SetLoggingScreen(
          route: RouteSettings(name: SetLoggingScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Session not found'), findsNothing);
    // The fake iOS status bar is gone; the real one comes from the OS.
    expect(find.text('9:41'), findsNothing);
  });

  testWidgets('the summary renders its session without mock chrome', (
    tester,
  ) async {
    final provider = seededProvider();
    final workout = provider.focusWorkout!;

    await tester.pumpWidget(
      _withProvider(
        provider,
        WorkoutSummaryScreen(
          route: RouteSettings(name: WorkoutSummaryScreen.routeFor(workout.id)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Session not found'), findsNothing);
    expect(find.text('9:41'), findsNothing);
  });
}
