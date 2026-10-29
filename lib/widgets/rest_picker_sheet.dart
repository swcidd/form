import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Chooses the rest planned for an exercise, the way a phone clock chooses a
/// time.
///
/// A wheel rather than a field or a stepper: the useful values are few and
/// evenly spaced, and a wheel lets a thumb land on one without aiming. Steps of
/// ten seconds, because that is the resolution anybody plans in - nobody
/// prescribes a twenty-three second rest.
///
/// Returns the chosen number of seconds, or null when dismissed. Zero means no
/// rest, which is the default: a plan does not invent a rest nobody chose.
Future<int?> showRestPicker(
  BuildContext context, {
  required String exercise,
  required int initial,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RestPicker(exercise: exercise, initial: initial),
  );
}

/// Ten seconds per notch, up to ten minutes - past that a rest is a different
/// activity.
const int restStep = 10;
const int restCeiling = 600;

class _RestPicker extends StatefulWidget {
  const _RestPicker({required this.exercise, required this.initial});

  final String exercise;
  final int initial;

  @override
  State<_RestPicker> createState() => _RestPickerState();
}

class _RestPickerState extends State<_RestPicker> {
  late int _seconds = widget.initial.clamp(0, restCeiling);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = context.text;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Rest', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.exercise,
            style: text.annotation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: CupertinoPicker.builder(
              scrollController: FixedExtentScrollController(
                initialItem: _seconds ~/ restStep,
              ),
              itemExtent: 44,
              useMagnifier: true,
              magnification: 1.15,
              // Selection is the scroll position, so it is reported live; the
              // button below is what commits it.
              onSelectedItemChanged: (index) =>
                  setState(() => _seconds = index * restStep),
              childCount: (restCeiling ~/ restStep) + 1,
              itemBuilder: (_, index) {
                final seconds = index * restStep;
                final selected = seconds == _seconds;
                return Center(
                  child: Text(
                    restLabel(seconds),
                    style: text.dataMetric.copyWith(
                      fontSize: 28,
                      height: 1,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_seconds),
                child: Text(
                  _seconds == 0 ? 'No rest' : 'Set ${restLabel(_seconds)}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ten seconds as `0:10`, a minute as `1:30`, nothing as `Off`.
String restLabel(int seconds) {
  if (seconds <= 0) return 'Off';
  final minutes = seconds ~/ 60;
  final rest = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$rest';
}
