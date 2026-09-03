import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../cord/reach_feel.dart';

/// Offline fallback surface. Sits behind a soft neon backdrop and lets the
/// user probe the connection again without leaving the app.
class VoidPage extends StatefulWidget {
  const VoidPage({
    super.key,
    required this.scout,
    required this.retryBuilder,
  });

  final ReachFeel scout;
  final WidgetBuilder retryBuilder;

  @override
  State<VoidPage> createState() => _VoidPageState();
}

class _VoidPageState extends State<VoidPage> {
  bool _probing = false;
  bool _stillDown = false;

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

  Future<void> _retry() async {
    if (_probing) return;
    HapticFeedback.lightImpact();
    setState(() {
      _probing = true;
      _stillDown = false;
    });
    bool online = false;
    try {
      online = await widget.scout.reachesNetwork();
    } catch (_) {
      online = false;
    }
    if (!mounted) return;
    if (online) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: widget.retryBuilder),
      );
      return;
    }
    setState(() {
      _probing = false;
      _stillDown = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final bool landscape = media.orientation == Orientation.landscape;
    final double cardWidth = landscape
        ? (media.size.width * 0.44).clamp(320.0, 540.0)
        : (media.size.width * 0.82).clamp(280.0, 440.0);

    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const _ConnectionGlyph(),
        SizedBox(height: landscape ? 18 : 22),
        Text(
          'NO INTERNET CONNECTION',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: landscape ? 22 : 26,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: Colors.white,
            shadows: const <Shadow>[
              Shadow(color: VxColors.cyan, blurRadius: 18),
            ],
          ),
        ),
        SizedBox(height: landscape ? 10 : 14),
        Text(
          'Check your connection and try again',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: landscape ? 15 : 16.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: VxColors.textMuted,
          ),
        ),
        SizedBox(height: landscape ? 22 : 30),
        _RetryPad(
          width: cardWidth,
          busy: _probing,
          onTap: _retry,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          child: _stillDown
              ? const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    'No connection yet',
                    style: TextStyle(
                      color: VxColors.magenta,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
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
                landscape ? Alignment.center : const Alignment(0, 0.05),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
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
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: <Color>[
              Color(0x552B6BFF),
              Color(0x22B24DFF),
              Color(0x00050510),
            ],
            stops: <double>[0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }
}

class _ConnectionGlyph extends StatelessWidget {
  const _ConnectionGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: VxColors.cyan.withValues(alpha: 0.45),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: VxColors.magenta.withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
        gradient: RadialGradient(
          colors: <Color>[
            VxColors.violet.withValues(alpha: 0.28),
            Colors.transparent,
          ],
        ),
      ),
      child: const Icon(
        Icons.wifi_off_rounded,
        color: Colors.white,
        size: 44,
      ),
    );
  }
}

class _RetryPad extends StatelessWidget {
  const _RetryPad({
    required this.width,
    required this.busy,
    required this.onTap,
  });

  final double width;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: busy ? null : VxColors.buttonGradient,
          color: busy ? const Color(0xFF1A1A30) : null,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: busy
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: VxColors.magenta.withValues(alpha: 0.32),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: busy ? null : onTap,
            child: Center(
              child: busy
                  ? const SizedBox.square(
                      dimension: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.replay_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
