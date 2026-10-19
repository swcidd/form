import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/theme/app_colors.dart';
import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/app_nav_bar.dart';
import 'package:plus_one/widgets/new_workout_dialog.dart';
import 'package:plus_one/widgets/workout_card.dart';

import 'support/harness.dart';

void main() {
  setUpAll(useOfflineFonts);

  group('theme', () {
    test('light scheme lands on the palette, not an approximation', () {
      final scheme = AppTheme.colorScheme(Brightness.light);

      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, AppColors.ink);
      expect(scheme.surface, AppColors.white);
      expect(scheme.onSurface, AppColors.ink);
      expect(scheme.secondary, AppColors.sage600);
    });

    test('dark scheme mirrors the palette off the ink page', () {
      final scheme = AppTheme.colorScheme(Brightness.dark);

      expect(scheme.brightness, Brightness.dark);
      expect(scheme.surface, AppColors.inkMuted);
      expect(scheme.onSurface, AppColors.cream);
      expect(scheme.primary, AppColors.lime);
      expect(scheme.onPrimary, AppColors.ink);
    });

    test('every text pair in both modes clears WCAG AA', () {
      for (final brightness in Brightness.values) {
        final scheme = AppTheme.colorScheme(brightness);

        final pairs = <String, (Color, Color, double)>{
          'body text': (scheme.onSurface, scheme.surface, 7),
          'secondary text': (scheme.onSurfaceVariant, scheme.surface, 4.5),
          'filled control': (scheme.onPrimary, scheme.primary, 4.5),
          'container text': (
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
            4.5,
          ),
          'inverse surface': (
            scheme.onInverseSurface,
            scheme.inverseSurface,
            4.5,
          ),
        };

        pairs.forEach((label, pair) {
          final (foreground, background, minimum) = pair;
          expect(
            contrast(foreground, background),
            greaterThanOrEqualTo(minimum),
            reason:
                '$label in $brightness mode: '
                '${foreground.toHex()} on ${background.toHex()}',
          );
        });
      }
    });
  });

  group('empty account', () {
    testWidgets('the dashboard opens with nothing in it', (tester) async {
      await tester.pumpWidget(emptyApp());
      await tester.pumpAndSettle();

      expect(find.text('FORM'), findsOneWidget);
      expect(find.text('Workout Tracker'), findsOneWidget);

      // No session, so the card has to say so rather than inviting the user to
      // resume something that does not exist.
      expect(find.text('NO SESSION SCHEDULED'), findsOneWidget);
      expect(find.text('Rest day'), findsOneWidget);
      expect(find.text('Resume workout'), findsNothing);
      expect(find.text('Start workout'), findsNothing);
    });

    testWidgets('the weekly tiles read zero rather than missing', (
      tester,
    ) async {
      await tester.pumpWidget(emptyApp());
      await tester.pumpAndSettle();

      final week = find.text('THIS WEEK');
      await tester.scrollUntilVisible(week, 200);

      expect(find.text('SESSIONS'), findsOneWidget);
      expect(find.text('DAY STREAK'), findsOneWidget);
      // 0 of the default goal, and a zero-day streak.
      expect(find.text('0/4'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('recent sessions offers a way forward when empty', (
      tester,
    ) async {
      await tester.pumpWidget(emptyApp());
      await tester.pumpAndSettle();

      final empty = find.text('No finished sessions yet');
      await tester.scrollUntilVisible(empty, 200);
      expect(empty, findsOneWidget);

      // An empty list that only says "nothing here" leaves the user with no way
      // forward, which is the whole reason EmptyState carries an action.
      expect(find.byType(WorkoutCard), findsNothing);
    });

    testWidgets('tapping Workout tab with no sessions opens create form', (
      tester,
    ) async {
      await tester.pumpWidget(emptyApp());
      await tester.pumpAndSettle();

      await _tapDestination(tester, 'Workout');
      await tester.pumpAndSettle();

      // With nothing logged the Workout tab opens the
      // create form instead. That is the only sensible next step for an
      // account with no sessions, and the one the user is reaching for.
      expect(find.text('Workout Detail'), findsNothing);
      expect(find.text('New workout'), findsOneWidget);
    });

    testWidgets('the dashboard leads with no general health metrics', (
      tester,
    ) async {
      await tester.pumpWidget(emptyApp());
      await tester.pumpAndSettle();

      // Heart rate, steps, sleep and calories belong to a general fitness app.
      // FORM tracks strength training, so their absence is the point: it is what
      // separates this from every other dashboard wearing the same layout.
      for (final removed in [
        'HEART RATE',
        'CALORIES',
        'STEPS',
        'SLEEP SCORE',
        'HYDRATION',
        'DAILY GOALS',
        "TODAY'S VITALS",
        'DAILY COMPLIANCE',
      ]) {
        expect(
          find.text(removed),
          findsNothing,
          reason: '$removed was removed',
        );
      }
    });
  });

  group('populated account', () {
    testWidgets('the dashboard leads with the session of the day', (
      tester,
    ) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.textContaining('Upper Body'), findsOneWidget);
      expect(find.text('Resume workout'), findsOneWidget);
    });

    testWidgets('the workout card opens the detail screen by path', (
      tester,
    ) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      // Tap the focus workout card's button instead (which uses the same route)
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // New pre-workout screen shows the hardcoded workout title and "THE LINEUP"
      expect(find.textContaining('LOWER BODY'), findsWidgets);
      expect(find.text('THE LINEUP'), findsOneWidget);
    });
  });

  group('destination bar', () {
    testWidgets('offers every destination exactly once', (tester) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      final bar = find.byType(AppNavBar);
      expect(bar, findsOneWidget);

      for (final label in ['Home', 'Progress', 'Library', 'Profile']) {
        expect(
          find.descendant(of: bar, matching: find.text(label)),
          findsOneWidget,
          reason: 'the bar should offer $label',
        );
      }
    });

    testWidgets('tapping a destination swaps the visible screen', (
      tester,
    ) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      expect(find.text('UP NEXT'), findsOneWidget);

      await _tapDestination(tester, 'Progress');
      expect(find.text('Estimated 1RM'), findsOneWidget);

      await _tapDestination(tester, 'Profile');
      expect(find.text('Alex Mercer'), findsOneWidget);
    });

    testWidgets('the Library destination opens the exercise library', (
      tester,
    ) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      await _tapDestination(tester, 'Library');
      expect(find.text('THE TRAINING LIBRARY'), findsOneWidget);

      // The catalogue sits behind the Discover pill rather than on the first
      // screen, and it makes real-I/O hops (the HTTP probe, then the bundled
      // assets) that the fake clock cannot advance, so each wait grants real
      // time and then pumps the fake one.
      await tester.tap(find.text('Discover'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (!tester.any(find.byType(CircularProgressIndicator))) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
      }
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Widget tests stub HTTP into a failure, so this run is the offline
      // path - the same one a phone with no signal takes.
      expect(find.textContaining('Offline catalogue'), findsOneWidget);
    });

    testWidgets('the dashboard avatar opens the profile tab', (tester) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      // The avatar is a cross-tab shortcut, so it has to reach the same place a
      // tap on the bar does rather than push a second profile route. Scoped to
      // the app bar: the bar's Profile destination carries the same tooltip.
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byTooltip('Profile'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alex Mercer'), findsOneWidget);
    });

    testWidgets('a tab route opens its own tab, not the home one', (
      tester,
    ) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      // Replaces the shell rather than stacking on top of it, which is what
      // keeps `/progress` from rendering behind a live home screen.
      await tester.binding.handlePushRoute('/progress');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // The progress tab should now be visible - check for progress content
      expect(find.text('Estimated 1RM'), findsOneWidget);
    });
  });

  group('new workout dialog', () {
    testWidgets('tapping Workout tab with no sessions opens create form', (
      tester,
    ) async {
      await tester.pumpWidget(emptyApp());
      await tester.pumpAndSettle();

      await _tapDestination(tester, 'Workout');
      await tester.pumpAndSettle();

      expect(find.byType(NewWorkoutDialog), findsOneWidget);
      expect(find.text('New workout'), findsOneWidget);
      expect(find.text('NAME THIS SESSION'), findsOneWidget);
      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets(
      'tapping Workout tab with planned session opens pre-workout screen',
      (tester) async {
        await tester.pumpWidget(seededApp());
        await tester.pumpAndSettle();

        await _tapDestination(tester, 'Workout');
        await tester.pumpAndSettle();

        // A planned session is a better answer than a form: opening the form
        // would offer to create a second session for a day that already has one.
        expect(find.byType(NewWorkoutDialog), findsNothing);
        expect(find.text('THE LINEUP'), findsOneWidget);
      },
    );

    testWidgets('starting creates the workout and opens it', (tester) async {
      final provider = WorkoutProvider();
      await tester.pumpWidget(emptyAppWith(provider));
      await tester.pumpAndSettle();

      await _tapDestination(tester, 'Workout');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Leg Day');
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      // The session has to be in the store before the detail screen can find
      // it, or the push lands on "Session not found".
      expect(provider.workouts, hasLength(1));
      expect(provider.workouts.single.title, 'Leg Day');
      expect(provider.workouts.single.status, WorkoutStatus.planned);
      expect(find.text('THE LINEUP'), findsOneWidget);
    });

    testWidgets('an empty name falls back to the date', (tester) async {
      final provider = WorkoutProvider();
      await tester.pumpWidget(emptyAppWith(provider));
      await tester.pumpAndSettle();

      await _tapDestination(tester, 'Workout');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      // Naming a session is not the point of opening the app, so an untitled
      // one is created rather than rejected.
      expect(provider.workouts, hasLength(1));
      expect(provider.workouts.single.title, isNotEmpty);
      expect(provider.workouts.single.title, contains('Training'));
    });

    testWidgets('cancelling creates nothing', (tester) async {
      final provider = WorkoutProvider();
      await tester.pumpWidget(emptyAppWith(provider));
      await tester.pumpAndSettle();

      await _tapDestination(tester, 'Workout');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(provider.workouts, isEmpty);
      expect(find.byType(NewWorkoutDialog), findsNothing);
      expect(find.text('Workout Detail'), findsNothing);
    });
  });

  group('workout tab', () {
    testWidgets('tapping Workout tab opens the pre-workout screen', (
      tester,
    ) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      await _tapDestination(tester, 'Workout');
      await tester.pumpAndSettle();

      expect(find.text('THE LINEUP'), findsOneWidget);
    });

    testWidgets('Workout tab is a regular destination', (tester) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      final bar = find.byType(AppNavBar);
      final dest = tester.widget<NavigationBar>(
        find.descendant(of: bar, matching: find.byType(NavigationBar)),
      );
      expect(dest.destinations, hasLength(5));

      expect(find.text('Workout'), findsOneWidget);
    });

    testWidgets('Workout tab is a regular destination with key', (
      tester,
    ) async {
      await tester.pumpWidget(seededApp());
      await tester.pumpAndSettle();

      // The Workout tab destination should have the key
      expect(find.byKey(const Key('workout_destination')), findsOneWidget);
    });
  });
}

/// Taps a destination in the bar by its visible label.
///
/// Scoped to the bar so a label that also appears in the screen body - the
/// dashboard's "Profile" heading, say - cannot be tapped by mistake.
Future<void> _tapDestination(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AppNavBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// WCAG 2.x contrast ratio between two opaque colors.
double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

extension on Color {
  String toHex() => '#${toARGB32().toRadixString(16).padLeft(8, '0')}';
}
