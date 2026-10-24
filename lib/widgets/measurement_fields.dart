import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'auth_field.dart';

/// Height in centimetres, or feet and inches behind a unit toggle.
///
/// The canonical value is always centimetres. Switching units only changes how
/// the same height is written down, so the profile does not have to remember
/// which one it was given in.
class HeightField extends StatefulWidget {
  const HeightField({
    super.key,
    this.initialHeightCm,
    this.initialImperial = false,
    required this.onChanged,
    this.onUnitChanged,
    this.errorText,
    this.enabled = true,
  });

  final double? initialHeightCm;
  final bool initialImperial;
  final ValueChanged<double?> onChanged;

  /// Reports the unit the athlete chose, so the profile can remember it.
  final ValueChanged<bool>? onUnitChanged;

  final String? errorText;
  final bool enabled;

  @override
  State<HeightField> createState() => _HeightFieldState();
}

class _HeightFieldState extends State<HeightField> {
  final _cm = TextEditingController();
  final _feet = TextEditingController();
  final _inches = TextEditingController();

  bool _imperial = false;
  double? _heightCm;

  @override
  void initState() {
    super.initState();
    _heightCm = widget.initialHeightCm;
    _imperial = widget.initialImperial;
    _writeCurrent();
  }

  @override
  void dispose() {
    _cm.dispose();
    _feet.dispose();
    _inches.dispose();
    super.dispose();
  }

  void _selectUnit(bool imperial) {
    if (imperial == _imperial) return;
    setState(() {
      _imperial = imperial;
      _writeCurrent();
    });
    widget.onUnitChanged?.call(imperial);
  }

  void _writeCurrent() {
    final cm = _heightCm;
    if (cm == null) {
      _cm.clear();
      _feet.clear();
      _inches.clear();
      return;
    }
    if (!_imperial) {
      _cm.text = _format(cm);
      return;
    }
    final totalInches = cm / 2.54;
    var feet = totalInches ~/ 12;
    var inches = totalInches - feet * 12;
    inches = (inches * 10).roundToDouble() / 10;
    if (inches >= 12) {
      feet += 1;
      inches = 0;
    }
    _feet.text = '$feet';
    _inches.text = _format(inches);
  }

  void _changed() {
    _heightCm = _read();
    widget.onChanged(_heightCm);
  }

  double? _read() {
    if (!_imperial) {
      final cm = _number(_cm.text);
      return cm == null || cm <= 0 ? null : cm;
    }
    final feet = _number(_feet.text);
    if (feet == null || feet <= 0) return null;
    final inches = _number(_inches.text) ?? 0;
    if (inches < 0) return null;
    return (feet * 12 + inches) * 2.54;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('HEIGHT', style: context.text.labelCaps),
        const SizedBox(height: 8),
        _UnitToggle(
          imperialLabel: 'FEET',
          metricLabel: 'CENTIMETERS',
          imperial: _imperial,
          enabled: widget.enabled,
          onChanged: _selectUnit,
        ),
        const SizedBox(height: 12),
        if (!_imperial)
          AuthField(
            label: 'CENTIMETRES',
            controller: _cm,
            hint: 'e.g. 178',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _numberFormatters,
            textInputAction: TextInputAction.next,
            errorText: widget.errorText,
            enabled: widget.enabled,
            onChanged: (_) => _changed(),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuthField(
                  label: 'FEET',
                  controller: _feet,
                  hint: '5',
                  keyboardType: TextInputType.number,
                  inputFormatters: _numberFormatters,
                  textInputAction: TextInputAction.next,
                  errorText: widget.errorText,
                  enabled: widget.enabled,
                  onChanged: (_) => _changed(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthField(
                  label: 'INCHES',
                  controller: _inches,
                  hint: '9',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _numberFormatters,
                  textInputAction: TextInputAction.next,
                  enabled: widget.enabled,
                  onChanged: (_) => _changed(),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Weight in kilograms, or pounds behind a unit toggle.
class WeightField extends StatefulWidget {
  const WeightField({
    super.key,
    this.initialWeightKg,
    this.initialImperial = false,
    required this.onChanged,
    this.onUnitChanged,
    this.errorText,
    this.enabled = true,
  });

  final double? initialWeightKg;
  final bool initialImperial;
  final ValueChanged<double?> onChanged;

  /// Reports the unit the athlete chose, so the profile can remember it.
  final ValueChanged<bool>? onUnitChanged;

  final String? errorText;
  final bool enabled;

  @override
  State<WeightField> createState() => _WeightFieldState();
}

class _WeightFieldState extends State<WeightField> {
  final _kg = TextEditingController();
  final _lb = TextEditingController();

  bool _imperial = false;
  double? _weightKg;

  @override
  void initState() {
    super.initState();
    _weightKg = widget.initialWeightKg;
    _imperial = widget.initialImperial;
    _writeCurrent();
  }

  @override
  void dispose() {
    _kg.dispose();
    _lb.dispose();
    super.dispose();
  }

  void _selectUnit(bool imperial) {
    if (imperial == _imperial) return;
    setState(() {
      _imperial = imperial;
      _writeCurrent();
    });
    widget.onUnitChanged?.call(imperial);
  }

  void _writeCurrent() {
    final kg = _weightKg;
    if (kg == null) {
      _kg.clear();
      _lb.clear();
      return;
    }
    if (_imperial) {
      _lb.text = _format(kg * 2.2046226218);
    } else {
      _kg.text = _format(kg);
    }
  }

  void _changed() {
    final text = _imperial ? _lb.text : _kg.text;
    final value = _number(text);
    _weightKg = value == null || value <= 0
        ? null
        : _imperial
        ? value / 2.2046226218
        : value;
    widget.onChanged(_weightKg);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('WEIGHT', style: context.text.labelCaps),
        const SizedBox(height: 8),
        _UnitToggle(
          imperialLabel: 'POUNDS',
          metricLabel: 'KILOGRAMS',
          imperial: _imperial,
          enabled: widget.enabled,
          onChanged: _selectUnit,
        ),
        const SizedBox(height: 12),
        AuthField(
          label: _imperial ? 'POUNDS' : 'KILOGRAMMES',
          controller: _imperial ? _lb : _kg,
          hint: _imperial ? 'e.g. 165' : 'e.g. 75',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _numberFormatters,
          textInputAction: TextInputAction.done,
          errorText: widget.errorText,
          enabled: widget.enabled,
          onChanged: (_) => _changed(),
        ),
      ],
    );
  }
}

/// The two units for one measurement, with the one in use filled in the
/// design system's signature green.
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({
    required this.imperialLabel,
    required this.metricLabel,
    required this.imperial,
    required this.onChanged,
    this.enabled = true,
  });

  final String imperialLabel;
  final String metricLabel;
  final bool imperial;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.control,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              context,
              label: imperialLabel,
              selected: imperial,
              value: true,
            ),
          ),
          Container(width: 1, color: scheme.outlineVariant),
          Expanded(
            child: _segment(
              context,
              label: metricLabel,
              selected: !imperial,
              value: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required bool selected,
    required bool value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final style = context.text.labelCaps.copyWith(
      color: selected ? AppColors.ink : scheme.onSurfaceVariant,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.lime : scheme.surface,
        child: InkWell(
          onTap: enabled ? () => onChanged(value) : null,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

final List<TextInputFormatter> _numberFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
];

double? _number(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

String _format(double value) {
  final rounded = (value * 10).roundToDouble() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
}
