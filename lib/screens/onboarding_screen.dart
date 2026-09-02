import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/orientation.dart';
import '../data/app_store.dart';
import '../services/audio_service.dart';
import '../widgets/neon_button.dart';
import '../widgets/scene_background.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'Write the choice',
      body: 'Turn a real decision into neon balls — what to eat, watch, start, or who goes first.',
      art: AppAssets.onboardingAdd,
    ),
    (
      title: 'Drop through Vortixa',
      body: 'Balls fall, collide, and leave one by one. The last ones standing are your result.',
      art: AppAssets.onboardingDrop,
    ),
    (
      title: 'A clear local pick',
      body: 'Quick picks one winner, Multi ranks a few, Split makes teams. Everything stays on this device.',
      art: AppAssets.onboardingResult,
    ),
  ];

  @override
  void initState() {
    super.initState();
    VxOrientation.lockPortrait();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppStore>().completeOnboarding();
    AudioService.instance.play(AppAssets.soundMenuOpen);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const HomeShell(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: VxColors.voidBlack,
      body: SceneBackground(
        asset: AppAssets.neonOrbit,
        scrim: 0.55,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: Column(
              children: [
                Image.asset(AppAssets.gameName, height: 92, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) {
                      final page = _pages[i];
                      return Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Image.asset(
                                page.art,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: VxColors.textMuted,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: active ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: active ? VxColors.cyan : Colors.white24,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                NeonButton(
                  label: last ? 'Start' : 'Next',
                  icon: last ? Icons.auto_awesome : Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (last) {
                      _finish();
                    } else {
                      _page.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
