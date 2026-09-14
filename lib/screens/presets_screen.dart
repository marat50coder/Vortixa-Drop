import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/starter_packs.dart';
import '../services/audio_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MenuPage(
      title: 'Presets',
      subtitle: 'Tap a pack to load it into Drop.',
      child: ListView.separated(
        itemCount: StarterPacks.library.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final pack = StarterPacks.library[i];
          return GlassPanel(
            onTap: () {
              AudioService.instance.play(AppAssets.soundBallAdd);
              store.applyPreset(pack.$1, pack.$3);
              store.openTab(HomeTabs.drop);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Loaded “${pack.$1}” into Drop')),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: VxColors.ballTints[i % VxColors.ballTints.length]
                      .withValues(alpha: 0.22),
                  child: Text(
                    '${pack.$3.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        pack.$2,
                        style: const TextStyle(color: VxColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          );
        },
      ),
    );
  }
}
