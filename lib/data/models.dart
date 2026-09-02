import 'dart:math';

enum DropMode { quick, multi, split }

class ChoiceOption {
  ChoiceOption({
    required this.id,
    required this.label,
    required this.colorIndex,
    this.wins = 0,
  });

  final String id;
  String label;
  int colorIndex;
  int wins;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'colorIndex': colorIndex,
        'wins': wins,
      };

  factory ChoiceOption.fromJson(Map<String, dynamic> json) {
    return ChoiceOption(
      id: json['id'] as String,
      label: json['label'] as String,
      colorIndex: json['colorIndex'] as int,
      wins: json['wins'] as int? ?? 0,
    );
  }

  ChoiceOption copy() => ChoiceOption(
        id: id,
        label: label,
        colorIndex: colorIndex,
        wins: wins,
      );
}

class ChoiceSet {
  ChoiceSet({
    required this.id,
    required this.name,
    required this.options,
    required this.updatedAt,
  });

  final String id;
  String name;
  List<ChoiceOption> options;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'options': options.map((o) => o.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChoiceSet.fromJson(Map<String, dynamic> json) {
    return ChoiceSet(
      id: json['id'] as String,
      name: json['name'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => ChoiceOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.setName,
    required this.mode,
    required this.results,
    required this.at,
    this.groups,
  });

  final String id;
  final String setName;
  final DropMode mode;
  final List<String> results;
  final List<List<String>>? groups;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'setName': setName,
        'mode': mode.name,
        'results': results,
        'groups': groups,
        'at': at.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'];
    return HistoryEntry(
      id: json['id'] as String,
      setName: json['setName'] as String,
      mode: DropMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => DropMode.quick,
      ),
      results: (json['results'] as List<dynamic>).cast<String>(),
      groups: rawGroups == null
          ? null
          : (rawGroups as List<dynamic>)
              .map((g) => (g as List<dynamic>).cast<String>())
              .toList(),
      at: DateTime.parse(json['at'] as String),
    );
  }
}

class DropSession {
  DropSession({
    required this.mode,
    required this.setName,
    required this.options,
    required this.winners,
    this.pickCount = 1,
    this.groupCount = 2,
    this.groups = const [],
  });

  final DropMode mode;
  final String setName;
  final List<ChoiceOption> options;
  final List<ChoiceOption> winners;
  final int pickCount;
  final int groupCount;
  final List<List<ChoiceOption>> groups;

  static final Random _rng = Random();

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(1 << 32)}';

  static DropSession quick({
    required String setName,
    required List<ChoiceOption> options,
    String? excludeId,
  }) {
    var copy = options.map((o) => o.copy()).toList();
    if (excludeId != null && copy.length > 2) {
      final filtered = copy.where((o) => o.id != excludeId).toList();
      if (filtered.length >= 2) copy = filtered;
    }
    final winner = copy[_rng.nextInt(copy.length)];
    return DropSession(
      mode: DropMode.quick,
      setName: setName,
      options: options.map((o) => o.copy()).toList(),
      winners: [winner],
    );
  }

  static DropSession multi({
    required String setName,
    required List<ChoiceOption> options,
    required int pickCount,
  }) {
    final copy = options.map((o) => o.copy()).toList()..shuffle(_rng);
    final take = pickCount.clamp(1, copy.length);
    return DropSession(
      mode: DropMode.multi,
      setName: setName,
      options: copy,
      pickCount: take,
      winners: copy.take(take).toList(),
    );
  }

  static DropSession split({
    required String setName,
    required List<ChoiceOption> options,
    required int groupCount,
  }) {
    final copy = options.map((o) => o.copy()).toList()..shuffle(_rng);
    final count = groupCount.clamp(2, copy.length);
    final buckets = List<List<ChoiceOption>>.generate(count, (_) => []);
    for (var i = 0; i < copy.length; i++) {
      buckets[i % count].add(copy[i]);
    }
    return DropSession(
      mode: DropMode.split,
      setName: setName,
      options: copy,
      groupCount: count,
      winners: const [],
      groups: buckets,
    );
  }

  HistoryEntry toHistory() {
    if (mode == DropMode.split) {
      return HistoryEntry(
        id: newId(),
        setName: setName,
        mode: mode,
        results: groups
            .expand((g) => g)
            .map((o) => o.label)
            .toList(growable: false),
        groups: groups
            .map((g) => g.map((o) => o.label).toList())
            .toList(growable: false),
        at: DateTime.now(),
      );
    }
    return HistoryEntry(
      id: newId(),
      setName: setName,
      mode: mode,
      results: winners.map((o) => o.label).toList(growable: false),
      at: DateTime.now(),
    );
  }
}

class AppSettings {
  AppSettings({
    this.sound = true,
    this.haptics = true,
    this.animations = true,
    this.skipRepeat = false,
    this.onboardingComplete = false,
    this.totalDrops = 0,
    this.streakCount = 0,
    this.streakDate,
    this.bestStreak = 0,
    this.favoriteSetIds = const [],
  });

  bool sound;
  bool haptics;
  bool animations;
  bool skipRepeat;
  bool onboardingComplete;
  int totalDrops;
  int streakCount;
  String? streakDate;
  int bestStreak;
  List<String> favoriteSetIds;

  Map<String, dynamic> toJson() => {
        'sound': sound,
        'haptics': haptics,
        'animations': animations,
        'skipRepeat': skipRepeat,
        'onboardingComplete': onboardingComplete,
        'totalDrops': totalDrops,
        'streakCount': streakCount,
        'streakDate': streakDate,
        'bestStreak': bestStreak,
        'favoriteSetIds': favoriteSetIds,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      sound: json['sound'] as bool? ?? true,
      haptics: json['haptics'] as bool? ?? true,
      animations: json['animations'] as bool? ?? true,
      skipRepeat: json['skipRepeat'] as bool? ?? false,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      totalDrops: json['totalDrops'] as int? ?? 0,
      streakCount: json['streakCount'] as int? ?? 0,
      streakDate: json['streakDate'] as String?,
      bestStreak: json['bestStreak'] as int? ?? 0,
      favoriteSetIds: (json['favoriteSetIds'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }
}
