import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Month, day and year in one box, the way the design asks for a date of birth.
///
/// Three dropdowns rather than a calendar: the design has no room for a
/// calendar on this step, and the date being asked for is a fact about somebody
/// that is easier to pick in three known lists than to navigate to on a
/// twelve-month grid.
///
/// The widget holds the partial selection, because half a date is not a value
/// its caller should have to model. It reports a [DateTime] only when month,
/// day and year are all chosen and the three make a real date; until then the
/// caller is told null and can refuse to continue.
class DateOfBirthField extends StatefulWidget {
  const DateOfBirthField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialDate,
    this.errorText,
    this.enabled = true,
  });

  final String label;

  /// Called with the chosen date, or null while the choice is incomplete or
  /// impossible (29 February in a year that has no 29 February).
  final ValueChanged<DateTime?> onChanged;

  final DateTime? initialDate;

  final String? errorText;

  final bool enabled;

  @override
  State<DateOfBirthField> createState() => _DateOfBirthFieldState();
}

class _DateOfBirthFieldState extends State<DateOfBirthField> {
  int? _month;
  int? _day;
  int? _year;

  /// The youngest and oldest ages the list offers.
  ///
  /// Thirteen is the floor for an account, and a hundred is the point where a
  /// year list stops being useful. The month and day are still checked against
  /// the real calendar — a list of days is not a list of dates.
  static const int _youngest = 13;
  static const int _oldest = 100;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate;
    if (initial != null) {
      _year = initial.year;
      _month = initial.month;
      _day = initial.day;
    }
  }

  int get _daysInMonth => DateUtils.getDaysInMonth(_year ?? 2000, _month ?? 1);

  void _select({int? month, int? day, int? year}) {
    setState(() {
      if (year != null) _year = year;
      if (month != null) _month = month;
      if (day != null) _day = day;

      // A day that does not exist in the new month cannot stay selected; the
      // list shrinks under it and the box must not claim 31 February.
      final lastDay = _daysInMonth;
      if (_day != null && _day! > lastDay) _day = null;
    });
    _report();
  }

  void _report() {
    final month = _month;
    final day = _day;
    final year = _year;
    if (month == null || day == null || year == null) {
      widget.onChanged(null);
      return;
    }

    final date = DateTime(year, month, day);
    // DateTime rolls an impossible date forward, so an equal round trip is the
    // check that the three lists agreed on a real day.
    final real = date.year == year && date.month == month && date.day == day;
    widget.onChanged(real ? date : null);
  }

  List<int> get _years {
    final thisYear = DateTime.now().year;
    return [for (var y = thisYear - _youngest; y >= thisYear - _oldest; y--) y];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: text.labelCaps),
        const SizedBox(height: 8),
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.control,
            border: Border.all(
              color: hasError ? scheme.error : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _segment(
                  value: _month,
                  hintTop: 'Month',
                  hintBottom: 'Select month',
                  unit: 'Month',
                  menu: [
                    for (var m = 1; m <= 12; m++)
                      _Choice(
                        value: m,
                        label: DateFormat.MMMM().format(DateTime(2000, m)),
                      ),
                  ],
                  onSelected: (m) => _select(month: m),
                ),
              ),
              _divider(scheme),
              Expanded(
                child: _segment(
                  value: _day,
                  hintTop: 'Day',
                  hintBottom: 'Select day',
                  unit: 'Day',
                  menu: [
                    for (var d = 1; d <= _daysInMonth; d++)
                      _Choice(value: d, label: '$d'),
                  ],
                  onSelected: (d) => _select(day: d),
                ),
              ),
              _divider(scheme),
              Expanded(
                child: _segment(
                  value: _year,
                  hintTop: 'Year',
                  hintBottom: 'Select year',
                  unit: 'Year',
                  menu: [
                    for (final y in _years) _Choice(value: y, label: '$y'),
                  ],
                  onSelected: (y) => _select(year: y),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: text.annotation.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }

  Widget _divider(ColorScheme scheme) =>
      Container(width: 1, height: 32, color: scheme.outlineVariant);

  /// One column of the box: a value over its unit, or the unit over a prompt
  /// while nothing has been chosen.
  Widget _segment({
    required int? value,
    required String hintTop,
    required String hintBottom,
    required String unit,
    required List<_Choice> menu,
    required ValueChanged<int> onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;
    final selected = menu.where((choice) => choice.value == value).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          icon: const SizedBox.shrink(),
          borderRadius: AppRadius.control,
          menuMaxHeight: 320,
          hint: _label(text, scheme, selected?.label ?? hintTop, hintBottom),
          selectedItemBuilder: (context) => [
            for (final choice in menu) _label(text, scheme, choice.label, unit),
          ],
          items: [
            for (final choice in menu)
              DropdownMenuItem(
                value: choice.value,
                child: Text(choice.label, style: text.exerciseMeta),
              ),
          ],
          onChanged: widget.enabled
              ? (chosen) {
                  if (chosen != null) onSelected(chosen);
                }
              : null,
        ),
      ),
    );
  }

  Widget _label(AppText text, ColorScheme scheme, String top, String bottom) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          top,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.exerciseMeta.copyWith(
            fontSize: 14,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          bottom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.annotation.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Choice {
  const _Choice({required this.value, required this.label});

  final int value;
  final String label;
}
