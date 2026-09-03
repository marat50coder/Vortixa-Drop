import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import '../kine_chart.dart';

/// http.Client that stamps Mobile Safari on every request.
///
/// Tokens are assembled on first [prepare]. No `appid/` or `appname/` tail.
class HttpPersona extends http.BaseClient {
  final http.Client _inner = http.Client();
  String? _cachedUa;

  Future<void> prepare() async {
    try {
      if (!Platform.isIOS) {
        _cachedUa = _fallbackUa();
        return;
      }
      final IosDeviceInfo info = await DeviceInfoPlugin().iosInfo;
      _cachedUa = _mobileSafari(_iosVersion(info.systemVersion));
    } catch (_) {
      _cachedUa = _fallbackUa();
    }
  }

  String get userAgent => _cachedUa ?? _fallbackUa();

  String _iosVersion(String raw) {
    final List<int> parts = raw
        .split('.')
        .map(int.tryParse)
        .whereType<int>()
        .take(3)
        .toList();
    if (parts.isEmpty || parts.first < 18) return '18.7';
    return parts.join('.');
  }

  String _mobileSafari(String iosVersion) {
    final String cpu = iosVersion.replaceAll('.', '_');
    return '${KineChart.uaProduct} ${KineChart.uaPlatformHead} $cpu '
        '${KineChart.uaPlatformTail} ${KineChart.uaEngine} Version/'
        '${KineChart.safariVersion} ${KineChart.uaMobileTag} Safari/'
        '${KineChart.safariBuild}';
  }

  String _fallbackUa() => _mobileSafari('18.7');

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => userAgent);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
