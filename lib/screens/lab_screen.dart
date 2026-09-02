import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';
import '../widgets/neon_button.dart';
import 'drop_scene_screen.dart';

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MenuPage(
      title: 'Lab',
      subtitle: 'Small experiments on the current set.',
      child: ListView(
        children: [
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best of 3',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Three Quick drops in a row. Watch who keeps winning.',
                  style: TextStyle(color: VxColors.textMuted),
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Run a round',
                  icon: Icons.replay_rounded,
                  onPressed: () => _drop(context, store, DropMode.quick),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shuffle colors',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Same names, new ball colors.',
                  style: TextStyle(color: VxColors.textMuted),
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Shuffle',
                  icon: Icons.shuffle_rounded,
                  secondary: true,
                  onPressed: () {
                    AudioService.instance.play(AppAssets.soundBallAdd);
                    store.shuffleColors();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reset win counts',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Clears “Won Nx” on the current set.',
                  style: TextStyle(color: VxColors.textMuted),
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Reset wins',
                  icon: Icons.refresh_rounded,
                  secondary: true,
                  onPressed: () {
                    store.resetWinCounts();
                    AudioService.instance.play(AppAssets.soundSave);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _drop(BuildContext context, AppStore store, DropMode mode) {
    store.setMode(mode);
    final error = store.validateDrop();
    if (error != null) {
      AudioService.instance.play(AppAssets.soundError);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DropSceneScreen(session: store.createSession()),
      ),
    );
  }
}
