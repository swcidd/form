import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/library_exercise.dart';
import 'package:plus_one/auth/auth_repository.dart';
import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/profile_stats.dart';
import 'package:plus_one/models/saved_exercise.dart';
import 'package:plus_one/models/session.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/auth_provider.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/profile_screen.dart';
import 'package:plus_one/theme/app_theme.dart';
import 'package:plus_one/widgets/auth_field.dart';
import 'package:plus_one/widgets/change_password_sheet.dart';
import 'package:plus_one/widgets/stat_tile.dart';

import 'support/fake_auth.dart';
import 'support/fixtures.dart';
import 'support/harness.dart';

/// The profile tab is the one screen that must not flatter the account. A new
/// user has no history, and these tests hold it to saying so rather than
/// printing zeros as if they were achievements or quoting the stored totals
/// nothing maintains.
void main() {
  useOfflineFonts();

  final today = DateTime(2026, 3, 10);

  Widget screenWith(
    WorkoutProvider provider, {
    AuthProvider? auth,
  }) => MultiProvider(
    providers: [
      // The app hands every screen behind the shell an identity; the profile
      // reads it to say who the account belongs to.
      ChangeNotifierProvider<AuthProvider>.value(value: auth ?? signedInAuth()),
      ChangeNotifierProvider<WorkoutProvider>.value(value: provider),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const ProfileScreen()),
  );

  /// Renders the screen on a surface tall enough for all of it.
  ///
  /// The body is a scrolling column taller than the default 800x600 test
  /// surface, and a ListView only builds the children that fit. Without this the
  /// lower sections - body metrics, records, badges - are not in the tree at
  /// all, and their assertions fail for a reason that has nothing to do with
  /// them.
  Future<void> pumpProfile(
    WidgetTester tester,
    WorkoutProvider provider, {
    AuthProvider? auth,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1100, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(screenWith(provider, auth: auth));
    await tester.pumpAndSettle();
  }

  Workout session({
    required String id,
    required WorkoutStatus status,
    required List<WorkoutSet> sets,
    int durationMin = 45,
  }) {
    return Workout(
      id: id,
      title: 'Upper Body',
      date: today,
      status: status,
      durationMin: durationMin,
      estimatedKcal: 0,
      targetMuscleGroups: const ['chest'],
      equipment: const ['barbell'],
      logs: [
        ExerciseLog(
          exercise: const Exercise(
            name: 'Bench Press',
            equipment: 'barbell',
            muscleGroups: ['chest'],
          ),
          sets: sets,
        ),
      ],
    );
  }

  /// StatTile uppercases its label on the way to the screen, so the finder
  /// matches what is rendered rather than what the caller passes.
  String tileValue(WidgetTester tester, String label) =>
      tester.widget<StatTile>(find.widgetWithText(StatTile, label)).value;

  Finder fieldFor(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(AuthField)),
    matching: find.byType(TextField),
  );

  testWidgets('an account with nothing says so rather than showing a history', (
    tester,
  ) async {
    await pumpProfile(tester, WorkoutProvider(today: today));

    expect(find.text('No name yet'), findsOneWidget);
    expect(find.text('Your training stays on this device.'), findsOneWidget);
    // Nothing has been earned, so nothing may claim it has been.
    expect(find.text('PRO'), findsNothing);

    expect(tileValue(tester, 'SESSIONS'), '0');
    expect(tileValue(tester, 'STREAK (DAYS)'), '0');
    expect(tileValue(tester, 'VOLUME LIFTED (KG)'), '0');
    // A stored zero is "not set", not "weighs nothing".
    expect(tileValue(tester, 'WEIGHT (KG)'), '—');
    expect(tileValue(tester, 'RESTING HR (BPM)'), '—');

    expect(find.textContaining('Nothing logged yet'), findsOneWidget);
    expect(find.textContaining('No personal records yet'), findsOneWidget);
    expect(find.textContaining('No badges yet'), findsOneWidget);
  });

  testWidgets('counts finished sessions, and only the work inside them', (
    tester,
  ) async {
    final provider = WorkoutProvider(
      today: today,
      workouts: [
        session(
          id: 'a',
          status: WorkoutStatus.completed,
          sets: const [
            WorkoutSet(reps: 10, weightKg: 50, completed: true),
            WorkoutSet(reps: 10, weightKg: 50, completed: true),
          ],
          durationMin: 45,
        ),
        session(
          id: 'b',
          status: WorkoutStatus.completed,
          sets: const [
            WorkoutSet(reps: 5, weightKg: 100, completed: true),
            // Planned but never ticked: it must not count as lifted.
            WorkoutSet(reps: 5, weightKg: 100),
          ],
          durationMin: 30,
        ),
        session(
          id: 'c',
          status: WorkoutStatus.planned,
          sets: const [WorkoutSet(reps: 10, weightKg: 80)],
          durationMin: 60,
        ),
      ],
    );

    await pumpProfile(tester, provider);

    expect(tileValue(tester, 'SESSIONS'), '2');
    // 1,000 + 500 kg of completed sets; the planned session and the unticked
    // set add nothing.
    expect(tileValue(tester, 'VOLUME LIFTED (KG)'), '1,500');
    // 45 + 30 minutes, not the planned hour.
    expect(tileValue(tester, 'TIME TRAINED'), '1.3h');
    expect(tileValue(tester, 'STREAK (DAYS)'), '1');
    expect(find.textContaining('Nothing logged yet'), findsNothing);
  });

  testWidgets('the weekly target is edited here', (tester) async {
    final provider = WorkoutProvider(today: today);
    await pumpProfile(tester, provider);

    expect(find.text('0 of 4 this week'), findsOneWidget);

    await tester.tap(find.byTooltip('More sessions per week'));
    await tester.pumpAndSettle();

    expect(provider.weeklyGoal, 5);
    expect(find.text('0 of 5 this week'), findsOneWidget);

    await tester.tap(find.byTooltip('Fewer sessions per week'));
    await tester.pumpAndSettle();

    expect(provider.weeklyGoal, 4);
  });

  testWidgets('the target cannot be stepped past what the store accepts', (
    tester,
  ) async {
    final provider = WorkoutProvider(today: today)..setWeeklyGoal(1);
    await pumpProfile(tester, provider);

    await tester.tap(find.byTooltip('Fewer sessions per week'));
    await tester.pumpAndSettle();
    expect(provider.weeklyGoal, 1, reason: 'the control offered a zero target');

    provider.setWeeklyGoal(WorkoutProvider.weeklyGoalMax);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More sessions per week'));
    await tester.pumpAndSettle();
    expect(
      provider.weeklyGoal,
      WorkoutProvider.weeklyGoalMax,
      reason: 'the control offered a target the store would refuse',
    );
  });

  testWidgets('a profiled account shows who it is and what it earned', (
    tester,
  ) async {
    await pumpProfile(tester, seededProvider(today: today));

    expect(find.text('Alex Mercer'), findsOneWidget);
    expect(
      find.text('@alex_lift92 · Athlete · Since Jan 2023'),
      findsOneWidget,
    );
    expect(find.text('PRO'), findsOneWidget);
    expect(tileValue(tester, 'WEIGHT (KG)'), '74.5');

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('140 kg'), findsOneWidget);
    expect(find.textContaining('No personal records yet'), findsNothing);
    expect(find.textContaining('No badges yet'), findsNothing);
  });

  testWidgets('an imperial profile reads height and weight in its units', (
    tester,
  ) async {
    final provider = WorkoutProvider(
      today: today,
      profile: ProfileStats.empty().copyWith(
        heightCm: 182,
        weightKg: 74.5,
        heightImperial: true,
        weightImperial: true,
      ),
    );
    await pumpProfile(tester, provider);

    expect(tileValue(tester, 'WEIGHT (LB)'), '164.2');
    expect(tileValue(tester, 'HEIGHT (FT)'), '6\'0"');
  });

  testWidgets('the body can be edited from the profile', (tester) async {
    final now = DateTime.now();
    final born = DateTime(now.year - 30, 1, 1);
    final provider = WorkoutProvider(
      today: today,
      profile: ProfileStats.empty().copyWith(
        dateOfBirth: born,
        heightCm: 180,
        weightKg: 80,
      ),
    );
    await pumpProfile(tester, provider);

    expect(tileValue(tester, 'AGE'), '30');

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT BODY.'), findsOneWidget);

    Future<void> choose(int list, String value) async {
      final button = find.byType(DropdownButton<int>).at(list);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();
      final items = find.widgetWithText(DropdownMenuItem<int>, value);
      if (list == 2) {
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

    await choose(0, '1');
    await choose(1, 'January');
    await choose(2, '${now.year - 31}');
    await tester.enterText(fieldFor('CENTIMETRES'), '182');
    await tester.enterText(fieldFor('KILOGRAMMES'), '82');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(provider.profile.dateOfBirth, DateTime(now.year - 31, 1, 1));
    expect(provider.profile.age, 31);
    expect(provider.profile.heightCm, 182);
    expect(provider.profile.weightKg, 82);
    expect(tileValue(tester, 'AGE'), '31');
    expect(tileValue(tester, 'HEIGHT (CM)'), '182');
  });

  testWidgets('editing in imperial saves the units the profile shows', (
    tester,
  ) async {
    final now = DateTime.now();
    final provider = WorkoutProvider(
      today: today,
      profile: ProfileStats.empty().copyWith(
        dateOfBirth: DateTime(now.year - 30, 1, 1),
        heightCm: 180,
        weightKg: 80,
      ),
    );
    await pumpProfile(tester, provider);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('FEET').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('POUNDS').last);
    await tester.pumpAndSettle();

    await tester.enterText(fieldFor('FEET'), '5');
    await tester.enterText(fieldFor('INCHES'), '10');
    await tester.enterText(fieldFor('POUNDS'), '165');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(provider.profile.heightImperial, isTrue);
    expect(provider.profile.weightImperial, isTrue);
    expect(provider.profile.heightCm, closeTo(177.8, 0.01));
    expect(provider.profile.weightKg, closeTo(74.84, 0.01));
    expect(tileValue(tester, 'HEIGHT (FT)'), '5\'10"');
    expect(tileValue(tester, 'WEIGHT (LB)'), '165.0');
  });

  group('the account behind the profile', () {
    late FakeAuth fake;
    late AuthProvider auth;

    /// Signs in behind a store the test can read, as the app does.
    Future<void> signedIn(
      WidgetTester tester,
      WorkoutProvider provider, {
      Session? session,
    }) async {
      fake = FakeAuth(session: session ?? namedSession());
      auth = AuthProvider(repository: fake);
      await auth.restore();
      await pumpProfile(tester, provider, auth: auth);
    }

    /// Taps a row of the account card, scrolling to it first: the card is the
    /// last thing on a long screen.
    Future<void> tapRow(WidgetTester tester, String label) async {
      final finder = find.text(label);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('names the account it belongs to', (tester) async {
      await signedIn(tester, WorkoutProvider(today: today));

      expect(find.text('sam@example.com'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
    });

    testWidgets('says when there is no account, and offers no delete', (
      tester,
    ) async {
      await signedIn(
        tester,
        WorkoutProvider(today: today),
        session: Session.device(issuedAt: today),
      );

      expect(find.text('Offline account'), findsOneWidget);
      expect(find.textContaining('this device is the account'), findsOneWidget);
      // Nothing to delete: no password to lose and no address to be locked out
      // of. Signing out is the whole of the way back.
      expect(find.text('Delete account'), findsNothing);
      // And no password to change: the device account has none.
      expect(find.text('Change password'), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('signing out ends the session without asking', (tester) async {
      await signedIn(tester, WorkoutProvider(today: today));

      await tapRow(tester, 'Sign out');

      // Nothing is lost by it, so nothing needed confirming.
      expect(find.text('Delete this account?'), findsNothing);
      expect(fake.signOutCount, 1);
      expect(auth.session, isNull);
    });

    testWidgets('deleting asks first, and names what it would take', (
      tester,
    ) async {
      final provider = WorkoutProvider(
        today: today,
        workouts: [
          session(id: 'w1', status: WorkoutStatus.completed, sets: const []),
          session(id: 'w2', status: WorkoutStatus.completed, sets: const []),
        ],
        saved: [
          SavedExercise(
            exercise: const LibraryExercise(
              name: 'Barbell Curl',
              primaryMuscles: ['biceps'],
              instructions: ['Curl the bar.'],
              equipment: ['Barbell'],
              category: 'strength',
            ),
            savedAt: today,
          ),
        ],
      );
      await signedIn(tester, provider);

      await tapRow(tester, 'Delete account');

      // Said in the account's own numbers rather than in general terms about
      // data: "delete your account" invites the question of what that includes.
      expect(find.text('Delete this account?'), findsOneWidget);
      expect(
        find.textContaining('2 sessions, your profile and 1 saved exercise'),
        findsOneWidget,
      );

      await tapRow(tester, 'Keep my account');
      expect(find.text('Delete this account?'), findsNothing);
      expect(fake.lastUserId, isNull);
      expect(auth.session?.userId, 'acct_1');

      await tapRow(tester, 'Delete account');
      await tapRow(tester, 'Delete');

      expect(fake.lastUserId, 'acct_1');
      expect(auth.session, isNull);
    });

    group('changing the password', () {
      /// The field carrying [label] inside the sheet.
      Finder passwordField(String label) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(AuthField),
        ),
        matching: find.byType(TextField),
      );

      /// Taps a control inside the sheet.
      ///
      /// The account card behind it has a row with the same words, so a bare
      /// `find.text` would be ambiguous once the sheet is up.
      Future<void> tapInSheet(WidgetTester tester, String label) async {
        final finder = find.descendant(
          of: find.byType(ChangePasswordSheet),
          matching: find.text(label),
        );
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> openSheet(WidgetTester tester) async {
        await signedIn(tester, WorkoutProvider(today: today));
        await tapRow(tester, 'Change password');
        expect(find.byType(ChangePasswordSheet), findsOneWidget);
      }

      Future<void> fillIn(
        WidgetTester tester, {
        required String current,
        required String updated,
      }) async {
        await tester.enterText(passwordField('CURRENT PASSWORD'), current);
        await tester.enterText(passwordField('NEW PASSWORD'), updated);
      }

      testWidgets('asks for the current password and a new one', (
        tester,
      ) async {
        await openSheet(tester);

        await tapInSheet(tester, 'Change password');

        expect(find.text('Enter your current password.'), findsOneWidget);
        expect(find.text('Choose a password.'), findsOneWidget);
        expect(fake.lastCurrentPassword, isNull);
      });

      testWidgets('a wrong current password is refused under that field', (
        tester,
      ) async {
        await openSheet(tester);
        fake.changeError = const AuthException(AuthFailure.invalidCredentials);

        await fillIn(tester, current: 'old-password', updated: 'new-password');
        await tapInSheet(tester, 'Change password');

        // Not the sign-in screen's "that email and password do not match":
        // there is no email here, and this form can say what is actually wrong.
        expect(find.text('That is not your current password.'), findsOneWidget);
        expect(find.byType(ChangePasswordSheet), findsOneWidget);
      });

      testWidgets('a good change closes the sheet and says so', (tester) async {
        await openSheet(tester);

        await fillIn(tester, current: 'old-password', updated: 'new-password');
        await tapInSheet(tester, 'Change password');

        expect(fake.lastUserId, 'acct_1');
        expect(fake.lastCurrentPassword, 'old-password');
        expect(fake.lastNewPassword, 'new-password');
        expect(find.byType(ChangePasswordSheet), findsNothing);
        expect(find.text('Password changed.'), findsOneWidget);
      });
    });
  });
}
