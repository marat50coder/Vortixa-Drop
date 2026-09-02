import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/orientation.dart';
import '../data/app_store.dart';
import '../services/audio_service.dart';
import '../widgets/horizontal_progress_bar.dart';
import '../widgets/loading_dots_text.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    VxOrientation.allowAny();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..addListener(() => setState(() {}));
    _progress.animateTo(0.9, curve: Curves.easeOutCubic);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final clock = Stopwatch()..start();
    try {
      await AudioService.instance.init();
      AudioService.instance.play(AppAssets.soundLaunch);
      if (!mounted) return;
      await context.read<AppStore>().load();
      if (!mounted) return;
      await _precache();
    } catch (_) {}

    const minDisplay = Duration(milliseconds: 2000);
    final remaining = minDisplay - clock.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    await _finishAndLaunch();
  }

  Future<void> _precache() async {
    final images = <String>[
      AppAssets.verticalLoading,
      AppAssets.horizontalLoading,
      AppAssets.gameName,
      AppAssets.dropChamber,
      AppAssets.vortexCore,
      AppAssets.vortexFunnel,
      ...AppAssets.balls,
    ];
    for (final path in images) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }
  }

  Future<void> _finishAndLaunch() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    await _progress.animateTo(
      1.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeIn,
    );
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    final store = context.read<AppStore>();
    await VxOrientation.lockPortrait();
    if (!mounted) return;
    final next = store.settings.onboardingComplete
        ? const HomeShell()
        : const OnboardingScreen();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.gameName,
                      height: landscape ? 64 : 88,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    SizedBox(height: landscape ? 10 : 14),
                    HorizontalProgressBar(progress: _progress.value),
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
