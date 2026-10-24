import 'package:equatable/equatable.dart';

import 'age.dart';

/// A personal best shown on the profile record list.
class PersonalRecord extends Equatable {
  const PersonalRecord({
    required this.id,
    required this.category,
    required this.name,
    required this.protocol,
    required this.value,
    required this.unit,
  });

  /// Short badge drawn on the left of the row ("BP", "5K", "DL").
  final String id;
  final String category;
  final String name;
  final String protocol;
  final String value;
  final String unit;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      protocol: json['protocol'] as String,
      value: json['value'] as String,
      unit: json['unit'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'name': name,
    'protocol': protocol,
    'value': value,
    'unit': unit,
  };

  @override
  List<Object?> get props => [id, category, name, protocol, value, unit];
}

/// A badge earned through consistency or load.
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  final String id;
  final String title;
  final String subtitle;

  /// One-line qualifier under the grid, e.g. "18 Total".
  final String detail;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      detail: json['detail'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'detail': detail,
  };

  @override
  List<Object?> get props => [id, title, subtitle, detail];
}

/// Everything the profile screen renders about the signed-in lifter.
class ProfileStats extends Equatable {
  /// A brand new account: no name, no history, nothing earned.
  ///
  /// Every field is zeroed rather than absent so the profile screen has
  /// numbers to render before the account has any. A screen reading `null`
  /// would need a branch per figure; zero renders as an honest "0" without
  /// one. Records and achievements are empty, since there is nothing to have
  /// earned yet.
  factory ProfileStats.empty() => const ProfileStats(
    name: '',
    handle: '',
    role: '',
    memberSince: '',
    isPro: false,
    dateOfBirth: null,
    weightKg: 0,
    heightCm: 0,
    bodyFatPct: 0,
    restingHrBpm: 0,
    totalWorkouts: 0,
    totalKcal: 0,
    totalHours: 0,
    streakDays: 0,
    badgeCount: 0,
    records: [],
    achievements: [],
  );
  const ProfileStats({
    this.name = '',
    required this.handle,
    required this.role,
    required this.memberSince,
    required this.isPro,
    this.dateOfBirth,
    required this.weightKg,
    required this.heightCm,
    required this.bodyFatPct,
    required this.restingHrBpm,
    required this.totalWorkouts,
    required this.totalKcal,
    required this.totalHours,
    required this.streakDays,
    required this.badgeCount,
    required this.records,
    required this.achievements,
  });

  final String name;
  final String handle;
  final String role;
  final String memberSince;
  final bool isPro;

  /// The date the sign-up asked for, or null when the account has not said.
  final DateTime? dateOfBirth;

  /// Years old, or zero when the account has not given a date.
  int get age => dateOfBirth == null ? 0 : ageInYears(dateOfBirth!);

  final double weightKg;
  final double heightCm;
  final double bodyFatPct;
  final int restingHrBpm;

  final int totalWorkouts;
  final int totalKcal;
  final int totalHours;
  final int streakDays;
  final int badgeCount;

  final List<PersonalRecord> records;
  final List<Achievement> achievements;

  ProfileStats copyWith({
    String? name,
    String? handle,
    String? role,
    String? memberSince,
    bool? isPro,
    DateTime? dateOfBirth,
    double? weightKg,
    double? heightCm,
    double? bodyFatPct,
    int? restingHrBpm,
    int? totalWorkouts,
    int? totalKcal,
    int? totalHours,
    int? streakDays,
    int? badgeCount,
    List<PersonalRecord>? records,
    List<Achievement>? achievements,
  }) {
    return ProfileStats(
      name: name ?? this.name,
      handle: handle ?? this.handle,
      role: role ?? this.role,
      memberSince: memberSince ?? this.memberSince,
      isPro: isPro ?? this.isPro,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      restingHrBpm: restingHrBpm ?? this.restingHrBpm,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalKcal: totalKcal ?? this.totalKcal,
      totalHours: totalHours ?? this.totalHours,
      streakDays: streakDays ?? this.streakDays,
      badgeCount: badgeCount ?? this.badgeCount,
      records: records ?? this.records,
      achievements: achievements ?? this.achievements,
    );
  }

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      name: json['name'] as String,
      handle: json['handle'] as String,
      role: json['role'] as String,
      memberSince: json['memberSince'] as String,
      isPro: json['isPro'] as bool? ?? false,
      dateOfBirth: json['dateOfBirth'] is String
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      bodyFatPct: (json['bodyFatPct'] as num).toDouble(),
      restingHrBpm: (json['restingHrBpm'] as num).toInt(),
      totalWorkouts: (json['totalWorkouts'] as num).toInt(),
      totalKcal: (json['totalKcal'] as num).toInt(),
      totalHours: (json['totalHours'] as num).toInt(),
      streakDays: (json['streakDays'] as num).toInt(),
      badgeCount: (json['badgeCount'] as num).toInt(),
      records: (json['records'] as List<dynamic>)
          .map((r) => PersonalRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>)
          .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'handle': handle,
    'role': role,
    'memberSince': memberSince,
    'isPro': isPro,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'weightKg': weightKg,
    'heightCm': heightCm,
    'bodyFatPct': bodyFatPct,
    'restingHrBpm': restingHrBpm,
    'totalWorkouts': totalWorkouts,
    'totalKcal': totalKcal,
    'totalHours': totalHours,
    'streakDays': streakDays,
    'badgeCount': badgeCount,
    'records': records.map((r) => r.toJson()).toList(),
    'achievements': achievements.map((a) => a.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    name,
    handle,
    role,
    memberSince,
    isPro,
    dateOfBirth,
    weightKg,
    heightCm,
    bodyFatPct,
    restingHrBpm,
    totalWorkouts,
    totalKcal,
    totalHours,
    streakDays,
    badgeCount,
    records,
    achievements,
  ];
}
