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
                  'Three Quick drops in a row. See who keeps winning.',
                  style: TextStyle(color: VxColors.textMuted),
                ),
                const SizedBox(height: 12),
                NeonButton(
                  label: 'Run Best of 3',
                  icon: Icons.looks_3_rounded,
                  onPressed: () => _bestOf3(context, store),
                ),
                const SizedBox(height: 8),
                NeonButton(
                  label: 'Watch one drop',
                  icon: Icons.replay_rounded,
                  secondary: true,
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

  void _bestOf3(BuildContext context, AppStore store) {
    store.ensureReadyToDrop();
    store.setMode(DropMode.quick);
    final error = store.validateDrop();
    if (error != null) {
      AudioService.instance.play(AppAssets.soundError);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final rounds = <String>[];
    for (var i = 0; i < 3; i++) {
      rounds.add(store.createSession().winners.first.label);
    }
    final tallies = <String, int>{};
    for (final label in rounds) {
      tallies[label] = (tallies[label] ?? 0) + 1;
    }
    final champ = tallies.entries.reduce((a, b) => a.value >= b.value ? a : b);
    AudioService.instance.play(AppAssets.soundSave);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VxColors.graphite,
        title: const Text('Best of 3', style: TextStyle(color: Colors.white)),
        content: Text(
          '1. ${rounds[0]}\n2. ${rounds[1]}\n3. ${rounds[2]}\n\nChampion: ${champ.key} (${champ.value}/3)',
          style: const TextStyle(color: Colors.white, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _drop(BuildContext context, AppStore store, DropMode mode) {
    store.ensureReadyToDrop();
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
