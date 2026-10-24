import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/workout_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'auth_action.dart';
import 'auth_field.dart';
import 'measurement_fields.dart';

/// Age, height and weight, opened from the profile's Body section.
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
  final _age = TextEditingController();

  double? _heightCm;
  double? _weightKg;
  String? _ageError;
  String? _heightError;
  String? _weightError;

  static const int minimumAge = 13;
  static const int maximumAge = 120;

  @override
  void initState() {
    super.initState();
    final profile = context.read<WorkoutProvider>().profile;
    if (profile.age > 0) _age.text = '${profile.age}';
    _heightCm = profile.heightCm > 0 ? profile.heightCm : null;
    _weightKg = profile.weightKg > 0 ? profile.weightKg : null;
  }

  @override
  void dispose() {
    _age.dispose();
    super.dispose();
  }

  void _save() {
    final age = int.tryParse(_age.text.trim());
    final height = _heightCm;
    final weight = _weightKg;

    final ageProblem = switch (age) {
      null => 'Enter your age.',
      < minimumAge => 'You must be at least $minimumAge.',
      > maximumAge => 'Enter an age under $maximumAge.',
      _ => null,
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
      _ageError = ageProblem;
      _heightError = heightProblem;
      _weightError = weightProblem;
    });
    if (ageProblem != null || heightProblem != null || weightProblem != null) {
      return;
    }

    final provider = context.read<WorkoutProvider>();
    provider.updateProfile(
      provider.profile.copyWith(age: age, heightCm: height, weightKg: weight),
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
            AuthField(
              label: 'AGE',
              controller: _age,
              hint: 'Years',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              errorText: _ageError,
              onChanged: (_) {
                if (_ageError != null) setState(() => _ageError = null);
              },
            ),
            const SizedBox(height: 20),
            HeightField(
              initialHeightCm: _heightCm,
              errorText: _heightError,
              onChanged: (value) => setState(() {
                _heightCm = value;
                if (value != null) _heightError = null;
              }),
            ),
            const SizedBox(height: 20),
            WeightField(
              initialWeightKg: _weightKg,
              errorText: _weightError,
              onChanged: (value) => setState(() {
                _weightKg = value;
                if (value != null) _weightError = null;
              }),
            ),
            const SizedBox(height: 24),
            AuthAction(label: 'Save changes', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
