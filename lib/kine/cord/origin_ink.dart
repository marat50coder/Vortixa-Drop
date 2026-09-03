import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../kine_chart.dart';
import '../veil/kine_log.dart';
import 'http_persona.dart';

/// Attribution collector: AppsFlyer, ATT, conversion / reopen / deep-link,
/// then the map posted to the config host.
class OriginInk {
  OriginInk(this._persona);

  final HttpPersona _persona;
  AppsflyerSdk? _sdk;

  Map<String, dynamic>? _install;
  Map<String, dynamic>? _reopen;
  Map<String, dynamic>? _deepLink;

  Future<void>? _startFuture;
  Future<void>? _consentFuture;
  final Completer<void> _installReady = Completer<void>();
  final Completer<void> _deepLinkReady = Completer<void>();

  Future<void> start() => _startFuture ??= _start();

  Future<void> askTrackingConsent() {
    final Future<void>? inFlight = _consentFuture;
    if (inFlight != null) return inFlight;
    final Future<void> started = _askTrackingConsent();
    _consentFuture = started;
    return started;
  }

  Future<void> _start() async {
    if (!KineChart.pipelineReady) {
      _releaseWaiters();
      return;
    }
    try {
      await askTrackingConsent();
      final AppsflyerSdk sdk = AppsflyerSdk(
        AppsFlyerOptions(
          afDevKey: KineChart.appsFlyerKey,
          appId: KineChart.iosStoreId,
          showDebug: kDebugMode,
          timeToWaitForATTUserAuthorization: 9,
        ),
      );
      _sdk = sdk;
      sdk.onInstallConversionData(_onConversion);
      sdk.onAppOpenAttribution((dynamic raw) => _reopen = _asMap(raw));
      sdk.onDeepLinking((DeepLinkResult r) {
        final Map<String, dynamic>? click = r.deepLink?.clickEvent;
        if (click != null) _deepLink = Map<String, dynamic>.from(click);
        if (!_deepLinkReady.isCompleted) _deepLinkReady.complete();
      });
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (error) {
      kineLog(() => '[KINE.INK] start failed: $error');
      _releaseWaiters();
    }
  }

  Future<void> _askTrackingConsent() async {
    if (!Platform.isIOS) return;
    try {
      TrackingStatus status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status != TrackingStatus.notDetermined) return;
      await _awaitFrontmost();
      status = await AppTrackingTransparency.requestTrackingAuthorization();
      if (status == TrackingStatus.notDetermined) {
        await _awaitFrontmost();
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }
      if (status == TrackingStatus.notDetermined) _consentFuture = null;
    } catch (_) {
      _consentFuture = null;
    }
  }

  Future<void> _awaitFrontmost() async {
    await WidgetsBinding.instance.endOfFrame;
    for (int i = 0; i < 22; i++) {
      final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) {
        await Future<void>.delayed(const Duration(milliseconds: 210));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 115));
    }
  }

  Future<void> _onConversion(dynamic raw) async {
    try {
      final Map<String, dynamic> body = _asMap(raw);
      final String? status = body['status']?.toString().toLowerCase();
      final bool failed =
          status == 'failure' ||
          (body['af_status'] == null && body.containsKey('status'));
      kineLog(
        () =>
            '[KINE.INK] conversion status=$status '
            'af_status=${body['af_status']} keys=${body.keys.toList()}',
      );
      if (failed) {
        _install = <String, dynamic>{};
      } else if (body['af_status'] == 'Organic') {
        await Future<void>.delayed(
          const Duration(seconds: KineChart.organicRecheckSeconds),
        );
        final Map<String, dynamic>? gcd = await _fetchGcd();
        if (gcd == null) {
          _install = body;
        } else {
          final Map<String, dynamic> merged = <String, dynamic>{
            ...body,
            ...gcd,
          };
          merged.putIfAbsent('af_status', () => body['af_status']);
          _install = merged;
        }
      } else {
        _install = body;
      }
    } catch (error) {
      kineLog(() => '[KINE.INK] conversion parse failed: $error');
      _install = <String, dynamic>{};
    } finally {
      if (!_installReady.isCompleted) _installReady.complete();
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    final Object? payload = map['payload'];
    return payload is Map ? Map<String, dynamic>.from(payload) : map;
  }

  Future<Map<String, dynamic>?> _fetchGcd() async {
    final String? uid = await appsFlyerUid();
    if (uid == null || uid.isEmpty) return null;
    try {
      final String base = KineChart.gcdBase.endsWith('/')
          ? KineChart.gcdBase
          : '${KineChart.gcdBase}/';
      final Uri uri = Uri.parse(
        '${base}id${KineChart.iosStoreId}?device_id=$uid',
      );
      final response = await _persona
          .get(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer ${KineChart.appsFlyerKey}',
            },
          )
          .timeout(const Duration(milliseconds: 15400));
      if (response.statusCode != 200) return null;
      final Object? decoded = jsonDecode(response.body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> awaitSignals({
    Duration installTimeout = const Duration(milliseconds: 10600),
  }) async {
    await start();
    await Future.wait<void>(<Future<void>>[
      _installReady.future.timeout(installTimeout, onTimeout: () {}),
      _deepLinkReady.future.timeout(
        const Duration(milliseconds: 7400),
        onTimeout: () {},
      ),
    ]);
  }

  Future<String?> appsFlyerUid() async {
    try {
      return await _sdk?.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> compose({
    required String locale,
    String? pushToken,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (_install != null) body.addAll(_install!);
    _reopen?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));
    _deepLink?.forEach((String k, dynamic v) => body.putIfAbsent(k, () => v));

    body['af_id'] = await appsFlyerUid() ?? body['af_id'] ?? '';
    body['bundle_id'] = KineChart.bundleId;
    body['os'] = 'iOS';
    body['store_id'] = KineChart.storeToken;
    body['locale'] = locale;

    if (pushToken != null &&
        pushToken.isNotEmpty &&
        KineChart.firebaseProjectNumber.isNotEmpty) {
      body['push_token'] = pushToken;
      body['firebase_project_id'] = KineChart.firebaseProjectNumber;
    }

    if (Platform.isIOS) {
      try {
        final TrackingStatus status =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.authorized) {
          final String idfa =
              await AppTrackingTransparency.getAdvertisingIdentifier();
          if (idfa.isNotEmpty && !idfa.startsWith('00000000-')) {
            body['sub_id_10'] = idfa;
          }
        }
      } catch (_) {}
    }
    kineLog(() => '[KINE.INK] payload ${jsonEncode(body)}');
    return body;
  }

  void _releaseWaiters() {
    if (!_installReady.isCompleted) _installReady.complete();
    if (!_deepLinkReady.isCompleted) _deepLinkReady.complete();
  }
}
