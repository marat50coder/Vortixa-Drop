import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../kine_chart.dart';
import '../vault/lane_chest.dart';
import '../vault/push_hub.dart';

/// Push permission invite screen, shown once between the boot and the
/// portal when the OS still lets us ask. The visual language matches the
/// Vortixa Drop menus: neon on void black, gradient primary button.
class BellAsk extends StatefulWidget {
  const BellAsk({
    super.key,
    required this.locker,
    required this.beacon,
    required this.nextBuilder,
    this.onTokenReady,
  });

  final LaneChest locker;
  final PushHub beacon;
  final WidgetBuilder nextBuilder;
  final Future<void> Function(String token)? onTokenReady;

  @override
  State<BellAsk> createState() => _BellAskState();
}

class _BellAskState extends State<BellAsk> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bool granted = await widget.beacon.requestPermission();
    final String? token = widget.beacon.token;
    if (granted && token != null && token.isNotEmpty) {
      await widget.onTokenReady?.call(token);
    }
    if (!granted) await _snooze();
    _forward();
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _snooze();
    _forward();
  }

  Future<void> _snooze() {
    final int readyAt =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        KineChart.pushInviteSnoozeSeconds;
    return widget.locker.snoozeInvite(readyAt);
  }

  void _forward() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.nextBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool landscape = media.orientation == Orientation.landscape;
    final double panelWidth = landscape
        ? (media.size.width * 0.5).clamp(340.0, 560.0)
        : (media.size.width * 0.86).clamp(300.0, 440.0);

    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const _BellGlyph(),
        SizedBox(height: landscape ? 16 : 22),
        Text(
          'ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: landscape ? 22 : 26,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: Colors.white,
            shadows: const <Shadow>[
              Shadow(color: VxColors.magenta, blurRadius: 16),
            ],
          ),
        ),
        SizedBox(height: landscape ? 10 : 14),
        Text(
          'Stay tuned for special offers and rewards',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: VxColors.textMuted,
            fontSize: landscape ? 15 : 16.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: landscape ? 22 : 28),
        _InvitePad(
          width: panelWidth,
          height: landscape ? 66 : 74,
          fontSize: landscape ? 22 : 24,
          label: 'Allow',
          primary: true,
          busy: _busy,
          onTap: _accept,
        ),
        SizedBox(height: landscape ? 12 : 16),
        _InvitePad(
          width: panelWidth * 0.9,
          height: landscape ? 58 : 64,
          fontSize: landscape ? 20 : 22,
          label: 'Skip',
          primary: false,
          busy: false,
          onTap: _skip,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _NeonBackdrop(),
          Align(
            alignment:
                landscape ? Alignment.center : const Alignment(0, 0.08),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonBackdrop extends StatelessWidget {
  const _NeonBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.15,
            colors: <Color>[
              Color(0x66FF2BD6),
              Color(0x2200E8FF),
              Color(0x00050510),
            ],
            stops: <double>[0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}

class _BellGlyph extends StatelessWidget {
  const _BellGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: VxColors.magenta.withValues(alpha: 0.55),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: VxColors.cyan.withValues(alpha: 0.45),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
        gradient: RadialGradient(
          colors: <Color>[
            VxColors.violet.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
      ),
      child: const Icon(
        Icons.notifications_active_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}

class _InvitePad extends StatelessWidget {
  const _InvitePad({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.label,
    required this.primary,
    required this.busy,
    required this.onTap,
  });

  final double width;
  final double height;
  final double fontSize;
  final String label;
  final bool primary;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: primary && !busy ? VxColors.buttonGradient : null,
          color: primary
              ? (busy ? const Color(0xFF1A1A30) : null)
              : const Color(0xFF141428),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: primary && !busy
              ? <BoxShadow>[
                  BoxShadow(
                    color: VxColors.magenta.withValues(alpha: 0.36),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: busy ? null : onTap,
            child: Center(
              child: busy
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        height: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
