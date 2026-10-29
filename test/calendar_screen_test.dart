import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/widgets/app_nav_bar.dart';

import 'support/harness.dart';

/// A session with nothing on it, for the tests that care only about how many
/// sit on a day.
Workout _session(
  String id,
  DateTime date, {
  WorkoutStatus status = WorkoutStatus.planned,
  String title = 'Push Day',
}) => Workout(
  id: id,
  title: title,
  date: date,
  status: status,
  durationMin: 45,
  estimatedKcal: 300,
  targetMuscleGroups: const [],
  equipment: const [],
  logs: const [],
);

/// The calendar is the Workout tab, so every test arrives the way a user does:
/// from the bar rather than by constructing the screen.
void main() {
  setUpAll(useOfflineFonts);

  /// Monday 26 October 2026. Fixed rather than `DateTime.now()` so the labels
  /// under test do not change on the day the suite happens to run.
  final today = DateTime(2026, 10, 26);

  /// The frame the calendar is drawn for. The default test window is wider and
  /// shorter than a phone, which would hide the vertical budget the screen has.
  Future<void> pumpApp(WidgetTester tester, Widget app) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  Future<void> openWorkoutTab(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Workout'),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('calendar', () {
    testWidgets('opens on today with the day it has planned', (tester) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      expect(find.text('PLAN THE WEEK.'), findsOneWidget);
      expect(find.text('OCT 26 – 28'), findsOneWidget);
      expect(find.text('MONDAY 26 OCT'), findsOneWidget);
      expect(find.text('1 SESSION'), findsOneWidget);
      expect(find.text('Start workout'), findsOneWidget);
    });

    testWidgets('an empty account offers the next step', (tester) async {
      await pumpApp(tester, emptyApp());
      await openWorkoutTab(tester);

      expect(find.text('no workouts scheduled'), findsOneWidget);
      expect(find.text('0 SESSIONS'), findsOneWidget);
      expect(find.text('Nothing planned yet'), findsOneWidget);
      expect(find.text('Plan a workout'), findsOneWidget);
      expect(find.text('Start workout'), findsNothing);
    });

    testWidgets('the week range runs Monday to Sunday', (tester) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.text('OCT 26 – NOV 1'), findsOneWidget);
      // M T W T F S S, so the repeated letters appear twice.
      expect(find.text('T'), findsNWidgets(2));
      expect(find.text('S'), findsNWidgets(2));
    });

    testWidgets('next moves the window forward one range', (tester) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next Week'));
      await tester.pumpAndSettle();

      expect(find.text('NOV 2 – 8'), findsOneWidget);
      expect(find.text('MONDAY 2 NOV'), findsOneWidget);
    });

    testWidgets('previous steps back over the boundary', (tester) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.byTooltip('Previous 3 days'));
      await tester.pumpAndSettle();

      expect(find.text('OCT 23 – 25'), findsOneWidget);
      expect(find.text('FRIDAY 23 OCT'), findsOneWidget);
    });

    testWidgets('the month range names the month', (tester) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.text('OCTOBER 2026'), findsOneWidget);
      // October 2026 starts on a Thursday and ends on a Saturday: five rows.
      expect(find.text('26'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('selecting a day swaps the list under the calendar', (
      tester,
    ) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      // The 27th is a rest day in the fixtures, so selecting it has to swap a
      // populated day for an empty one.
      await tester.tap(find.text('27'));
      await tester.pumpAndSettle();

      expect(find.text('TUESDAY 27 OCT'), findsOneWidget);
      expect(find.text('0 SESSIONS'), findsOneWidget);
      expect(find.text('Nothing planned yet'), findsOneWidget);
      expect(find.text('Plan a workout'), findsOneWidget);
    });

    testWidgets('a range keeps every session in the window marked', (
      tester,
    ) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // The seeded plan is today's, so the legend has to report the window as
      // occupied rather than reading only the selected day.
      expect(find.text('workout planned'), findsOneWidget);
    });

    testWidgets('the legend reads the window even on a rest day', (
      tester,
    ) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // The 27th has nothing on it; the rest of the week does.
      await tester.tap(find.text('27'));
      await tester.pumpAndSettle();

      expect(find.text('TUESDAY 27 OCT'), findsOneWidget);
      expect(find.text('0 SESSIONS'), findsOneWidget);
      expect(find.text('workout planned'), findsOneWidget);
    });

    testWidgets('a six-row month fits its card', (tester) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();

      // November 2026 starts on a Sunday, so a Monday-first grid needs six
      // rows: the last days of October and the first of December.
      expect(find.text('NOVEMBER 2026'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      // The 6th appears twice - once in November, once in December - which is
      // what the sixth row is there to hold.
      expect(find.text('6'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a month cursor on the 31st steps month by month', (
      tester,
    ) async {
      // March 31st is the day the old arithmetic rolled into May: the 31st of
      // April does not exist.
      await pumpApp(tester, seededApp(today: DateTime(2026, 3, 31)));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(find.text('MARCH 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();
      expect(find.text('APRIL 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Month'));
      await tester.pumpAndSettle();
      expect(find.text('MARCH 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous Month'));
      await tester.pumpAndSettle();
      expect(find.text('FEBRUARY 2026'), findsOneWidget);
    });

    testWidgets('switching ranges keeps the selection on screen', (
      tester,
    ) async {
      await pumpApp(tester, seededApp(today: today));
      await openWorkoutTab(tester);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next Month'));
      await tester.pumpAndSettle();

      // The 31st is a leading cell of the November grid: October, borrowed to
      // keep the rows rectangular. The 3-day window that follows would keep
      // the cursor in November and highlight nothing.
      await tester.tap(find.text('31'));
      await tester.pumpAndSettle();
      expect(find.text('SATURDAY 31 OCT'), findsOneWidget);

      await tester.tap(find.text('3 days'));
      await tester.pumpAndSettle();

      expect(find.text('OCT 31 – NOV 2'), findsOneWidget);
      expect(find.text('SATURDAY 31 OCT'), findsOneWidget);

      // The selected cell is the day the heading names, and it says so to a
      // screen reader instead of reading out a bare "31".
      final selectedCell = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Saturday 31 October, 1 session',
        ),
      );
      expect(selectedCell.properties.button, isTrue);
      expect(selectedCell.properties.selected, isTrue);
    });

    testWidgets('two sessions on one day do not overflow the grid', (
      tester,
    ) async {
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          _session('double-a', DateTime(2026, 10, 28)),
          _session('double-b', DateTime(2026, 10, 28)),
        ],
      );
      await pumpApp(tester, emptyAppWith(provider));
      await openWorkoutTab(tester);

      await tester.tap(find.text('2 weeks'));
      await tester.pumpAndSettle();

      expect(find.text('OCT 26 – NOV 8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a finished day offers to view rather than start', (
      tester,
    ) async {
      final provider = WorkoutProvider(
        today: today,
        workouts: [_session('done', today, status: WorkoutStatus.completed)],
      );
      await pumpApp(tester, emptyAppWith(provider));
      await openWorkoutTab(tester);

      expect(find.text('1 SESSION'), findsOneWidget);
      expect(find.text('View workout'), findsOneWidget);
      expect(find.text('Start workout'), findsNothing);
    });

    testWidgets('starting a day prefers the session still to be done', (
      tester,
    ) async {
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          _session(
            'done',
            today,
            status: WorkoutStatus.completed,
            title: 'Morning Push',
          ),
          _session('open', today, title: 'Evening Pull'),
        ],
      );
      await pumpApp(tester, emptyAppWith(provider));
      await openWorkoutTab(tester);

      expect(find.text('2 SESSIONS'), findsOneWidget);
      await tester.tap(find.text('Start workout'));
      await tester.pumpAndSettle();

      // The finished session is just as much "first" as the planned one, so
      // the action must look for the open session rather than the list head.
      expect(find.text('EVENING PULL'), findsOneWidget);
    });

    testWidgets('planning a workout dates it on the selected day', (
      tester,
    ) async {
      final provider = WorkoutProvider(today: today);
      await pumpApp(tester, emptyAppWith(provider));
      await openWorkoutTab(tester);

      await tester.tap(find.text('27'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan a workout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The picker runs first, then the form.
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(provider.workouts.single.date, DateTime(2026, 10, 27));
    });
  });
}
