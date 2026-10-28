import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/calendar_screen.dart';
import 'package:plus_one/screens/progress_screen.dart';
import 'package:plus_one/screens/set_logging_screen.dart';
import 'package:plus_one/screens/workout_detail_screen.dart';
import 'package:plus_one/screens/workout_summary_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/fixtures.dart';
import 'support/harness.dart';

Widget _screen(WorkoutProvider provider, Widget child, Brightness brightness) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  setUpAll(useOfflineFonts);

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} session screens fit a 320dp phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final provider = seededProvider(today: DateTime(2026, 10, 17));
      final workout = provider.focusWorkout!;

      final screens = <Widget>[
        SetLoggingScreen(
          route: RouteSettings(name: SetLoggingScreen.routeFor(workout.id)),
        ),
        WorkoutSummaryScreen(
          route: RouteSettings(name: WorkoutSummaryScreen.routeFor(workout.id)),
        ),
        WorkoutDetailScreen(
          route: RouteSettings(name: WorkoutDetailScreen.routeFor(workout.id)),
        ),
        const ProgressScreen(),
        const CalendarScreen(),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(_screen(provider, screen, brightness));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
      }
    });
  }

  testWidgets('logging a set advances the table and starts rest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final provider = seededProvider(today: DateTime(2026, 10, 17));
    final workout = provider.focusWorkout!;
    // A planned rest is what starts the countdown. Rest is blank by default -
    // the design's own control reads "Rest: OFF" until somebody sets one - so
    // this test says out loud that it wants one.
    provider.updateWorkout(
      workout.copyWith(
        logs: [for (final log in workout.logs) log.copyWith(restSeconds: 120)],
      ),
    );
    await tester.pumpWidget(
      _screen(
        provider,
        SetLoggingScreen(
          route: RouteSettings(name: SetLoggingScreen.routeFor(workout.id)),
        ),
        Brightness.dark,
      ),
    );
    await tester.pump();

    expect(find.text('Log set 03'), findsOneWidget);
    await tester.tap(find.text('Log set 03'));
    await tester.pump();

    expect(find.text('Log set 04'), findsOneWidget);
    expect(find.textContaining('REST /'), findsOneWidget);

    // Stop the countdown before the test tears the tree down.
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(find.textContaining('REST /'), findsNothing);
  });
}
