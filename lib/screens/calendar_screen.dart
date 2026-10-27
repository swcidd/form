import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/library_exercise.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/new_workout_dialog.dart';
import 'add_exercise_screen.dart';
import 'workout_detail_screen.dart';

/// The Workout tab: a range calendar over the stored sessions.
///
/// Laid out from the Figma "Workout · Training calendar" frames — header, a
/// four-way range selector, a calendar card that switches between a 3-day,
/// week, 2-week and month grid, then the selected day's sessions and one
/// pinned action.
///
/// The range and the selected day are screen state rather than provider state:
/// which window the user is looking at is a view preference, and storing it in
/// the workout store would make it outlive a sign-out.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

/// The window the calendar shows. Labels are the selector's copy in Figma.
enum CalendarRange {
  threeDays('3 days'),
  week('Week'),
  twoWeeks('2 weeks'),
  month('Month');

  const CalendarRange(this.label);

  final String label;
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarRange _range = CalendarRange.threeDays;

  /// A day inside the window being shown. Null until the first build, when the
  /// provider's notion of today is available.
  DateTime? _cursor;

  /// The day whose sessions are listed under the calendar.
  DateTime? _selected;

  DateTime get _today => context.read<WorkoutProvider>().today;

  DateTime get _anchor => _cursor ?? _today;

  DateTime get _selection => _selected ?? _today;

  /// Monday of the week containing [day], which is where every multi-day
  /// window starts. A Sunday-start week would slide the columns depending on
  /// the weekday the app is opened.
  static DateTime _mondayOf(DateTime day) =>
      DateUtils.dateOnly(day).subtract(Duration(days: day.weekday - 1));

  /// First cell of the window. Month starts at the Monday of the week holding
  /// the 1st so the grid stays rectangular.
  DateTime _windowStart(DateTime cursor) => switch (_range) {
    CalendarRange.threeDays => DateUtils.dateOnly(cursor),
    CalendarRange.week || CalendarRange.twoWeeks => _mondayOf(cursor),
    CalendarRange.month => _mondayOf(DateTime(cursor.year, cursor.month)),
  };

  /// Every cell in the window, including the leading and trailing days a month
  /// grid borrows from its neighbours.
  List<DateTime> _windowDays(DateTime cursor) {
    final start = _windowStart(cursor);
    final count = switch (_range) {
      CalendarRange.threeDays => 3,
      CalendarRange.week => 7,
      CalendarRange.twoWeeks => 14,
      CalendarRange.month => _monthRows(cursor) * 7,
    };
    return [
      for (var index = 0; index < count; index++)
        start.add(Duration(days: index)),
    ];
  }

  /// Five rows for a month that fits, six when it spills, so October 2026 shows
  /// the same five rows it does in the frame.
  static int _monthRows(DateTime cursor) {
    final start = _mondayOf(DateTime(cursor.year, cursor.month));
    final end = DateTime(cursor.year, cursor.month + 1, 0);
    return ((end.difference(start).inDays + 1) / 7).ceil();
  }

  /// Indexes the store by day once per build.
  ///
  /// A month draws 42 cells and the legend asks about every day in the window,
  /// so looking each one up through `workoutsOn` would walk the whole account
  /// dozens of times for one frame.
  static Map<DateTime, List<Workout>> _indexByDay(WorkoutProvider provider) {
    final byDay = <DateTime, List<Workout>>{};
    for (final workout in provider.workouts) {
      (byDay[DateUtils.dateOnly(workout.date)] ??= []).add(workout);
    }
    return byDay;
  }

  static List<Workout> _sessionsOn(
    Map<DateTime, List<Workout>> byDay,
    DateTime day,
  ) => byDay[DateUtils.dateOnly(day)] ?? const [];

  /// Switches the window, taking the selection with it.
  ///
  /// The four ranges start on different days, so the day selected in one can
  /// fall outside the next — a leading day of a month grid is not in that
  /// month's three-day window. Re-anchoring on the selection keeps the heading
  /// and the highlighted cell describing the same day.
  void _selectRange(CalendarRange range) {
    if (range == _range) return;
    setState(() {
      _range = range;
      final cursor = _anchor;
      final exists = _windowDays(cursor)
          .any((day) => DateUtils.isSameDay(day, _selection));
      _cursor = exists ? cursor : DateUtils.dateOnly(_selection);
      _selected = _selection;
    });
  }

  /// Moves the window — and the selection with it, so the list under the
  /// calendar never describes a day that is no longer on screen.
  void _shift(int direction) {
    setState(() {
      final cursor = _anchor;
      final moved = switch (_range) {
        CalendarRange.threeDays => DateTime(
          cursor.year,
          cursor.month,
          cursor.day + 3 * direction,
        ),
        CalendarRange.week => DateTime(
          cursor.year,
          cursor.month,
          cursor.day + 7 * direction,
        ),
        CalendarRange.twoWeeks => DateTime(
          cursor.year,
          cursor.month,
          cursor.day + 14 * direction,
        ),
        CalendarRange.month => _stepMonth(cursor, direction),
      };
      _cursor = DateUtils.dateOnly(moved);
      _selected = _cursor;
    });
  }

  /// The same day of the month [direction] months away, clamped to what that
  /// month has. `DateTime(2026, 3, 31 + a month)` normalises to 1 May, which
  /// would skip April entirely and make the next press land in June.
  static DateTime _stepMonth(DateTime cursor, int direction) {
    final target = DateTime(cursor.year, cursor.month + direction);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(target.year, target.month, math.min(cursor.day, lastDay));
  }

  void _selectDay(DateTime day) {
    setState(() => _selected = DateUtils.dateOnly(day));
  }

  /// Plans a session: exercises first, then what to call it.
  ///
  /// The picker runs before the form because a planned session without
  /// exercises is not what the button is for - backing out of the picker leaves
  /// the calendar as it was rather than opening a form for an empty workout.
  Future<void> _createWorkout() async {
    final provider = context.read<WorkoutProvider>();
    final navigator = Navigator.of(context);

    final picked = await navigator.pushNamed<List<LibraryExercise>>(
      AddExerciseScreen.routeName,
    );
    if (picked == null || !mounted) return;

    // The form opens on the day the calendar is pointed at, so planning from
    // the 29th does not quietly write the session onto today.
    final created = await NewWorkoutDialog.show(
      context,
      initialDate: _selection,
      exercises: picked,
    );
    if (created == null) return;

    final stored = provider.addWorkout(created);
    if (!mounted) return;
    navigator.pushNamed(WorkoutDetailScreen.routeFor(stored.id));
  }

  void _openSession(String id) {
    Navigator.of(context).pushNamed(WorkoutDetailScreen.routeFor(id));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final provider = context.watch<WorkoutProvider>();

    final days = _windowDays(_anchor);
    final selected = _selection;
    final sessionsByDay = _indexByDay(provider);
    final sessions = _sessionsOn(sessionsByDay, selected);
    final planned = days.any(
      (day) => _sessionsOn(sessionsByDay, day).isNotEmpty,
    );

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 16),
            _rangeSelector(),
            const SizedBox(height: 16),
            _hero(
              days: days,
              selected: selected,
              planned: planned,
              sessionsByDay: sessionsByDay,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                children: [
                  _dayHeading(selected, sessions.length),
                  const SizedBox(height: 12),
                  if (sessions.isEmpty)
                    const _NothingPlanned()
                  else
                    for (final session in sessions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SessionTile(
                          session: session,
                          isToday: DateUtils.isSameDay(session.date, _today),
                          onTap: () => _openSession(session.id),
                        ),
                      ),
                ],
              ),
            ),
            _action(sessions: sessions),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR TRAINING',
            style: text.annotation.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'PLAN THE WEEK.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeSelector() {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (final range in CalendarRange.values)
              Expanded(
                child: Semantics(
                  selected: range == _range,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectRange(range),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: range == _range
                            ? scheme.surfaceContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        range.label,
                        style: context.text.labelCaps.copyWith(
                          fontSize: 11,
                          letterSpacing: 0,
                          color: range == _range
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hero({
    required List<DateTime> days,
    required DateTime selected,
    required bool planned,
    required Map<DateTime, List<Workout>> sessionsByDay,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: _range == CalendarRange.month
            ? _monthHeight(days.length ~/ 7)
            : 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _rangeLabel(days),
                    style: text.programBadge.copyWith(
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                _RangeArrow(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous ${_range.label}',
                  onTap: () => _shift(-1),
                ),
                const SizedBox(width: 10),
                _RangeArrow(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next ${_range.label}',
                  onTap: () => _shift(1),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_range != CalendarRange.threeDays)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    for (final letter in const [
                      'M',
                      'T',
                      'W',
                      'T',
                      'F',
                      'S',
                      'S',
                    ])
                      Expanded(
                        child: Text(
                          letter,
                          textAlign: TextAlign.center,
                          style: text.annotation.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _range == CalendarRange.threeDays
                  ? Row(
                      children: [
                        for (final day in days)
                          Expanded(
                            child: _DayCell(
                              day: day,
                              selection: selected,
                              today: _today,
                              workouts: _sessionsOn(sessionsByDay, day),
                              detailed: true,
                              onTap: () => _selectDay(day),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      children: [
                        for (var row = 0; row < days.length ~/ 7; row++)
                          Expanded(
                            child: Row(
                              children: [
                                for (var column = 0; column < 7; column++)
                                  Expanded(
                                    child: _DayCell(
                                      day: days[row * 7 + column],
                                      selection: selected,
                                      today: _today,
                                      workouts: _sessionsOn(
                                        sessionsByDay,
                                        days[row * 7 + column],
                                      ),
                                      month: _range == CalendarRange.month
                                          ? _anchor.month
                                          : null,
                                      detailed: false,
                                      onTap: () =>
                                          _selectDay(days[row * 7 + column]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  planned ? 'workout planned' : 'no workouts scheduled',
                  style: text.annotation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Height of one week row in the month grid: the number's circle, the gap
  /// under it and the session dot, with a margin.
  static const double _monthRowHeight = 40;

  /// Everything in the card that is not a week row: the range header and its
  /// touch targets, the weekday strip, the legend and the card's padding.
  ///
  /// The frame fitted five taller rows into 330 by leaving the cells more room
  /// than they need. Taking a fixed row height instead is what lets a sixth
  /// week borrow one more row (see [_monthHeight]) rather than squeezing all
  /// of them; 134 is the measured chrome plus a few pixels of slack for the
  /// text lines' rounding.
  static const double _monthChrome = 134;

  /// The card's height for a month of [rows] weeks.
  ///
  /// Derived rather than fixed: November 2026 is six rows, so a hardcoded 330
  /// overflowed every cell of it by three pixels one `Next` away from the
  /// default month.
  static double _monthHeight(int rows) => _monthChrome + rows * _monthRowHeight;

  /// "OCT 26 – 28" inside one month, "OCT 31 – NOV 2" across two, and the
  /// month's own name when the window is a month.
  String _rangeLabel(List<DateTime> days) {
    if (_range == CalendarRange.month) {
      return DateFormat('MMMM yyyy').format(_anchor).toUpperCase();
    }
    final first = days.first;
    final last = days.last;
    final head = DateFormat('MMM d').format(first).toUpperCase();
    final tail = first.month == last.month
        ? DateFormat('d').format(last)
        : DateFormat('MMM d').format(last).toUpperCase();
    return '$head – $tail';
  }

  Widget _dayHeading(DateTime day, int count) {
    final text = context.text;

    return Row(
      children: [
        Expanded(
          child: Text(
            DateFormat('EEEE d MMM').format(day).toUpperCase(),
            style: text.labelCaps,
          ),
        ),
        Text(
          count == 1 ? '1 SESSION' : '$count SESSIONS',
          style: text.annotation,
        ),
      ],
    );
  }

  Widget _action({required List<Workout> sessions}) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final target = _openSessionOn(sessions);

    // Nothing left to train means the button opens the day rather than
    // pretending a finished session is the one about to start.
    final label = target != null
        ? 'Start workout'
        : sessions.isEmpty
        ? 'Plan a workout'
        : 'View workout';
    final icon = target != null
        ? Icons.play_arrow_rounded
        : sessions.isEmpty
        ? Icons.add_rounded
        : Icons.arrow_outward_rounded;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: sessions.isEmpty
                ? _createWorkout
                : () => _openSession((target ?? sessions.first).id),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: text.labelCaps.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimary,
                  ),
                ),
                Icon(icon, size: 22, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The session on the selected day that is still to be trained, if any.
  ///
  /// The list is in date order, not status order, so the first session can be
  /// a finished one from the morning with the planned session behind it. The
  /// action has to prefer the open one or "Start workout" opens a session that
  /// is already done.
  static Workout? _openSessionOn(List<Workout> sessions) {
    for (final session in sessions) {
      if (session.status == WorkoutStatus.planned ||
          session.status == WorkoutStatus.inProgress) {
        return session;
      }
    }
    return null;
  }
}

/// One day in the calendar card.
///
/// Three densities from one widget, because every range asks the same question
/// of a day — is it today, is it selected, what is on it — and only the amount
/// of room differs.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selection,
    required this.today,
    required this.workouts,
    required this.onTap,
    required this.detailed,
    this.month,
  });

  final DateTime day;
  final DateTime selection;
  final DateTime today;

  /// True when the cell has room for a session name rather than a bar. Only
  /// the 3-day window does.
  final bool detailed;

  /// Every session on the day, including completed ones: the calendar shows
  /// what was trained, not only what is left to do.
  final List<Workout> workouts;

  final VoidCallback onTap;

  /// Set for the month grid, where the cells outside the month are muted.
  final int? month;

  bool get _isToday => DateUtils.isSameDay(day, today);

  bool get _isSelected => DateUtils.isSameDay(day, selection);

  bool get _outside => month != null && day.month != month;

  /// The day as a screen reader reads it: "Thursday 29 October, 2 sessions".
  ///
  /// The cell's own text is a bare number, which announces as "29" with no
  /// month, no weekday and nothing about what is on it.
  String get _semanticsLabel {
    final date = DateFormat('EEEE d MMMM').format(day);
    return switch (workouts.length) {
      0 => date,
      1 => '$date, 1 session',
      final count => '$date, $count sessions',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final number = Text(
      '${day.day}',
      style: context.text.annotation.copyWith(
        fontSize: 12,
        fontWeight: _isToday ? FontWeight.w600 : FontWeight.w400,
        color: _isToday
            ? scheme.onPrimary
            : _outside
            ? scheme.outline
            : _isSelected
            ? scheme.onSurface
            : scheme.onSurfaceVariant,
      ),
    );

    return Semantics(
      button: true,
      selected: _isSelected,
      label: _semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 2,
            // The compact grids have less height per row, so the cell gives
            // back the room the two session bars need.
            vertical: month != null
                ? 2
                : detailed
                ? 4
                : 2,
          ),
          child: Column(
            children: [
              // Only the three-day cell has room for the weekday: the header
              // row above already names the columns for the week and month
              // grids, and repeating it here crowded the session bars out.
              if (detailed)
                Text(
                  DateFormat('EEE').format(day).toUpperCase(),
                  style: context.text.annotation.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              if (detailed) const SizedBox(height: 4),
              Container(
                width: month == null ? 20 : 30,
                height: month == null ? 20 : 30,
                alignment: Alignment.center,
                // Today is filled; the selected day is outlined, so a day can
                // show both without one of the two marks disappearing.
                decoration: _isToday
                    ? BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      )
                    : _isSelected
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.primary, width: 1.5),
                      )
                    : null,
                child: number,
              ),
              SizedBox(height: month != null ? 2 : (detailed ? 8 : 4)),
              if (month != null)
                // Month is a scan view: a dot says "something happened" without
                // pretending the 9px cell can hold a title.
                if (workouts.isNotEmpty)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 4)
              else
                for (final workout in workouts.take(2))
                  if (detailed)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      height: 32,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        workout.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.annotation.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimary,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 4),
                      height: 10,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeArrow extends StatelessWidget {
  const _RangeArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      // A 26px glyph is a 26px target, which is below the 44dp a thumb needs.
      // The style keeps the icon small and lets the button itself take the
      // space a press deserves.
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.zero,
      ),
      iconSize: 18,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: Icon(icon),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isToday,
    required this.onTap,
  });

  final Workout session;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    final kicker = [
      isToday
          ? 'TODAY'
          : DateFormat('EEE d MMM').format(session.date).toUpperCase(),
      if (session.startTime.isNotEmpty) session.startTime,
    ].join(' · ');

    final meta = [
      '${session.logs.length} '
          '${session.logs.length == 1 ? 'exercise' : 'exercises'}',
      if (session.durationMin > 0) '${session.durationMin} min',
      if (session.modality != null) session.modality!.label,
    ].join(' · ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: text.annotation.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.programBadge.copyWith(
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.annotation,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_outward_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _NothingPlanned extends StatelessWidget {
  const _NothingPlanned();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'Nothing planned yet',
      message: 'Tap a day on the calendar to schedule your first session.',
    );
  }
}
