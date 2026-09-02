import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../widgets/neon_ball.dart';
import '../widgets/neon_button.dart';
import 'result_screen.dart';

enum _Phase { falling, orbiting, winding, flash, reveal, presenting, celebrating }

class _Orb {
  _Orb({
    required this.option,
    required this.pos,
    required this.vel,
    required this.orbitAngle,
    this.enterDelay = 0,
  });

  final ChoiceOption option;
  Offset pos;
  Offset vel;
  double opacity = 1;
  double spin = 0;
  double scale = 1;
  double orbitAngle;
  double enterDelay;
  double enterT = 0;
  bool seated = false;
  int? rank;
  int? groupIndex;
  Offset? presentTarget;
  double presentScale = 1;
}

class _Confetti {
  _Confetti(this.pos, this.vel, this.color, this.rotation, this.spinSpeed);
  Offset pos;
  Offset vel;
  double rotation;
  final double spinSpeed;
  final Color color;
  double life = 1;
}

class _Shockwave {
  _Shockwave(this.center, this.color);
  final Offset center;
  final Color color;
  double life = 1;
}

class DropSceneScreen extends StatefulWidget {
  const DropSceneScreen({
    super.key,
    required this.session,
    this.charge = 0,
  });

  final DropSession session;
  final double charge;

  @override
  State<DropSceneScreen> createState() => _DropSceneScreenState();
}

class _DropSceneScreenState extends State<DropSceneScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Orb> _orbs = [];
  final List<_Confetti> _confetti = [];
  final List<_Shockwave> _shockwaves = [];
  final math.Random _rng = math.Random();
  Size _size = Size.zero;
  Offset _ringCenter = Offset.zero;
  double _ringRadius = 0;
  double _ringSpin = 0;
  double _ringSpinSpeed = 0.4;
  double _radiusScale = 1.0;
  double _flashPulse = 0;
  Duration _last = Duration.zero;
  Duration _elapsed = Duration.zero;
  _Phase _phase = _Phase.falling;
  bool _finished = false;
  double _orbitStartAt = 0;
  double _windStartAt = 0;
  double _flashAt = 0;
  double _revealAt = 0;
  double _celebrateAt = 0;
  late final bool _animated;
  final List<_Orb> _losers = [];
  final List<_Orb> _keepers = [];

  double get _speed => 1 + widget.charge * 0.4;
  bool get _isSplit => widget.session.mode == DropMode.split;

  @override
  void initState() {
    super.initState();
    _animated = context.read<AppStore>().settings.animations;
    AudioService.instance.play(AppAssets.soundDropStart);
    AudioService.instance.startLoop(AppAssets.soundVortex);
    HapticsService.instance.impact();
    _ticker = createTicker(_onTick)..start();
  }

  Set<String> get _keepIds {
    if (_isSplit) {
      return widget.session.options.map((o) => o.id).toSet();
    }
    return widget.session.winners.map((o) => o.id).toSet();
  }

  void _spawn(Size size) {
    if (_orbs.isNotEmpty) return;
    final options = widget.session.options;
    final n = options.length;

    _ringCenter = Offset(size.width / 2, size.height * 0.48);
    _ringRadius = math.min(size.width, size.height) *
        (n <= 3 ? 0.22 : n <= 5 ? 0.26 : 0.30);

    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final start = _ringCenter +
          Offset(math.cos(angle), math.sin(angle)) * _ringRadius * 1.42;
      _orbs.add(
        _Orb(
          option: options[i],
          pos: start,
          vel: Offset.zero,
          orbitAngle: angle,
          enterDelay: i * 0.09,
        )..opacity = 0
          ..scale = 0.28,
      );
    }

    if (_isSplit) {
      for (var g = 0; g < widget.session.groups.length; g++) {
        final ids = widget.session.groups[g].map((o) => o.id).toSet();
        for (final orb in _orbs) {
          if (ids.contains(orb.option.id)) orb.groupIndex = g;
        }
      }
      _keepers
        ..clear()
        ..addAll(_orbs);
      _assignSplitTargets(size);
    } else {
      final keep = _keepIds;
      _losers
        ..clear()
        ..addAll(_orbs.where((o) => !keep.contains(o.option.id)));
      _keepers
        ..clear()
        ..addAll(_orbs.where((o) => keep.contains(o.option.id)));
      for (var i = 0; i < widget.session.winners.length; i++) {
        final id = widget.session.winners[i].id;
        for (final orb in _keepers) {
          if (orb.option.id == id) orb.rank = i + 1;
        }
      }
      _keepers.sort((a, b) => (a.rank ?? 99).compareTo(b.rank ?? 99));
    }
  }

  void _onTick(Duration elapsed) {
    if (_size == Size.zero) return;
    final dt = _last == Duration.zero
        ? 0.016
        : ((elapsed - _last).inMicroseconds / 1000000).clamp(0.0, 0.033);
    _last = elapsed;
    _elapsed = elapsed;

    if (!_animated) {
      _reveal();
      return;
    }

    _step(dt);
    _stepEffects(dt);
    if (mounted) setState(() {});
  }

  void _step(double dt) {
    final ms = _elapsed.inMilliseconds;
    final now = ms / 1000;

    if (_isSplit) {
      _stepSplit(dt, ms, now);
      return;
    }

    // Phase transitions ---------------------------------------------------
    final enterWindow = (_orbs.isEmpty ? 0.0 : (_orbs.length - 1) * 0.09) + 0.62;
    if (_phase == _Phase.falling && now >= enterWindow + 0.16) {
      _phase = _Phase.orbiting;
      _orbitStartAt = now;
      HapticsService.instance.tap();
    }
    if (_phase == _Phase.orbiting && now - _orbitStartAt >= 1.15) {
      _phase = _Phase.winding;
      _windStartAt = now;
    }
    if (_phase == _Phase.winding && now - _windStartAt >= 0.75) {
      _enterFlash(now);
    }
    if (_phase == _Phase.flash && now - _flashAt >= 0.22) {
      _phase = _Phase.reveal;
      _revealAt = now;
    }
    final revealDuration = 0.55 +
        math.max(0, _keepers.length - 1).toDouble() * 0.15;
    if (_phase == _Phase.reveal && now - _revealAt >= revealDuration) {
      _phase = _Phase.celebrating;
      _celebrateAt = now;
    }
    if (_phase == _Phase.celebrating && now - _celebrateAt >= 1.5) {
      _reveal();
    }

    // Ring motion ---------------------------------------------------------
    final targetSpinSpeed = switch (_phase) {
      _Phase.falling => 0.5 * _speed,
      _Phase.orbiting => _lerp(
          0.7,
          3.2,
          ((now - _orbitStartAt) / 1.15).clamp(0.0, 1.0),
        ),
      _Phase.winding => _lerp(
          3.5,
          9.5,
          ((now - _windStartAt) / 0.75).clamp(0.0, 1.0),
        ),
      _Phase.flash ||
      _Phase.reveal ||
      _Phase.presenting ||
      _Phase.celebrating =>
        0.0,
    };
    _ringSpinSpeed += (targetSpinSpeed - _ringSpinSpeed) * 5 * dt;
    _ringSpin += _ringSpinSpeed * dt;

    final targetRadius = switch (_phase) {
      _Phase.falling => 1.0,
      _Phase.orbiting => 1.0,
      _Phase.winding => math.max(
          0.10,
          1.0 - ((now - _windStartAt) / 0.75).clamp(0.0, 1.0) * 0.95,
        ),
      _Phase.flash ||
      _Phase.reveal ||
      _Phase.presenting ||
      _Phase.celebrating =>
        0.0,
    };
    _radiusScale += (targetRadius - _radiusScale) * 6 * dt;

    // Orb updates ---------------------------------------------------------
    for (final orb in _orbs) {
      final isLoser = _losers.contains(orb);
      final winnerIdx = isLoser ? -1 : _keepers.indexOf(orb);

      switch (_phase) {
        case _Phase.falling:
          _glideOntoOrbit(orb, now, dt);
        case _Phase.orbiting:
        case _Phase.winding:
          final target = _slotFor(orb);
          orb.pos = Offset(
            orb.pos.dx + (target.dx - orb.pos.dx) * 14 * dt,
            orb.pos.dy + (target.dy - orb.pos.dy) * 14 * dt,
          );
          orb.spin += _ringSpinSpeed * 0.6 * dt;
        case _Phase.flash:
          if (isLoser) {
            orb.opacity = 0;
          } else {
            orb.opacity = 0;
            orb.pos = _ringCenter;
            orb.scale = 0.1;
          }
        case _Phase.presenting:
          // unused in non-split flow
          break;
        case _Phase.reveal:
        case _Phase.celebrating:
          if (isLoser) {
            orb.opacity = 0;
            continue;
          }
          final delay = winnerIdx * 0.15;
          final t =
              ((now - _revealAt) - delay).clamp(0.0, 1.5) / 0.55;
          final k = t.clamp(0.0, 1.0);
          final easeOut = 1 - math.pow(1 - k, 3);
          // slight overshoot for bounce
          final overshoot = k < 1
              ? _easeOutBack(k)
              : 1.0 + math.sin((now - _revealAt - delay) * 5) * 0.02;
          final target = orb.presentTarget ?? _ringCenter;
          orb.pos = Offset(
            _ringCenter.dx + (target.dx - _ringCenter.dx) * easeOut,
            _ringCenter.dy + (target.dy - _ringCenter.dy) * easeOut,
          );
          orb.scale = 0.1 + (orb.presentScale - 0.1) * overshoot;
          orb.opacity = k.clamp(0.0, 1.0);
          orb.spin += 1.2 * dt;
          if (_phase == _Phase.celebrating) {
            final bob = math.sin(now * 2.6 + winnerIdx) * 2.4;
            orb.pos = Offset(orb.pos.dx, orb.pos.dy + bob * dt * 8);
          }
      }
    }

    _flashPulse = (_flashPulse - dt * 4.5).clamp(0.0, 1.0);
  }

  void _enterFlash(double now) {
    _phase = _Phase.flash;
    _flashAt = now;
    _flashPulse = 1;
    _assignPresentTargets(_size);
    _shockwaves.add(_Shockwave(
      _ringCenter,
      _keepers.isEmpty
          ? VxColors.cyan
          : VxColors.ballTints[
              _keepers.first.option.colorIndex % VxColors.ballTints.length],
    ));
    _burstConfetti(_size);
    AudioService.instance.play(AppAssets.soundResult);
    HapticsService.instance.result();
  }

  void _stepSplit(double dt, int _, double now) {
    final enterWindow = (_orbs.isEmpty ? 0.0 : (_orbs.length - 1) * 0.09) + 0.62;
    if (_phase == _Phase.falling && now >= enterWindow + 0.16) {
      _phase = _Phase.orbiting;
      _orbitStartAt = now;
      HapticsService.instance.tap();
    }
    if (_phase == _Phase.orbiting && now - _orbitStartAt >= 0.85) {
      _phase = _Phase.presenting;
      _revealAt = now;
    }
    final draftDone = 0.28 + _orbs.length * 0.18;
    if (_phase == _Phase.presenting && now - _revealAt >= draftDone) {
      _phase = _Phase.celebrating;
      _celebrateAt = now;
      _shockwaves.add(_Shockwave(
        Offset(_size.width / 2, _size.height * 0.22),
        VxColors.cyan,
      ));
      _burstConfetti(_size);
      AudioService.instance.play(AppAssets.soundResult);
      HapticsService.instance.result();
    }
    if (_phase == _Phase.celebrating && now - _celebrateAt >= 1.5) {
      _reveal();
    }

    final targetSpin = switch (_phase) {
      _Phase.falling => 0.45,
      _Phase.orbiting => 2.4,
      _ => 0.0,
    };
    _ringSpinSpeed += (targetSpin - _ringSpinSpeed) * 5 * dt;
    _ringSpin += _ringSpinSpeed * dt;

    for (var i = 0; i < _orbs.length; i++) {
      final orb = _orbs[i];
      if (_phase == _Phase.falling) {
        _glideOntoOrbit(orb, now, dt);
        continue;
      }
      if (_phase == _Phase.orbiting) {
        final target = _slotFor(orb);
        orb.pos = Offset(
          orb.pos.dx + (target.dx - orb.pos.dx) * 14 * dt,
          orb.pos.dy + (target.dy - orb.pos.dy) * 14 * dt,
        );
        orb.spin += _ringSpinSpeed * 0.6 * dt;
        orb.scale += (1.0 - orb.scale) * 8 * dt;
        orb.opacity = 1;
        continue;
      }

      final delay = i * 0.18;
      final k = ((now - _revealAt - delay) / 0.42).clamp(0.0, 1.0);
      final ease = 1 - math.pow(1 - k, 3).toDouble();
      final lane = orb.presentTarget ?? _ringCenter;
      final from = _slotFor(orb);
      if (k <= 0) {
        orb.pos = from;
      } else {
        orb.pos = Offset(
          from.dx + (lane.dx - from.dx) * ease,
          from.dy + (lane.dy - from.dy) * ease,
        );
      }
      orb.scale += (1.0 - orb.scale) * 6 * dt;
      orb.opacity = 1;
    }
  }

  void _glideOntoOrbit(_Orb orb, double now, double dt) {
    final t = ((now - orb.enterDelay) / 0.58).clamp(0.0, 1.0);
    orb.enterT = t;
    final ease = 1 - math.pow(1 - t, 3).toDouble();
    final pop = _easeOutBack(t);
    final a = orb.orbitAngle + _ringSpin;
    final r = _ringRadius * (1.42 - 0.42 * ease) * _radiusScale;
    orb.pos = _ringCenter + Offset(math.cos(a), math.sin(a)) * r;
    orb.opacity = ease;
    orb.scale = 0.28 + 0.72 * pop;
    orb.spin += (0.4 + 1.8 * ease) * dt;
    if (!orb.seated && t >= 1) {
      orb.seated = true;
      HapticsService.instance.tap();
    }
  }

  Offset _slotFor(_Orb orb) {
    final a = orb.orbitAngle + _ringSpin;
    return _ringCenter +
        Offset(math.cos(a), math.sin(a)) * _ringRadius * _radiusScale;
  }

  void _assignPresentTargets(Size size) {
    final k = _keepers.length;
    final center = _ringCenter;
    if (k == 1) {
      _keepers[0].presentTarget = center;
      _keepers[0].presentScale = 1.55;
      return;
    }
    for (var i = 0; i < k; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / k;
      _keepers[i].presentTarget =
          center + Offset(math.cos(angle), math.sin(angle)) * _ringRadius;
      _keepers[i].presentScale = i == 0 ? 1.35 : (i == 1 ? 1.10 : 1.0);
    }
  }

  void _assignSplitTargets(Size size) {
    final groups = widget.session.groups;
    final laneW = size.width / groups.length;
    for (var g = 0; g < groups.length; g++) {
      final ids = groups[g].map((o) => o.id).toList();
      final gx = laneW * (g + 0.5);
      for (var i = 0; i < ids.length; i++) {
        final orb = _orbs.firstWhere((o) => o.option.id == ids[i]);
        final ty = size.height * 0.24 + i * (kBallSize + 30);
        orb.presentTarget = Offset(gx, ty);
        orb.presentScale = 1.0;
      }
    }
  }

  void _burstConfetti(Size size) {
    final center = _isSplit
        ? Offset(size.width / 2, size.height * 0.30)
        : _ringCenter;
    final palette = <Color>[
      VxColors.cyan,
      VxColors.magenta,
      VxColors.violet,
      VxColors.lime,
      VxColors.orange,
      VxColors.turquoise,
      Colors.white,
    ];
    for (var i = 0; i < 90; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 280 + _rng.nextDouble() * 280;
      _confetti.add(
        _Confetti(
          center,
          Offset(math.cos(angle) * speed, math.sin(angle) * speed * 0.85),
          palette[_rng.nextInt(palette.length)],
          _rng.nextDouble() * math.pi,
          (_rng.nextDouble() - 0.5) * 8,
        ),
      );
    }
  }

  void _stepEffects(double dt) {
    if (_confetti.isNotEmpty) {
      for (final c in _confetti) {
        c.vel = Offset(c.vel.dx * 0.985, c.vel.dy + 460 * dt);
        c.pos += c.vel * dt;
        c.rotation += c.spinSpeed * dt;
        c.life = (c.life - dt * 0.6).clamp(0.0, 1.0);
      }
      _confetti.removeWhere((c) => c.life <= 0.02);
    }
    if (_shockwaves.isNotEmpty) {
      for (final s in _shockwaves) {
        s.life = (s.life - dt * 1.4).clamp(0.0, 1.0);
      }
      _shockwaves.removeWhere((s) => s.life <= 0.02);
    }
  }

  Future<void> _reveal() async {
    if (_finished) return;
    _finished = true;
    _ticker.stop();
    await AudioService.instance.stopLoop();
    if (!mounted) return;
    await context.read<AppStore>().recordHistory(widget.session);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => ResultScreen(session: widget.session),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _stop() {
    if (_finished) return;
    _reveal();
  }

  String get _bannerText {
    final session = widget.session;
    if (_isSplit) {
      if (_phase == _Phase.falling) return 'Loading orbits…';
      if (_phase == _Phase.orbiting) return 'Drafting lanes…';
      if (_phase == _Phase.presenting) return 'Dealing into groups';
      return 'Groups ready';
    }
    switch (_phase) {
      case _Phase.falling:
        return 'Loading orbits…';
      case _Phase.orbiting:
        return 'Vortixa locking';
      case _Phase.winding:
        return 'Winding vortex…';
      case _Phase.flash:
        return '⋯';
      case _Phase.presenting:
      case _Phase.reveal:
      case _Phase.celebrating:
        if (session.winners.length == 1) {
          return 'Chosen · ${session.winners.first.label}';
        }
        return 'Top ${session.winners.length}';
    }
  }

  bool get _showSpotlight =>
      !_isSplit &&
      widget.session.winners.length == 1 &&
      (_phase == _Phase.reveal || _phase == _Phase.celebrating);

  Offset get _spotlightCenter =>
      _keepers.isEmpty ? _ringCenter : (_keepers.first.presentTarget ?? _ringCenter);

  @override
  void dispose() {
    AudioService.instance.stopLoop();
    _ticker.dispose();
    super.dispose();
  }

  double get _revealProgressFor {
    if (_keepers.isEmpty || _phase != _Phase.reveal) return 0;
    final now = _elapsed.inMilliseconds / 1000;
    return ((now - _revealAt) / 0.55).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          _spawn(_size);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AppAssets.vortexCore,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              CustomPaint(
                painter: _DialPainter(
                  center: _ringCenter,
                  radius: _ringRadius,
                  spin: _ringSpin,
                  speed: _ringSpinSpeed,
                  intensity: _phase == _Phase.orbiting ||
                          _phase == _Phase.winding
                      ? 1
                      : 0.4,
                ),
              ),
              if (_isSplit &&
                  (_phase == _Phase.presenting ||
                      _phase == _Phase.celebrating))
                CustomPaint(painter: _LanePainter(session: widget.session)),
              if (_phase == _Phase.orbiting || _phase == _Phase.winding)
                CustomPaint(
                  painter: _TrailPainter(
                    orbs: _orbs,
                    losers: _losers.toSet(),
                    center: _ringCenter,
                    baseRadius: _ringRadius,
                    radiusScale: _radiusScale,
                    ringSpin: _ringSpin,
                    ringSpinSpeed: _ringSpinSpeed,
                  ),
                ),
              if (_showSpotlight)
                CustomPaint(
                  painter: _SpotlightPainter(
                    center: _spotlightCenter,
                    spin: _elapsed.inMilliseconds / 1000,
                    intensity:
                        _phase == _Phase.celebrating ? 1.0 : _revealProgressFor,
                    tint: _keepers.isEmpty
                        ? VxColors.cyan
                        : VxColors.ballTints[
                            _keepers.first.option.colorIndex %
                                VxColors.ballTints.length],
                  ),
                ),
              CustomPaint(
                painter: _ShockwavePainter(_shockwaves),
              ),
              if (_flashPulse > 0.05)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FlashPainter(
                      center: _ringCenter,
                      intensity: _flashPulse,
                      tint: _keepers.isEmpty
                          ? Colors.white
                          : VxColors.ballTints[
                              _keepers.first.option.colorIndex %
                                  VxColors.ballTints.length],
                    ),
                  ),
                ),
              if (_phase == _Phase.reveal || _phase == _Phase.celebrating)
                const ColoredBox(color: Color(0x55000000)),
              // Streak trails for winners travelling from center to slots (Multi)
              if ((_phase == _Phase.reveal) &&
                  !_isSplit &&
                  _keepers.length > 1)
                CustomPaint(
                  painter: _StreakPainter(
                    center: _ringCenter,
                    keepers: _keepers,
                  ),
                ),
              ..._orbs.map(_orbWidget),
              if (_isSplit &&
                  (_phase == _Phase.presenting ||
                      _phase == _Phase.celebrating))
                ..._splitHeaders(),
              if (_phase == _Phase.celebrating &&
                  !_isSplit &&
                  widget.session.winners.length == 1)
                _WinnerCard(
                  center: _spotlightCenter,
                  winner: widget.session.winners.first,
                ),
              CustomPaint(painter: _ConfettiPainter(_confetti)),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _StatusBanner(text: _bannerText),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                    child: NeonButton(
                      label: 'Skip',
                      icon: Icons.fast_forward_rounded,
                      secondary: true,
                      onPressed: _stop,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orbWidget(_Orb orb) {
    if (orb.opacity < 0.02) return const SizedBox.shrink();
    final effectiveSize = kBallSize * orb.scale;
    final showLabel =
        _phase == _Phase.celebrating &&
            !_isSplit &&
            _keepers.contains(orb);
    final showBadge = showLabel &&
        widget.session.winners.length > 1 &&
        orb.rank != null;
    final badge = showBadge ? '#${orb.rank}' : null;

    Widget child = Transform.rotate(
      angle: orb.spin,
      child: NeonBall(
        colorIndex: orb.option.colorIndex,
        size: effectiveSize,
        highlighted: showLabel,
        badge: badge,
      ),
    );

    if (showLabel) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 6),
          SizedBox(
            width: 120,
            child: Text(
              orb.option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.15,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
          ),
        ],
      );
    }

    return Positioned(
      left: orb.pos.dx - 60,
      top: orb.pos.dy - effectiveSize / 2 - 6,
      width: 120,
      child: Opacity(opacity: orb.opacity, child: Center(child: child)),
    );
  }

  List<Widget> _splitHeaders() {
    final groups = widget.session.groups;
    return List<Widget>.generate(groups.length, (g) {
      final gx = _size.width * ((g + 0.5) / groups.length);
      return Positioned(
        left: gx - 70,
        top: _size.height * 0.12,
        width: 140,
        child: Text(
          'Group ${g + 1}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: VxColors.cyan,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      );
    });
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _easeOutBack(double t) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  final k = t - 1;
  return 1 + c3 * k * k * k + c1 * k * k;
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.center, required this.winner});
  final Offset center;
  final ChoiceOption winner;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      top: center.dy + kBallSize * 1.15 + 16,
      child: Column(
        children: [
          const Text(
            'CHOSEN',
            style: TextStyle(
              color: VxColors.cyan,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            winner.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              shadows: [Shadow(color: Colors.black, blurRadius: 12)],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xE0121228),
        border: Border.all(color: VxColors.cyan.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.center,
    required this.radius,
    required this.spin,
    required this.speed,
    required this.intensity,
  });

  final Offset center;
  final double radius;
  final double spin;
  final double speed;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final ringA = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.10 + 0.10 * intensity);
    canvas.drawCircle(center, radius, ringA);
    canvas.drawCircle(center, radius - 12, ringA);
    canvas.drawCircle(
      center,
      radius + 12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    final tick = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 36; i++) {
      final a = spin * 0.4 + i * math.pi * 2 / 36;
      final major = i % 6 == 0;
      tick.color = Color.lerp(
        VxColors.cyan,
        VxColors.magenta,
        (i % 12) / 12,
      )!
          .withValues(alpha: (major ? 0.45 : 0.18) * (0.5 + 0.5 * intensity));
      final r1 = radius + 16;
      final r2 = radius + (major ? 26 : 22);
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * r1,
        center + Offset(math.cos(a), math.sin(a)) * r2,
        tick,
      );
    }

    if (speed > 1.5) {
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            VxColors.cyan
                .withValues(alpha: 0.10 + 0.08 * (speed - 1.5).clamp(0, 8)),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius * 1.6),
        );
      canvas.drawCircle(center, radius * 1.6, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.spin != spin ||
      old.center != center ||
      old.radius != radius ||
      old.intensity != intensity ||
      old.speed != speed;
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.orbs,
    required this.losers,
    required this.center,
    required this.baseRadius,
    required this.radiusScale,
    required this.ringSpin,
    required this.ringSpinSpeed,
  });

  final List<_Orb> orbs;
  final Set<_Orb> losers;
  final Offset center;
  final double baseRadius;
  final double radiusScale;
  final double ringSpin;
  final double ringSpinSpeed;

  @override
  void paint(Canvas canvas, Size size) {
    if (radiusScale <= 0 || ringSpinSpeed < 0.8) return;
    final trailStrength = (ringSpinSpeed / 9).clamp(0.0, 1.0);
    final steps = (6 + 10 * trailStrength).round();
    for (final orb in orbs) {
      if (orb.opacity < 0.02) continue;
      final tint = VxColors.ballTints[
          orb.option.colorIndex % VxColors.ballTints.length];
      final dim = losers.contains(orb) ? 0.65 : 1.0;
      for (var k = 1; k <= steps; k++) {
        final backAngle = orb.orbitAngle + ringSpin - k * 0.10 * trailStrength;
        final r = baseRadius * radiusScale;
        final p = center + Offset(math.cos(backAngle), math.sin(backAngle)) * r;
        final alpha = (1 - k / steps) * 0.28 * trailStrength * dim;
        final radius = (kBallSize / 2) * (1 - k / (steps + 4));
        canvas.drawCircle(p, radius, Paint()..color = tint.withValues(alpha: alpha));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) => true;
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.center,
    required this.spin,
    required this.intensity,
    required this.tint,
  });

  final Offset center;
  final double spin;
  final double intensity;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          tint.withValues(alpha: 0.55 * intensity),
          tint.withValues(alpha: 0.18 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.55),
      );
    canvas.drawCircle(center, size.width * 0.55, glow);

    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = tint.withValues(alpha: 0.32 * intensity);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin);
    for (var i = 0; i < 10; i++) {
      final a = (i / 10) * math.pi * 2;
      final r1 = size.width * 0.14;
      final r2 = size.width * 0.55;
      canvas.drawLine(
        Offset(math.cos(a) * r1, math.sin(a) * r1),
        Offset(math.cos(a) * r2, math.sin(a) * r2),
        rayPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.spin != spin ||
      old.center != center ||
      old.intensity != intensity;
}

class _FlashPainter extends CustomPainter {
  _FlashPainter({
    required this.center,
    required this.intensity,
    required this.tint,
  });

  final Offset center;
  final double intensity;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * (0.35 + 0.4 * (1 - intensity));
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.85 * intensity),
          tint.withValues(alpha: 0.55 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _FlashPainter old) =>
      old.intensity != intensity || old.center != center;
}

class _LanePainter extends CustomPainter {
  _LanePainter({required this.session});
  final DropSession session;

  @override
  void paint(Canvas canvas, Size size) {
    final n = session.groups.length;
    if (n == 0) return;
    final laneW = size.width / n;
    for (var g = 0; g < n; g++) {
      final tint = VxColors.ballTints[g % VxColors.ballTints.length];
      final rect = Rect.fromLTWH(laneW * g + 8, size.height * 0.16, laneW - 16, size.height * 0.62);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(22)),
        Paint()..color = tint.withValues(alpha: 0.10),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(22)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = tint.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LanePainter old) =>
      old.session.groupCount != session.groupCount;
}

class _ShockwavePainter extends CustomPainter {
  _ShockwavePainter(this.waves);
  final List<_Shockwave> waves;

  @override
  void paint(Canvas canvas, Size size) {
    for (final w in waves) {
      final progress = 1 - w.life;
      final r = size.width * (0.05 + progress * 0.55);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * w.life
        ..color = w.color.withValues(alpha: 0.55 * w.life);
      canvas.drawCircle(w.center, r, paint);
      final paint2 = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * w.life
        ..color = Colors.white.withValues(alpha: 0.35 * w.life);
      canvas.drawCircle(w.center, r * 0.85, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter old) => true;
}

class _StreakPainter extends CustomPainter {
  _StreakPainter({required this.center, required this.keepers});
  final Offset center;
  final List<_Orb> keepers;

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in keepers) {
      if (orb.opacity < 0.05 || (orb.presentTarget == null)) continue;
      final delta = orb.pos - center;
      if (delta.distance < 4) continue;
      final tint = VxColors.ballTints[
          orb.option.colorIndex % VxColors.ballTints.length];
      final unit = delta / delta.distance;
      final tail = orb.pos - unit * math.min(delta.distance, 90);
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..shader = LinearGradient(
          colors: [
            tint.withValues(alpha: 0.0),
            tint.withValues(alpha: 0.75),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromPoints(tail, orb.pos));
      canvas.drawLine(tail, orb.pos, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StreakPainter old) => true;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces);
  final List<_Confetti> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in pieces) {
      final paint = Paint()
        ..color = c.color.withValues(alpha: c.life.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(c.pos.dx, c.pos.dy);
      canvas.rotate(c.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -2, 8, 4),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
