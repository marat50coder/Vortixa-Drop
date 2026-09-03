import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../veil/href_guard.dart';

/// Reads the URL `SceneDelegate` wrote into UserDefaults when a remote
/// push launched the app.
///
/// The Dart key must stay `vxdrop_tap_route` — SharedPreferences maps it
/// to `flutter.vxdrop_tap_route` on iOS.
abstract final class NativeSlot {
  static const String _slotKey = 'vxdrop_tap_route';

  static Future<String?> take() async {
    if (!Platform.isIOS) return null;
    try {
      final SharedPreferences box = await SharedPreferences.getInstance();
      await box.reload();
      final String? parked = box.getString(_slotKey);
      if (parked == null) return null;
      await box.remove(_slotKey);
      return HrefGuard.sanitize(parked);
    } catch (_) {
      return null;
    }
  }
}
