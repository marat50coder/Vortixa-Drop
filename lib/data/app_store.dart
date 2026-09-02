import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  static const _keyWorking = 'vx_working';
  static const _keySaved = 'vx_saved';
  static const _keyHistory = 'vx_history';
  static const _keySettings = 'vx_settings';

  static const maxQuickOptions = 8;
  static const maxOptions = 20;
  static const maxHistory = 80;

  String workingSetId = '';
  String workingSetName = 'Quick Choice';
  List<ChoiceOption> workingOptions = [];
  List<ChoiceSet> savedSets = [];
  List<HistoryEntry> history = [];
  AppSettings settings = AppSettings();
  DropMode mode = DropMode.quick;
  int pickCount = 2;
  int groupCount = 2;
  String? lastWinnerId;

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final settingsRaw = _prefs!.getString(_keySettings);
    if (settingsRaw != null) {
      settings = AppSettings.fromJson(
        jsonDecode(settingsRaw) as Map<String, dynamic>,
      );
    }
    final workingRaw = _prefs!.getString(_keyWorking);
    if (workingRaw != null) {
      final map = jsonDecode(workingRaw) as Map<String, dynamic>;
      workingSetId = map['id'] as String? ?? '';
      workingSetName = map['name'] as String? ?? 'Quick Choice';
      workingOptions = (map['options'] as List<dynamic>? ?? [])
          .map((e) => ChoiceOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final savedRaw = _prefs!.getString(_keySaved);
    if (savedRaw != null) {
      savedSets = (jsonDecode(savedRaw) as List<dynamic>)
          .map((e) => ChoiceSet.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final historyRaw = _prefs!.getString(_keyHistory);
    if (historyRaw != null) {
      history = (jsonDecode(historyRaw) as List<dynamic>)
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    AudioService.instance.enabled = settings.sound;
    HapticsService.instance.enabled = settings.haptics;
    notifyListeners();
  }

  Future<void> _persistWorking() async {
    await _prefs?.setString(
      _keyWorking,
      jsonEncode({
        'id': workingSetId,
        'name': workingSetName,
        'options': workingOptions.map((o) => o.toJson()).toList(),
      }),
    );
  }

  Future<void> _persistSaved() async {
    await _prefs?.setString(
      _keySaved,
      jsonEncode(savedSets.map((s) => s.toJson()).toList()),
    );
  }

  Future<void> _persistHistory() async {
    await _prefs?.setString(
      _keyHistory,
      jsonEncode(history.map((h) => h.toJson()).toList()),
    );
  }

  Future<void> _persistSettings() async {
    await _prefs?.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  int get optionCap => mode == DropMode.quick ? maxQuickOptions : maxOptions;

  String? validateDrop() {
    if (workingOptions.isEmpty) {
      return 'Add at least two options to start a Drop.';
    }
    if (workingOptions.length < 2) {
      return 'Quick Choice needs at least 2 options.';
    }
    if (mode == DropMode.quick && workingOptions.length > maxQuickOptions) {
      return 'Quick Choice supports up to $maxQuickOptions options.';
    }
    if (mode == DropMode.multi) {
      if (workingOptions.length < 3) {
        return 'Multi needs at least 3 options.';
      }
      if (pickCount < 1) return 'Choose at least 1 result.';
      if (pickCount > workingOptions.length) {
        return 'Cannot pick more results than options.';
      }
    }
    if (mode == DropMode.split) {
      if (groupCount < 2) return 'Split Mode needs at least 2 groups.';
      if (groupCount > workingOptions.length) {
        return 'Groups cannot exceed the number of options.';
      }
    }
    return null;
  }

  DropSession createSession() {
    switch (mode) {
      case DropMode.quick:
        return DropSession.quick(
          setName: workingSetName,
          options: workingOptions,
          excludeId: settings.skipRepeat ? lastWinnerId : null,
        );
      case DropMode.multi:
        return DropSession.multi(
          setName: workingSetName,
          options: workingOptions,
          pickCount: pickCount,
        );
      case DropMode.split:
        return DropSession.split(
          setName: workingSetName,
          options: workingOptions,
          groupCount: groupCount,
        );
    }
  }

  void setMode(DropMode value) {
    mode = value;
    if (mode == DropMode.multi) {
      pickCount = pickCount.clamp(2, workingOptions.length.clamp(2, 10));
    }
    if (mode == DropMode.split) {
      groupCount = groupCount.clamp(2, workingOptions.length.clamp(2, 8));
    }
    notifyListeners();
  }

  void setPickCount(int value) {
    pickCount = value.clamp(1, workingOptions.length.clamp(1, 10));
    notifyListeners();
  }

  void setGroupCount(int value) {
    groupCount = value.clamp(2, workingOptions.length.clamp(2, 10));
    notifyListeners();
  }

  void setWorkingName(String name) {
    workingSetName = name.trim().isEmpty ? 'Quick Choice' : name.trim();
    notifyListeners();
    _persistWorking();
  }

  void addOption(String label) {
    if (workingOptions.length >= optionCap) return;
    final used = workingOptions.map((o) => o.colorIndex).toSet();
    var color = 0;
    for (var i = 0; i < VxColors.ballTints.length; i++) {
      if (!used.contains(i)) {
        color = i;
        break;
      }
    }
    if (used.length >= VxColors.ballTints.length) {
      color = workingOptions.length % VxColors.ballTints.length;
    }
    workingOptions.add(
      ChoiceOption(
        id: DropSession.newId(),
        label: label.trim().isEmpty
            ? 'Option ${workingOptions.length + 1}'
            : label.trim(),
        colorIndex: color,
      ),
    );
    notifyListeners();
    _persistWorking();
  }

  void updateOption(String id, {String? label, int? colorIndex}) {
    final option = workingOptions.cast<ChoiceOption?>().firstWhere(
          (o) => o!.id == id,
          orElse: () => null,
        );
    if (option == null) return;
    if (label != null) option.label = label;
    if (colorIndex != null) option.colorIndex = colorIndex;
    notifyListeners();
    _persistWorking();
  }

  void removeOption(String id) {
    workingOptions.removeWhere((o) => o.id == id);
    notifyListeners();
    _persistWorking();
  }

  void newBlankSet() {
    workingSetId = '';
    workingSetName = 'New Set';
    workingOptions = [];
    notifyListeners();
    _persistWorking();
  }

  Future<void> saveWorkingSet() async {
    final now = DateTime.now();
    if (workingSetId.isEmpty) {
      workingSetId = DropSession.newId();
      savedSets.insert(
        0,
        ChoiceSet(
          id: workingSetId,
          name: workingSetName,
          options: workingOptions.map((o) => o.copy()).toList(),
          updatedAt: now,
        ),
      );
    } else {
      final index = savedSets.indexWhere((s) => s.id == workingSetId);
      final snapshot = ChoiceSet(
        id: workingSetId,
        name: workingSetName,
        options: workingOptions.map((o) => o.copy()).toList(),
        updatedAt: now,
      );
      if (index >= 0) {
        savedSets[index] = snapshot;
      } else {
        savedSets.insert(0, snapshot);
      }
    }
    notifyListeners();
    await _persistWorking();
    await _persistSaved();
  }

  void loadSavedSet(ChoiceSet set) {
    workingSetId = set.id;
    workingSetName = set.name;
    workingOptions = set.options.map((o) => o.copy()).toList();
    notifyListeners();
    _persistWorking();
  }

  void deleteSavedSet(String id) {
    savedSets.removeWhere((s) => s.id == id);
    if (workingSetId == id) workingSetId = '';
    notifyListeners();
    _persistSaved();
    _persistWorking();
  }

  Future<void> recordHistory(DropSession session) async {
    history.insert(0, session.toHistory());
    if (history.length > maxHistory) {
      history = history.take(maxHistory).toList();
    }
    final winnerIds = session.mode == DropMode.split
        ? <String>{}
        : session.winners.map((o) => o.id).toSet();
    if (winnerIds.isNotEmpty) {
      lastWinnerId = session.winners.first.id;
      for (final option in workingOptions) {
        if (winnerIds.contains(option.id)) option.wins += 1;
      }
      await _persistWorking();
    }
    settings.totalDrops += 1;
    final today = _dayKey(DateTime.now());
    final last = settings.streakDate;
    if (last == today) {
      // same day, keep as-is
    } else if (last != null && _isYesterday(last, today)) {
      settings.streakCount += 1;
    } else {
      settings.streakCount = 1;
    }
    settings.streakDate = today;
    if (settings.streakCount > settings.bestStreak) {
      settings.bestStreak = settings.streakCount;
    }
    await _persistSettings();
    notifyListeners();
    await _persistHistory();
  }

  static String _dayKey(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  static bool _isYesterday(String yesterday, String today) {
    final y = DateTime.tryParse(yesterday);
    final t = DateTime.tryParse(today);
    if (y == null || t == null) return false;
    return t.difference(y).inDays == 1;
  }

  void applyPreset(String name, List<String> labels) {
    workingSetId = '';
    workingSetName = name;
    workingOptions = [];
    for (final label in labels) {
      addOption(label);
    }
  }

  Future<void> clearHistory() async {
    history = [];
    notifyListeners();
    await _persistHistory();
  }

  Future<void> setSound(bool value) async {
    settings.sound = value;
    AudioService.instance.enabled = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setHaptics(bool value) async {
    settings.haptics = value;
    HapticsService.instance.enabled = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setAnimations(bool value) async {
    settings.animations = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> setSkipRepeat(bool value) async {
    settings.skipRepeat = value;
    notifyListeners();
    await _persistSettings();
  }

  Future<void> completeOnboarding() async {
    settings.onboardingComplete = true;
    notifyListeners();
    await _persistSettings();
  }

  bool isFavoriteSet(String id) => settings.favoriteSetIds.contains(id);

  Future<void> toggleFavoriteSet(String id) async {
    final next = [...settings.favoriteSetIds];
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    settings.favoriteSetIds = next;
    notifyListeners();
    await _persistSettings();
  }

  void shuffleColors() {
    final colors = List<int>.generate(workingOptions.length, (i) => i);
    colors.shuffle();
    for (var i = 0; i < workingOptions.length; i++) {
      workingOptions[i].colorIndex = colors[i] % VxColors.ballTints.length;
    }
    notifyListeners();
    _persistWorking();
  }

  void resetWinCounts() {
    for (final option in workingOptions) {
      option.wins = 0;
    }
    notifyListeners();
    _persistWorking();
  }
}
