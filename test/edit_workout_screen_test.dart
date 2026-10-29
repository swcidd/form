import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plus_one/models/taxonomy.dart';
import 'package:plus_one/models/workout.dart';
import 'package:plus_one/providers/workout_provider.dart';
import 'package:plus_one/screens/edit_workout_screen.dart';
import 'package:plus_one/theme/app_theme.dart';

import 'support/harness.dart';
import 'support/seed_data.dart';

/// The edit screen is the first place a session's classification and name can
/// be changed, so these tests hold it to two things the rest of the app relies
/// on: the controls start from the record they were handed, and Save writes the
/// edited record through the store rather than to a screen-local copy.
void main() {
  useOfflineFonts();

  final today = DateTime(2026, 3, 10);

  /// A session that already answers all three classification questions, so each
  /// group has a current value to seed from and to replace.
  Workout fixture() => upperBodyPlan(today).copyWith(
    modality: Modality.cardio,
    split: WorkoutSplit.push,
    goal: TrainingGoal.hypertrophy,
  );

  /// Opens the editor on the route for [id] over [provider].
  ///
  /// The screen is pushed rather than set as the root so the value it pops with
  /// can be read back: saving is meant to hand the updated workout to whoever
  /// opened the screen, and a root-mounted screen has nobody to hand it to.
  /// The returned list's single element is that value once the screen pops.
  Future<List<Workout?>> openEditor(
    WidgetTester tester,
    WorkoutProvider provider,
    String id,
  ) async {
    final popped = <Workout?>[null];
    // Tall enough for every group at once: the pills wrap, and a group below
    // the default 600px surface would not be hit by a tap on it.
    await tester.binding.setSurfaceSize(const Size(1000, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider<WorkoutProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    popped[0] = await Navigator.of(context).push<Workout>(
                      MaterialPageRoute(
                        builder: (_) => EditWorkoutScreen(
                          route: RouteSettings(
                            name: EditWorkoutScreen.routeFor(id),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('open editor'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
    return popped;
  }

  /// The fill colour of the pill carrying [label], which is how the selected
  /// one reads: ink when it is chosen, a container surface when it is not.
  Color pillColor(WidgetTester tester, String label) {
    final container = tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  final primary = AppTheme.colorScheme(Brightness.light).primary;

  testWidgets('seeds the name field and the selected pills from the workout', (
    tester,
  ) async {
    final provider = WorkoutProvider(today: today, workouts: [fixture()]);
    await openEditor(tester, provider, 'upper-body');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Upper Body Hypertrophy & Core');

    expect(pillColor(tester, 'Cardio'), primary);
    expect(pillColor(tester, 'Push'), primary);
    expect(pillColor(tester, 'Hypertrophy'), primary);
    // A value the workout does not carry stays unselected.
    expect(pillColor(tester, 'Legs'), isNot(primary));
  });

  testWidgets('selecting a split deselects the previous one', (tester) async {
    final provider = WorkoutProvider(today: today, workouts: [fixture()]);
    await openEditor(tester, provider, 'upper-body');

    await tester.tap(find.text('Legs'));
    await tester.pumpAndSettle();

    expect(pillColor(tester, 'Legs'), primary);
    expect(pillColor(tester, 'Push'), isNot(primary));
  });

  testWidgets('save writes the new classification and name through the store', (
    tester,
  ) async {
    final provider = WorkoutProvider(today: today, workouts: [fixture()]);
    await openEditor(tester, provider, 'upper-body');

    await tester.tap(find.text('Plyometrics'));
    await tester.tap(find.text('Legs'));
    await tester.tap(find.text('Endurance'));
    await tester.enterText(find.byType(TextField), 'Heavy Leg Day');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = provider.byId('upper-body')!;
    expect(saved.modality, Modality.plyometrics);
    expect(saved.split, WorkoutSplit.legs);
    expect(saved.goal, TrainingGoal.endurance);
    expect(saved.title, 'Heavy Leg Day');
  });

  testWidgets('save pops with the updated workout', (tester) async {
    final provider = WorkoutProvider(today: today, workouts: [fixture()]);
    final popped = await openEditor(tester, provider, 'upper-body');

    await tester.tap(find.text('Legs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(popped[0], isNotNull);
    expect(popped[0]!.split, WorkoutSplit.legs);
    expect(popped[0]!.title, 'Upper Body Hypertrophy & Core');
  });

  testWidgets('clearing a classification leaves it unset', (tester) async {
    final provider = WorkoutProvider(today: today, workouts: [fixture()]);
    await openEditor(tester, provider, 'upper-body');

    // Tapping the already-selected pill clears it rather than re-choosing it.
    await tester.tap(find.text('Cardio'));
    await tester.pumpAndSettle();

    expect(pillColor(tester, 'Cardio'), isNot(primary));

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(provider.byId('upper-body')!.modality, isNull);
  });

  testWidgets('an unknown id renders the not-found state', (tester) async {
    final provider = WorkoutProvider(today: today, workouts: [fixture()]);
    final popped = await openEditor(tester, provider, 'no-such-workout');

    expect(find.text('Session not found'), findsOneWidget);
    expect(popped[0], isNull);
  });
}
