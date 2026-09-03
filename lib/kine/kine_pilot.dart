import 'dart:async';
import 'dart:io';

import 'cord/cfg_post.dart';
import 'cord/http_persona.dart';
import 'cord/origin_ink.dart';
import 'cord/reach_feel.dart';
import 'kine_chart.dart';
import 'veil/href_guard.dart';
import 'veil/kine_log.dart';
import 'veil/path_kinds.dart';
import 'vault/lane_chest.dart';
import 'vault/native_slot.dart';
import 'vault/push_hub.dart';

/// Boot router. Turns lane, reachability, native tap, attribution and
/// the config reply into one [SteerHint] for the splash.
class KinePilot {
  KinePilot({
    required this.locker,
    required this.scout,
    required this.trail,
    required this.dispatcher,
    required this.beacon,
    required this.agent,
    required this.runtimeEnabled,
  });

  final LaneChest locker;
  final ReachFeel scout;
  final OriginInk trail;
  final CfgPost dispatcher;
  final PushHub beacon;
  final HttpPersona agent;
  final bool runtimeEnabled;

  bool get enabled => runtimeEnabled && KineChart.pipelineReady;

  Future<SteerHint>? _pending;

  Future<SteerHint> decide({required void Function(double) onProgress}) {
    return _pending ??= _decide(
      onProgress: onProgress,
    ).whenComplete(() => _pending = null);
  }

  Future<SteerHint> _decide({
    required void Function(double) onProgress,
  }) async {
    if (!enabled) {
      kineLog(
        () =>
            '[KINE.PILOT] gate closed '
            'runtime=$runtimeEnabled creds=${KineChart.pipelineReady}',
      );
      onProgress(1);
      return const NestPath();
    }

    kineLog(() => '[KINE.PILOT] decide start lane=${locker.lane}');

    beacon.onTokenChanged = _refreshOnToken;

    final bool stackUp = await scout.hasInterface();

    final String? nativeTap = await NativeSlot.take();
    if (nativeTap != null) {
      kineLog(() => '[KINE.PILOT] native tap → $nativeTap');
      await locker.writeLane(PathKind.web);
      beacon.noteNativeTapConsumed();
      await locker.takeParkedUrl();
      if (!stackUp || !await scout.reachesNetwork()) {
        await locker.parkUrl(nativeTap);
        return const QuietPath(returnToHome: false);
      }
      unawaited(_warmInBackground());
      onProgress(1);
      return PanePath(nativeTap, coldLaunch: true);
    }

    // White lane never needs a network to open the game. Skip the probe
    // entirely when the radio is down so the splash does not sit there.
    if (locker.lane == PathKind.home && !stackUp) {
      onProgress(1);
      return const NestPath();
    }

    // Everyone else (first boot, returning web, push) with no stack goes
    // straight to the no-wifi surface — do not wait on DNS.
    if (locker.lane != PathKind.home && !stackUp) {
      kineLog(() => '[KINE.PILOT] no stack → quiet lane=${locker.lane}');
      return const QuietPath(returnToHome: false);
    }

    onProgress(0.12);

    return switch (locker.lane) {
      PathKind.unresolved => _firstBoot(onProgress),
      PathKind.web => _returningToWeb(onProgress),
      PathKind.home => _returningToHome(onProgress),
    };
  }

  Future<SteerHint> _firstBoot(void Function(double) progress) async {
    if (!await scout.reachesNetwork()) {
      kineLog(() => '[KINE.PILOT] first: offline → quiet');
      return const QuietPath(returnToHome: false);
    }
    progress(0.48);
    await trail.askTrackingConsent();
    await trail.awaitSignals();
    progress(0.72);
    final PilotReply reply = await _askConfig();
    progress(1);
    kineLog(
      () =>
          '[KINE.PILOT] first: config hasDest=${reply.hasDestination} '
          'url=${reply.url}',
    );
    if (reply.hasDestination) {
      await locker.writeLane(PathKind.web);
      return PanePath(reply.url!);
    }
    if (reply.transientFailure) {
      return const QuietPath(returnToHome: false);
    }
    await locker.writeLane(PathKind.home);
    return const NestPath();
  }

  Future<SteerHint> _returningToWeb(void Function(double) progress) async {
    if (!await scout.reachesNetwork()) {
      return const QuietPath(returnToHome: false);
    }

    final String? parked = await locker.takeParkedUrl();
    if (parked != null) {
      kineLog(() => '[KINE.PILOT] parked tap → $parked');
      progress(1);
      return PanePath(parked);
    }

    final String? cached = HrefGuard.sanitize(await locker.readCachedUrl());
    if (cached != null && !locker.cachedUrlStale) {
      progress(1);
      return PanePath(cached);
    }
    progress(0.62);
    await Future.wait<void>(<Future<void>>[beacon.ignite(), trail.start()]);
    await trail.awaitSignals(
      installTimeout: const Duration(milliseconds: 8200),
    );
    final PilotReply reply = await _askConfig();
    progress(1);
    if (reply.hasDestination) return PanePath(reply.url!);
    if (cached != null) return PanePath(cached);
    return const QuietPath(returnToHome: false);
  }

  Future<SteerHint> _returningToHome(void Function(double) progress) async {
    // Already classified white: the game does not need a network. Only
    // poke config when a real route exists, so a dead Wi-Fi association
    // cannot stall the splash.
    if (!await scout.hasInterface() || !await scout.reachesNetwork()) {
      progress(1);
      return const NestPath();
    }
    progress(0.55);
    await trail.awaitSignals();
    final PilotReply reply = await _askConfig();
    progress(1);
    if (!reply.hasDestination) return const NestPath();
    await locker.writeLane(PathKind.web);
    return PanePath(reply.url!);
  }

  Future<PilotReply> _askConfig({String? token}) async {
    final Map<String, dynamic> body = await trail.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: token ?? beacon.token,
    );
    return dispatcher.request(body);
  }

  Future<void> _warmInBackground() async {
    try {
      await Future.wait<void>(<Future<void>>[
        beacon.ignite(),
        trail.awaitSignals(),
      ]);
      await _askConfig();
    } catch (_) {}
  }

  Future<void> _refreshOnToken(String token) async {
    try {
      await _askConfig(token: token);
    } catch (_) {}
  }

  Future<void> igniteSignals() => beacon.ignite();

  Future<void> notePushToken(String token) => _refreshOnToken(token);
}
