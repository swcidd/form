import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A minimal line chart for a short series with gaps.
///
/// Null values are weeks with no measurement. They still occupy their place on
/// the x axis, but the line is broken there rather than drawn through a value
/// nobody logged. The chart has no axes or labels of its own; the card that
/// owns it supplies the dates underneath.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.values,
    required this.color,
    this.height = 112,
    this.semanticLabel,
  });

  final List<double?> values;
  final Color color;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = this.semanticLabel;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(values: values, color: color),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final observed = [
      for (var index = 0; index < values.length; index++)
        if (values[index] != null) index,
    ];
    if (observed.isEmpty) return;

    final numbers = [for (final index in observed) values[index]!];
    var minimum = numbers.reduce((a, b) => a < b ? a : b);
    var maximum = numbers.reduce((a, b) => a > b ? a : b);

    // A single point, or several equal estimates, would otherwise divide by
    // zero. Give the line a small band so it sits across the middle.
    if ((maximum - minimum).abs() < 0.001) {
      minimum -= 1;
      maximum += 1;
    } else {
      final padding = (maximum - minimum) * 0.18;
      minimum -= padding;
      maximum += padding;
    }

    final rect = Rect.fromLTRB(6, 10, size.width - 6, size.height - 10);
    Offset pointAt(int index) {
      final x = values.length == 1
          ? rect.center.dx
          : rect.left + (index / (values.length - 1)) * rect.width;
      final value = values[index]!;
      final ratio = (value - minimum) / (maximum - minimum);
      return Offset(x, rect.bottom - ratio * rect.height);
    }

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Only join adjacent observed weeks. A missing week is a break, not an
    // invitation to invent the value between two sessions.
    for (var position = 1; position < observed.length; position++) {
      final previous = observed[position - 1];
      final current = observed[position];
      if (current != previous + 1) continue;
      canvas.drawLine(pointAt(previous), pointAt(current), line);
    }

    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final index in observed) {
      canvas.drawCircle(pointAt(index), 3.2, dot);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.color != color || !listEquals(oldDelegate.values, values);
}
