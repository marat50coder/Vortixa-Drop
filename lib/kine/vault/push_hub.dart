import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../kine_chart.dart';
import '../veil/kine_log.dart';
import 'lane_chest.dart';

@pragma('vm:entry-point')
Future<void> kineBgPush(RemoteMessage _) async {}

/// FCM / APNs. Armed only after the boot path picks the WebView lane.
class PushHub {
  PushHub(this._chest);

  final LaneChest _chest;
  FirebaseMessaging? _messaging;
  Future<void>? _ignitionFuture;
  Future<void>? _bootFuture;
  Future<bool>? _permissionFuture;
  String? _token;
  bool _running = false;
  bool _launchTapConsumed = false;

  void Function(String token)? onTokenChanged;
  void Function(String url)? onDestination;

  String? get token => _token;
  bool get running => _running;

  void noteNativeTapConsumed() => _launchTapConsumed = true;

  Future<void> ignite() => _ignitionFuture ??= _ignite();

  Future<void> _ignite() async {
    if (!KineChart.pipelineReady) return;
    try {
      await Firebase.initializeApp();
      try {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (error) {
        kineLog(() => '[KINE.HUB] AppCheck skipped: $error');
      }
      _running = true;
      await _boot();
    } catch (error) {
      kineLog(() => '[KINE.HUB] ignite failed: $error');
    }
  }

  Future<void> _boot() => _bootFuture ??= _bootOnce();

  Future<void> _bootOnce() async {
    if (!_running) return;
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    _messaging = messaging;

    FirebaseMessaging.onMessageOpenedApp.listen(_onTapWhileForeground);

    if (!_launchTapConsumed) {
      final RemoteMessage? initial = await messaging
          .getInitialMessage()
          .timeout(const Duration(milliseconds: 5200), onTimeout: () => null);
      final String? launch = initial == null ? null : _pickUrl(initial.data);
      if (launch != null) await _chest.parkUrl(launch);
    }

    FirebaseMessaging.onBackgroundMessage(kineBgPush);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    messaging.onTokenRefresh.listen((String value) {
      _token = value;
      onTokenChanged?.call(value);
    });
    await _pollForApns();
    _token = await messaging.getToken();
  }

  void _onTapWhileForeground(RemoteMessage message) {
    final String? url = _pickUrl(message.data);
    if (url == null) return;
    final void Function(String url)? live = onDestination;
    if (live == null) {
      kineLog(() => '[KINE.HUB] tap parked $url');
      unawaited(_chest.parkUrl(url));
      return;
    }
    kineLog(() => '[KINE.HUB] tap live $url');
    live(url);
  }

  String? _pickUrl(Map<String, dynamic> payload) {
    const List<String> flat = <String>[
      'deep_link',
      'target',
      'url',
      'deeplink',
      'link',
    ];
    for (final String key in flat) {
      final Object? value = payload[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    for (final String container in const <String>['payload', 'data']) {
      final Object? nested = payload[container];
      if (nested is Map) {
        final String? found = _pickUrl(Map<String, dynamic>.from(nested));
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> _pollForApns({int attempts = 12}) async {
    final FirebaseMessaging? messaging = _messaging;
    if (messaging == null) return;
    for (int i = 0; i < attempts; i++) {
      try {
        final String? apns = await messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) return;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 430));
    }
  }

  Future<bool> canOfferInvite() async {
    if (!_running || _chest.pushRefusedByOs) return false;
    final FirebaseMessaging? messaging = _messaging;
    if (messaging == null) return false;
    final AuthorizationStatus status =
        (await messaging.getNotificationSettings()).authorizationStatus;
    if (status == AuthorizationStatus.denied) {
      await _chest.markPushRefusedByOs();
      return false;
    }
    return status == AuthorizationStatus.notDetermined ||
        status == AuthorizationStatus.provisional;
  }

  Future<bool> requestPermission() {
    return _permissionFuture ??= _requestPermissionOnce().whenComplete(
      () => _permissionFuture = null,
    );
  }

  Future<bool> _requestPermissionOnce() async {
    if (!_running || _messaging == null) return false;
    final NotificationSettings result = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final bool ok =
        result.authorizationStatus == AuthorizationStatus.authorized ||
        result.authorizationStatus == AuthorizationStatus.provisional;
    await _chest.writePushGranted(ok);
    if (!ok && result.authorizationStatus == AuthorizationStatus.denied) {
      await _chest.markPushRefusedByOs();
    }
    if (ok) {
      await _pollForApns(attempts: 18);
      _token = await _messaging!.getToken();
      final String? fresh = _token;
      if (fresh != null && fresh.isNotEmpty) onTokenChanged?.call(fresh);
    }
    return ok;
  }
}
