import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/orientation.dart';
import '../data/app_store.dart';
import '../kine/kine_pilot.dart';
import '../kine/panes/bell_ask.dart';
import '../kine/panes/void_page.dart';
import '../kine/panes/web_chamber.dart';
import '../kine/veil/path_kinds.dart';
import '../widgets/horizontal_progress_bar.dart';
import '../widgets/loading_dots_text.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, this.helm});

  final KinePilot? helm;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  /// Cruise toward ~85% while boot work is still running.
  static const int _cruiseMs = 7000;
  static const double _cruiseTo = 0.85;

  /// Last slice to 100% — only after work is done, right before handover.
  static const int _minFinishMs = 420;
  static const int _maxFinishMs = 880;

  late final Ticker _ticker;
  final Stopwatch _clock = Stopwatch();

  double _shown = 0;
  bool _handedOver = false;
  int? _finishOriginMs;
  double? _finishFrom;

  SteerHint _decision = const NestPath();
  bool _routerDone = false;
  bool _storeReady = false;

  @override
  void initState() {
    super.initState();
    VxOrientation.allowAny();
    _clock.start();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preflightQuiet();
      _runRouter();
      _loadStore();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _preflightQuiet() async {
    final KinePilot? helm = widget.helm;
    if (helm == null || !helm.enabled) return;
    if (helm.locker.lane == PathKind.home) return;
    bool stackUp = true;
    try {
      stackUp = await helm.scout.hasInterface();
    } catch (_) {
      stackUp = false;
    }
    if (stackUp || !mounted || _handedOver) return;
    _decision = const QuietPath(returnToHome: false);
    _routerDone = true;
    _jumpOffline();
  }

  Future<void> _runRouter() async {
    final KinePilot? helm = widget.helm;
    if (helm == null || !helm.enabled) {
      _decision = const NestPath();
      _routerDone = true;
      return;
    }
    try {
      _decision = await helm.decide(onProgress: (_) {});
    } catch (_) {
      _decision = helm.locker.lane == PathKind.home
          ? const NestPath()
          : const QuietPath(returnToHome: false);
    }
    if (!mounted || _handedOver) return;
    _routerDone = true;
    if (_decision is QuietPath) {
      _jumpOffline();
    }
  }

  Future<void> _loadStore() async {
    try {
      await context.read<AppStore>().load();
    } catch (_) {}
    if (!mounted) return;
    _storeReady = true;
  }

  bool get _workDone {
    if (!_routerDone) return false;
    if (_decision is QuietPath) return true;
    if (_decision is PanePath) return true;
    return _storeReady;
  }

  void _onTick(Duration _) {
    if (_handedOver) return;

    if (_routerDone && _decision is QuietPath) {
      _jumpOffline();
      return;
    }

    // Nowifi jumps immediately — do not keep filling the splash bar.
    if (_decision is QuietPath) return;

    final double target = _displayTarget();
    setState(() => _shown = target);

    if (_workDone && _shown >= 0.995) {
      setState(() => _shown = 1);
      if (_handedOver) return;
      _handedOver = true;
      _ticker.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_goToApp());
      });
    }
  }

  int _finishDurationMs(double from) {
    final double remain = (1.0 - from).clamp(0.0, 1.0);
    return (_minFinishMs + remain * (_maxFinishMs - _minFinishMs)).round();
  }

  double _displayTarget() {
    if (!_workDone) {
      final double t = (_clock.elapsedMilliseconds / _cruiseMs).clamp(0.0, 1.0);
      return _cruiseTo * Curves.easeOutCubic.transform(t);
    }
    _finishFrom ??= _shown;
    _finishOriginMs ??= _clock.elapsedMilliseconds;
    final int finishMs = _finishDurationMs(_finishFrom!);
    final double t =
        ((_clock.elapsedMilliseconds - _finishOriginMs!) / finishMs).clamp(
          0.0,
          1.0,
        );
    return _finishFrom! + (1.0 - _finishFrom!) * Curves.easeOutCubic.transform(t);
  }

  void _jumpOffline() {
    if (_handedOver) return;
    _handedOver = true;
    _ticker.stop();
    unawaited(_goToApp());
  }

  Future<void> _goToApp() async {
    if (!mounted) return;
    final SteerHint decision = _decision;
    final KinePilot? helm = widget.helm;

    if (decision is QuietPath && helm != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VoidPage(
            scout: helm.scout,
            retryBuilder: (_) => LoadingScreen(helm: helm),
          ),
        ),
      );
      return;
    }

    if (decision is PanePath && helm != null) {
      await helm.igniteSignals();
      if (!mounted) return;

      Widget openPortal(BuildContext _) => WebChamber(
        url: decision.url,
        coldLaunch: decision.coldLaunch,
        locker: helm.locker,
        beacon: helm.beacon,
        scout: helm.scout,
        agent: helm.agent,
      );

      if (helm.locker.inviteAllowed &&
          await helm.beacon.canOfferInvite()) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => BellAsk(
              locker: helm.locker,
              beacon: helm.beacon,
              nextBuilder: openPortal,
              onTokenReady: helm.notePushToken,
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: openPortal));
      return;
    }

    if (!_storeReady) {
      try {
        await context.read<AppStore>().load();
      } catch (_) {}
    }
    if (!mounted) return;
    await _warmWhiteAssets();
    if (!mounted) return;

    final AppStore store = context.read<AppStore>();
    await VxOrientation.lockPortrait();
    if (!mounted) return;
    final Widget next = store.settings.onboardingComplete
        ? const HomeShell()
        : const OnboardingScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, Animation<double> a, _, Widget child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  Future<void> _warmWhiteAssets() async {
    final List<String> images = <String>[
      AppAssets.dropChamber,
      AppAssets.vortexCore,
      AppAssets.vortexFunnel,
      ...AppAssets.balls,
    ];
    for (final String path in images) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            landscape
                ? AppAssets.horizontalLoading
                : AppAssets.verticalLoading,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                landscape ? 64 : 28,
                36,
                landscape ? 64 : 28,
                landscape ? 22 : 36,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Color(0xCC000000)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset(
                      AppAssets.gameName,
                      height: landscape ? 64 : 88,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    SizedBox(height: landscape ? 10 : 14),
                    HorizontalProgressBar(progress: _shown),
                    const SizedBox(height: 14),
                    const LoadingDotsText(
                      style: TextStyle(
                        color: VxColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
