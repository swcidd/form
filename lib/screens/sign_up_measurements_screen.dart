import 'package:flutter/material.dart';

import '../models/sign_up_draft.dart';
import '../widgets/auth_action.dart';
import '../widgets/auth_form_area.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_intro.dart';
import '../widgets/measurement_fields.dart';
import '../widgets/sign_up_steps.dart';
import 'sign_up_account_screen.dart';
import 'sign_up_footer.dart';

/// Sign-up, step three: the numbers the profile starts from.
class SignUpMeasurementsScreen extends StatefulWidget {
  const SignUpMeasurementsScreen({super.key, required this.draft});

  final SignUpDraft draft;

  @override
  State<SignUpMeasurementsScreen> createState() =>
      _SignUpMeasurementsScreenState();
}

class _SignUpMeasurementsScreenState extends State<SignUpMeasurementsScreen> {
  double? _heightCm;
  double? _weightKg;

  String? _heightError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _heightCm = widget.draft.heightCm;
    _weightKg = widget.draft.weightKg;
  }

  void _continue() {
    final height = _heightCm;
    final weight = _weightKg;

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
      _heightError = heightProblem;
      _weightError = weightProblem;
    });
    if (heightProblem != null || weightProblem != null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SignUpAccountScreen(
          draft: widget.draft.withMeasurements(
            heightCm: height!,
            weightKg: weight!,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AuthHero(
            kicker: 'YOUR TRAINING / STARTS HERE',
            headline: 'KNOW YOUR\nSTARTING LINE.',
            onBack: () => Navigator.of(context).maybePop(),
            height: 260,
          ),
          AuthFormArea(
            top: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SignUpSteps(current: 2),
                const SizedBox(height: 24),
                const AuthIntro(title: 'MEASUREMENTS.'),
                const SizedBox(height: 24),
                HeightField(
                  initialHeightCm: widget.draft.heightCm,
                  errorText: _heightError,
                  onChanged: (value) {
                    setState(() {
                      _heightCm = value;
                      if (value != null) _heightError = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                WeightField(
                  initialWeightKg: widget.draft.weightKg,
                  errorText: _weightError,
                  onChanged: (value) {
                    setState(() {
                      _weightKg = value;
                      if (value != null) _weightError = null;
                    });
                  },
                ),
              ],
            ),
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthAction(label: 'Continue', onPressed: _continue),
                const SizedBox(height: 12),
                const SignUpFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
