import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/age.dart';
import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'auth_action.dart';
import 'date_of_birth_field.dart';
import 'measurement_fields.dart';

/// Date of birth, height and weight, opened from the profile's Body section.
Future<void> showEditBodySheet(BuildContext context) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final animationStyle = reduceMotion
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: AppMotion.sheetIn,
          reverseDuration: AppMotion.sheetOut,
        );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: animationStyle,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const EditBodySheet(),
  );
}

class EditBodySheet extends StatefulWidget {
  const EditBodySheet({super.key});

  @override
  State<EditBodySheet> createState() => _EditBodySheetState();
}

class _EditBodySheetState extends State<EditBodySheet> {
  DateTime? _dateOfBirth;
  double? _heightCm;
  double? _weightKg;
  bool _heightImperial = false;
  bool _weightImperial = false;
  String? _dateError;
  String? _heightError;
  String? _weightError;

  static const int minimumAge = 13;
  static const int maximumAge = 120;

  @override
  void initState() {
    super.initState();
    final profile = context.read<WorkoutProvider>().profile;
    _dateOfBirth = profile.dateOfBirth;
    _heightCm = profile.heightCm > 0 ? profile.heightCm : null;
    _weightKg = profile.weightKg > 0 ? profile.weightKg : null;
    _heightImperial = profile.heightImperial;
    _weightImperial = profile.weightImperial;
  }

  void _save() {
    final dateOfBirth = _dateOfBirth;
    final height = _heightCm;
    final weight = _weightKg;

    final dateProblem = switch (dateOfBirth) {
      null => 'Choose your date of birth.',
      _ => switch (ageInYears(dateOfBirth)) {
        < minimumAge => 'You must be at least $minimumAge.',
        > maximumAge => 'Enter a date under $maximumAge years ago.',
        _ => null,
      },
    };
    final heightProblem = switch (height) {
      null => 'Enter your height.',
      < 50 => 'Enter a height over 50 cm.',
      > 300 => 'Enter a height under 300 cm.',
      _ => null,
    };
    final weightProblem = switch (weight) {
      null => 'Enter your weight.',
      < 20 => 'Enter a weight over 20 kg.',
      > 500 => 'Enter a weight under 500 kg.',
      _ => null,
    };

    setState(() {
      _dateError = dateProblem;
      _heightError = heightProblem;
      _weightError = weightProblem;
    });
    if (dateProblem != null || heightProblem != null || weightProblem != null) {
      return;
    }

    final provider = context.read<WorkoutProvider>();
    provider.updateProfile(
      provider.profile.copyWith(
        dateOfBirth: dateOfBirth,
        heightCm: height,
        weightKg: weight,
        heightImperial: _heightImperial,
        weightImperial: _weightImperial,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'EDIT BODY.',
              style: text.exerciseName.copyWith(
                fontSize: 32,
                letterSpacing: -1.28,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 24),
            DateOfBirthField(
              label: 'DATE OF BIRTH',
              initialDate: _dateOfBirth,
              errorText: _dateError,
              onChanged: (value) => setState(() {
                _dateOfBirth = value;
                if (value != null) _dateError = null;
              }),
            ),
            const SizedBox(height: 20),
            HeightField(
              initialHeightCm: _heightCm,
              initialImperial: _heightImperial,
              errorText: _heightError,
              onChanged: (value) => setState(() {
                _heightCm = value;
                if (value != null) _heightError = null;
              }),
              onUnitChanged: (imperial) =>
                  setState(() => _heightImperial = imperial),
            ),
            const SizedBox(height: 20),
            WeightField(
              initialWeightKg: _weightKg,
              initialImperial: _weightImperial,
              errorText: _weightError,
              onChanged: (value) => setState(() {
                _weightKg = value;
                if (value != null) _weightError = null;
              }),
              onUnitChanged: (imperial) =>
                  setState(() => _weightImperial = imperial),
            ),
            const SizedBox(height: 24),
            AuthAction(label: 'Save changes', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
