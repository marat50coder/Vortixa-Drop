import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../kine_chart.dart';
import '../veil/href_guard.dart';
import '../veil/path_kinds.dart';

/// Launch-to-launch state: last path, cached destination, invite bookkeeping,
/// and any tap waiting for a pane.
class LaneChest {
  static const String _laneKey = 'vxdrop::flux/lane';
  static const String _cacheExpiryKey = 'vxdrop::flux/cache_expiry';
  static const String _inviteReadyAtKey = 'vxdrop::flux/invite_ready_at';
  static const String _pushGrantedKey = 'vxdrop::flux/push_granted';
  static const String _pushOsRefusedKey = 'vxdrop::flux/push_os_refused';
  static const String _cachedUrlKey = 'vxdrop::flux/cached_url';
  static const String _parkedUrlKey = 'vxdrop::flux/parked_url';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  Future<void> prepare() async {
    _prefs = await SharedPreferences.getInstance();
  }

  PathKind get lane => PathKind.read(_prefs.getString(_laneKey));

  Future<void> writeLane(PathKind lane) =>
      _prefs.setString(_laneKey, lane.token);

  Future<String?> readCachedUrl() async {
    try {
      return await _secure.read(key: _cachedUrlKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeCachedUrl(String url, int? explicitExpiry) async {
    try {
      await _secure.write(key: _cachedUrlKey, value: url);
      final int expiry =
          explicitExpiry ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000 +
              KineChart.savedUrlTtlSeconds;
      await _prefs.setInt(_cacheExpiryKey, expiry);
    } catch (_) {}
  }

  bool get cachedUrlStale {
    final int? expiry = _prefs.getInt(_cacheExpiryKey);
    return expiry == null ||
        DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiry;
  }

  Future<void> parkUrl(String url) async {
    final String? cleaned = HrefGuard.sanitize(url);
    if (cleaned == null) return;
    try {
      await _secure.write(key: _parkedUrlKey, value: cleaned);
    } catch (_) {}
  }

  Future<String?> takeParkedUrl() async {
    try {
      final String? parked = await _secure.read(key: _parkedUrlKey);
      if (parked != null) await _secure.delete(key: _parkedUrlKey);
      return HrefGuard.sanitize(parked);
    } catch (_) {
      return null;
    }
  }

  bool get pushGranted => _prefs.getBool(_pushGrantedKey) ?? false;
  bool get pushRefusedByOs => _prefs.getBool(_pushOsRefusedKey) ?? false;

  Future<void> writePushGranted(bool value) =>
      _prefs.setBool(_pushGrantedKey, value);

  Future<void> markPushRefusedByOs() =>
      _prefs.setBool(_pushOsRefusedKey, true);

  bool get inviteAllowed {
    if (pushGranted || pushRefusedByOs) return false;
    final int? readyAt = _prefs.getInt(_inviteReadyAtKey);
    return readyAt == null ||
        DateTime.now().millisecondsSinceEpoch ~/ 1000 >= readyAt;
  }

  Future<void> snoozeInvite(int untilEpochSeconds) =>
      _prefs.setInt(_inviteReadyAtKey, untilEpochSeconds);
}
