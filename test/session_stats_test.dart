import 'package:flutter_test/flutter_test.dart';

import 'package:plus_one/data/session_stats.dart';
import 'package:plus_one/models/exercise.dart';
import 'package:plus_one/models/workout.dart';

/// A fixed "today", so the windows below are checked against a calendar
/// rather than against whatever day the suite happens to run on.
final _today = DateTime(2026, 10, 17);

DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

WorkoutSet _set(int reps, double kg, {bool completed = true}) =>
    WorkoutSet(reps: reps, weightKg: kg, completed: completed);

ExerciseLog _log(String name, List<WorkoutSet> sets) => ExerciseLog(
  exercise: Exercise(
    name: name,
    equipment: 'Barbell',
    muscleGroups: const ['Chest'],
  ),
  sets: sets,
);

Workout _session({
  required String id,
  required DateTime date,
  String title = 'Push Day',
  WorkoutStatus status = WorkoutStatus.completed,
  List<ExerciseLog> logs = const [],
}) => Workout(
  id: id,
  title: title,
  date: date,
  status: status,
  durationMin: 45,
  estimatedKcal: 300,
  targetMuscleGroups: const ['Chest'],
  equipment: const ['Barbell'],
  logs: logs,
);

void main() {
  group('an account with nothing on it', () {
    test('reports nothing rather than zeros', () {
      final stats = SessionStats(const [], today: _today);

      expect(stats.isEmpty, isTrue);
      expect(stats.sessions, 0);
      expect(stats.volumeKg, 0);
      expect(stats.records, isEmpty);
      expect(stats.sessionsPerWeek, 0);
      // Not "+100%" and not 0% - there is no baseline to compare against.
      expect(stats.volumeChangeIn(30), isNull);
    });

    test('ignores a session that was never finished', () {
      final stats = SessionStats([
        _session(
          id: 'plan',
          date: _today,
          status: WorkoutStatus.planned,
          logs: [
            _log('Bench Press', [_set(5, 100)]),
          ],
        ),
      ], today: _today);

      // A planned set is work the user has not done. Counting it would let a
      // routine nobody performed show up as training.
      expect(stats.isEmpty, isTrue);
      expect(stats.volumeKg, 0);
    });
  });

  group('volume', () {
    test('counts completed sets and skips the rest', () {
      final stats = SessionStats([
        _session(
          id: 'a',
          date: _daysAgo(1),
          logs: [
            _log('Bench Press', [_set(5, 100), _set(5, 100, completed: false)]),
          ],
        ),
      ], today: _today);

      expect(stats.volumeKg, 500);
    });

    test('windows the last 30 days and compares the 30 before them', () {
      final stats = SessionStats([
        _session(
          id: 'recent',
          date: _daysAgo(10),
          logs: [
            _log('Bench Press', [_set(5, 100)]),
          ],
        ),
        _session(
          id: 'older',
          date: _daysAgo(40),
          logs: [
            _log('Bench Press', [_set(5, 90)]),
          ],
        ),
        _session(
          id: 'ancient',
          date: _daysAgo(90),
          logs: [
            _log('Bench Press', [_set(5, 500)]),
          ],
        ),
      ], today: _today);

      expect(stats.volumeIn(30), 500);
      // 500 kg against the 450 kg of the window before it.
      expect(stats.volumeChangeIn(30), closeTo(11.1, 0.1));
    });

    test('has no percentage when there is no earlier window', () {
      final stats = SessionStats([
        _session(
          id: 'only',
          date: _daysAgo(2),
          logs: [
            _log('Bench Press', [_set(5, 100)]),
          ],
        ),
      ], today: _today);

      expect(stats.volumeChangeIn(30), isNull);
    });
  });

  group('records', () {
    test('ranks an exercise by estimated one-rep max, not by load', () {
      final stats = SessionStats([
        _session(
          id: 'a',
          date: _daysAgo(1),
          logs: [
            _log('Deadlift', [_set(1, 120)]),
            _log('Bench Press', [_set(10, 100)]),
          ],
        ),
      ], today: _today);

      // 100 kg for 10 reps is the better lift even though 120 kg is the
      // heavier bar, and a list sorted by weight would report the opposite.
      expect(stats.records.map((record) => record.exercise), [
        'Bench Press',
        'Deadlift',
      ]);
    });

    test('keeps the best set per exercise, with the day it was set', () {
      final stats = SessionStats([
        _session(
          id: 'new',
          date: _daysAgo(2),
          logs: [
            _log('Bench Press', [_set(5, 100)]),
          ],
        ),
        _session(
          id: 'old',
          date: _daysAgo(30),
          logs: [
            _log('Bench Press', [_set(5, 110)]),
          ],
        ),
      ], today: _today);

      final record = stats.records.single;
      expect(record.weightKg, 110);
      expect(record.date, _daysAgo(30));
    });

    test('leaves bodyweight work out of the ranking', () {
      final stats = SessionStats([
        _session(
          id: 'a',
          date: _daysAgo(1),
          logs: [
            _log('Pull Up', [_set(8, 0)]),
            _log('Bench Press', [_set(5, 60)]),
          ],
        ),
      ], today: _today);

      expect(stats.records.map((record) => record.exercise), ['Bench Press']);
    });

    test('picks the best set inside one session', () {
      final workout = _session(
        id: 'a',
        date: _today,
        logs: [
          _log('Bench Press', [_set(5, 80), _set(3, 90)]),
          _log('Squat', [_set(5, 60, completed: false)]),
        ],
      );
      final stats = SessionStats([workout], today: _today);

      final top = stats.topSetIn(workout);
      expect(top!.exercise, 'Bench Press');
      expect(top.weightKg, 90);
    });

    test('has no best set when nothing was ticked off', () {
      final workout = _session(
        id: 'a',
        date: _today,
        logs: [
          _log('Bench Press', [_set(5, 80, completed: false)]),
        ],
      );
      final stats = SessionStats([workout], today: _today);

      expect(stats.topSetIn(workout), isNull);
    });

    test('finds the same exercise in an earlier session, never itself', () {
      final earlier = _session(
        id: 'old',
        date: _daysAgo(9),
        logs: [
          _log('Bench Press', [_set(5, 95)]),
        ],
      );
      final latest = _session(
        id: 'new',
        date: _daysAgo(2),
        logs: [
          _log('Bench Press', [_set(5, 100)]),
        ],
      );
      final stats = SessionStats([earlier, latest], today: _today);

      final previous = stats.previousBestOf('Bench Press', before: latest.date);
      expect(previous!.weightKg, 95);
      expect(previous.date, _daysAgo(9));

      // A session is not its own baseline, so the first time an exercise is
      // logged there is nothing to beat.
      expect(stats.previousBestOf('Bench Press', before: earlier.date), isNull);
    });
  });

  group('session frequency', () {
    test('averages finished sessions over the last four weeks', () {
      final stats = SessionStats([
        for (var i = 0; i < 6; i++)
          _session(id: 's$i', date: _daysAgo(i), logs: const []),
        _session(id: 'old', date: _daysAgo(40), logs: const []),
      ], today: _today);

      expect(stats.sessionsIn(28), 6);
      expect(stats.sessionsPerWeek, 1.5);
    });

    test('finds the last session with the same title', () {
      final stats = SessionStats([
        _session(
          id: 'a',
          title: 'Push Day',
          date: _daysAgo(9),
          logs: [
            _log('Bench Press', [_set(5, 100)]),
          ],
        ),
        _session(
          id: 'b',
          title: 'Leg Day',
          date: _daysAgo(5),
          logs: [
            _log('Squat', [_set(5, 200)]),
          ],
        ),
        _session(
          id: 'c',
          title: 'Push Day',
          date: _daysAgo(2),
          logs: [
            _log('Bench Press', [_set(5, 100)]),
          ],
        ),
      ], today: _today);

      expect(stats.lastVolumeOf('Push Day', before: _today), 500);
      expect(stats.lastVolumeOf('Push Day', before: _daysAgo(2)), 500);
      // Nothing of that name happened before the oldest one.
      expect(stats.lastVolumeOf('Push Day', before: _daysAgo(9)), isNull);
      expect(stats.lastVolumeOf('Upper Body', before: _today), isNull);
    });
  });
}
