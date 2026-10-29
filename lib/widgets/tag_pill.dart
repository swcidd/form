import 'package:flutter/material.dart';

/// The thin tag under an exercise name.
///
/// Deliberately not a [ChoiceChip]: a tag is a read-out, not a control, and the
/// interactive chips in this app are 36 to 44 tall with a target size to match.
/// This one is 14 tall and carries 7.5pt text, which is as small as the design
/// goes anywhere - it sits under a title, so it labels rather than asks to be
/// tapped.
///
/// Colour comes from the scheme, not from a raw hex, so the same pill reads
/// correctly on the light and dark pages.
class TagPill extends StatelessWidget {
  const TagPill(this.label, {super.key, this.selected = false});

  final String label;

  /// Selected marks a tag the user chose, as opposed to one read off the
  /// catalogue. Nothing in the picker uses it yet; the row's selected state
  /// does.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 14,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 7.5,
          height: 1.0,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w500,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A wrapped run of [TagPill]s.
///
/// Wraps rather than scrolls: five tags do not fit one line of a phone, and a
/// horizontal scroll would hide the last one behind a gesture nobody knows is
/// there.
class TagPillRow extends StatelessWidget {
  const TagPillRow(this.labels, {super.key});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [for (final label in labels) TagPill(label)],
    );
  }
}
