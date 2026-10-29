/// The vocabularies FORM classifies its training with.
///
/// One file rather than loose strings on each model: the exercise catalogue,
/// the workout record and the filters all have to agree on what a "modality"
/// is, and a spelling that only one of them knows is a filter that silently
/// matches nothing.
///
/// Each enum keeps its [wire] name separate from its [label]. The wire name is
/// what SQLite rows and the bundled JSON carry and must never be renamed once
/// shipped; the label is what the UI shows and can change freely.
library;

/// What an exercise is, at the top level.
///
/// `stretching` is the catalogue's historical spelling of what the product
/// calls Mobility; the wire name stays so saved rows keep parsing.
enum ExerciseCategory {
  strength('strength', 'Strength'),
  cardio('cardio', 'Cardio'),
  mobility('stretching', 'Mobility'),
  plyometrics('plyometrics', 'Plyometrics'),
  calisthenics('calisthenics', 'Calisthenics'),
  calisthenicSkills('calisthenic_skills', 'Calisthenic skills'),
  strongman('strongman', 'Strongman'),
  powerlifting('powerlifting', 'Powerlifting');

  const ExerciseCategory(this.wire, this.label);

  final String wire;
  final String label;

  /// True for the bodyweight-discipline branches, which share the equipment
  /// vocabulary and are the two the product treats as distinct.
  bool get isCalisthenic =>
      this == ExerciseCategory.calisthenics ||
      this == ExerciseCategory.calisthenicSkills;

  /// Parses a catalogue value, tolerating the older spellings that saved rows
  /// and the two upstream data sets still carry.
  static ExerciseCategory? tryParse(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toLowerCase().replaceAll('-', '_');
    if (value.isEmpty) return null;
    for (final category in ExerciseCategory.values) {
      if (category.wire == value) return category;
    }
    return switch (value) {
      'mobility' || 'stretch' => ExerciseCategory.mobility,
      'calisthenics_skills' ||
      'calisthenic_skill' => ExerciseCategory.calisthenicSkills,
      'plyometric' => ExerciseCategory.plyometrics,
      _ => null,
    };
  }
}

/// Push / pull / legs, the axis a session is named from.
enum Movement {
  push('push', 'Push'),
  pull('pull', 'Pull'),
  legs('legs', 'Legs');

  const Movement(this.wire, this.label);

  final String wire;
  final String label;

  static Movement? tryParse(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toLowerCase();
    for (final movement in Movement.values) {
      if (movement.wire == value) return movement;
    }
    return null;
  }
}

/// How many joints an exercise moves.
enum Mechanic {
  compound('compound', 'Compound'),
  isolation('isolation', 'Isolation');

  const Mechanic(this.wire, this.label);

  final String wire;
  final String label;

  static Mechanic? tryParse(String? raw) {
    if (raw == null) return null;
    for (final mechanic in Mechanic.values) {
      if (mechanic.wire == raw.trim().toLowerCase()) return mechanic;
    }
    return null;
  }
}

/// Equipment, reduced to the vocabulary the filters expose.
///
/// The catalogue keeps its own longer list ("bench", "bands", "medicine ball")
/// because the detail screen benefits from the precision. Everything else maps
/// to one of these six for filtering.
enum Equipment {
  barbell('barbell', 'Barbell'),
  dumbbell('dumbbell', 'Dumbbell'),
  machine('machine', 'Machine'),
  cable('cable', 'Cable'),
  bodyweight('bodyweight', 'Bodyweight'),
  other('other', 'Other');

  const Equipment(this.wire, this.label);

  final String wire;
  final String label;

  /// Maps a catalogue equipment string to the filter vocabulary.
  static Equipment fromCatalogue(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'barbell' || 'ez curl bar' => barbell,
      'dumbbell' || 'kettlebell' || 'kettlebells' => dumbbell,
      'machine' || 'bench' => machine,
      'cable' => cable,
      'body only' || 'bodyweight' || 'none' => bodyweight,
      _ => other,
    };
  }
}

/// What a session is built around.
enum WorkoutSplit {
  push('push', 'Push'),
  pull('pull', 'Pull'),
  legs('legs', 'Legs'),
  upper('upper', 'Upper'),
  lower('lower', 'Lower'),
  fullBody('full_body', 'Full body'),
  coreArms('core_arms', 'Core / Arms'),
  custom('custom', 'Custom');

  const WorkoutSplit(this.wire, this.label);

  final String wire;
  final String label;

  static WorkoutSplit? tryParse(String? raw) {
    if (raw == null) return null;
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    for (final split in WorkoutSplit.values) {
      if (split.wire == value) return split;
    }
    return switch (value) {
      'fullbody' => WorkoutSplit.fullBody,
      'core/arms' || 'arms' || 'core' => WorkoutSplit.coreArms,
      _ => null,
    };
  }
}

/// What the training is for.
enum TrainingGoal {
  strength('strength', 'Strength'),
  hypertrophy('hypertrophy', 'Hypertrophy'),
  endurance('endurance', 'Endurance'),
  power('power', 'Power'),
  general('general', 'General'),
  skills('skills', 'Skills');

  const TrainingGoal(this.wire, this.label);

  final String wire;
  final String label;

  static TrainingGoal? tryParse(String? raw) {
    if (raw == null) return null;
    for (final goal in TrainingGoal.values) {
      if (goal.wire == raw.trim().toLowerCase()) return goal;
    }
    return null;
  }
}

/// The mode of training a session is.
///
/// Strength / Cardio / Mobility / Circuit are the four the product started
/// with; the last three are the disciplines added alongside them.
enum Modality {
  strength('strength', 'Strength'),
  cardio('cardio', 'Cardio'),
  mobilityWarmUp('mobility_warm_up', 'Mobility / Warm-up'),
  circuitHiit('circuit_hiit', 'Circuit / HIIT'),
  calisthenics('calisthenics', 'Calisthenics'),
  calisthenicSkills('calisthenic_skills', 'Calisthenic skills'),
  plyometrics('plyometrics', 'Plyometrics');

  const Modality(this.wire, this.label);

  final String wire;
  final String label;

  /// The categories this modality groups in the exercise catalogue.
  Set<ExerciseCategory> get categories => switch (this) {
    Modality.strength => {
      ExerciseCategory.strength,
      ExerciseCategory.strongman,
      ExerciseCategory.powerlifting,
    },
    Modality.cardio => {ExerciseCategory.cardio},
    Modality.mobilityWarmUp => {ExerciseCategory.mobility},
    Modality.circuitHiit => {
      ExerciseCategory.strength,
      ExerciseCategory.cardio,
      ExerciseCategory.calisthenics,
    },
    Modality.calisthenics => {ExerciseCategory.calisthenics},
    Modality.calisthenicSkills => {ExerciseCategory.calisthenicSkills},
    Modality.plyometrics => {ExerciseCategory.plyometrics},
  };

  static Modality? tryParse(String? raw) {
    if (raw == null) return null;
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    for (final modality in Modality.values) {
      if (modality.wire == value) return modality;
    }
    return switch (value) {
      'mobility' || 'warmup' || 'warm_up' => Modality.mobilityWarmUp,
      'circuit' || 'hiit' => Modality.circuitHiit,
      _ => null,
    };
  }
}

/// A routine is a template; a session is one logged occurrence of it.
enum WorkoutKind {
  routine('routine', 'Routine'),
  session('session', 'Session');

  const WorkoutKind(this.wire, this.label);

  final String wire;
  final String label;

  static WorkoutKind? tryParse(String? raw) {
    if (raw == null) return null;
    for (final kind in WorkoutKind.values) {
      if (kind.wire == raw.trim().toLowerCase()) return kind;
    }
    return null;
  }
}

/// How long a session is expected to take, for the "60 min" shorthand.
enum DurationBand {
  short('short', 'Short'),
  medium('medium', 'Medium'),
  long('long', 'Long');

  const DurationBand(this.wire, this.label);

  final String wire;
  final String label;

  /// Bands a duration in minutes. Short is anything up to half an hour,
  /// medium up to the hour, long beyond it.
  static DurationBand fromMinutes(int minutes) {
    if (minutes <= 30) return short;
    if (minutes <= 60) return medium;
    return long;
  }
}

/// Display label for a catalogue category string, without having to parse.
String categoryLabel(String raw) =>
    ExerciseCategory.tryParse(raw)?.label ?? _titleCase(raw);

/// Display label for a catalogue equipment string ("body only" → Bodyweight).
String equipmentLabel(String raw) => Equipment.fromCatalogue(raw).label;

String _titleCase(String raw) {
  if (raw.isEmpty) return raw;
  return raw
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
