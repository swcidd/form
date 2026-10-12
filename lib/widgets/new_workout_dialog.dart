import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The form for creating a workout, presented as a centred dialog.
///
/// Two fields only, because this is reached from the bar rather than chosen
/// deliberately. A lifter tapping the action mid-session wants to start
/// training, not fill in a questionnaire: the questions here are the two that
/// change what the next screen shows. Everything else - exercises, sets - is
/// added from the workout itself once it exists.
///
/// Returns the created [Workout] through [Navigator.pop], rather than writing
/// to the provider directly. The dialog owns no store, so a caller that
/// abandons it has nothing to undo, and the caller decides whether to open the
/// new session or just leave it in the list.
class NewWorkoutDialog extends StatefulWidget {
  const NewWorkoutDialog({super.key, this.initialDate});

  final DateTime? initialDate;

  /// Shows the dialog and resolves to the new workout, or null if dismissed.
  ///
  /// Null covers every way out - the back gesture, the barrier, Cancel - so
  /// callers do not have to distinguish them.
  static Future<Workout?> show(BuildContext context, {DateTime? initialDate}) {
    return showDialog<Workout>(
      context: context,
      builder: (_) => NewWorkoutDialog(initialDate: initialDate),
    );
  }

  @override
  State<NewWorkoutDialog> createState() => _NewWorkoutDialogState();
}

class _NewWorkoutDialogState extends State<NewWorkoutDialog> {
  final _name = TextEditingController();
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _name.text.trim();
    Navigator.of(context).pop(
      Workout(
        id: '',
        title: trimmed.isEmpty ? _defaultTitle() : trimmed,
        date: DateTime(_date.year, _date.month, _date.day),
        status: WorkoutStatus.planned,
        durationMin: 45,
        estimatedKcal: 0,
        targetMuscleGroups: const [],
        equipment: const [],
        logs: const [],
      ),
    );
  }

  /// Offers a starting point for someone who does not want to name a session.
  ///
  /// "Training" rather than "Workout" so the title is not the same word as the
  /// app, and an empty name is not rejected - a lifter mid-session wants the
  /// log, not a naming exercise.
  String _defaultTitle() => 'Training ${DateFormat('MMM d').format(_date)}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Sessions are logged for today or earlier in this flow; scheduling
      // ahead is what the calendar tab is for.
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('New workout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NAME THIS SESSION', style: context.text.labelCaps),
          const SizedBox(height: 8),
          TextFormField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: _defaultTitle(),
              border: OutlineInputBorder(
                borderRadius: AppRadius.control,
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.control,
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.control,
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
              // Deliberately no validator. An untitled session is still a
              // real one, and forcing a name here is friction in front of
              // the one thing the lifter opened the app to do.
              helperText: 'Leave blank to use the date.',
            ),
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 18),
          Text('DATE', style: context.text.labelCaps),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: AppRadius.control,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: AppRadius.control,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, MMM d').format(_date),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: scheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Start'),
        ),
      ],
    );
  }
}
