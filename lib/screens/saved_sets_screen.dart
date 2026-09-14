import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/starter_packs.dart';
import '../services/audio_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_ball.dart';
import '../widgets/neon_button.dart';
import '../widgets/scene_background.dart';
import 'editor_screen.dart';

class SavedSetsScreen extends StatelessWidget {
  const SavedSetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return SceneBackground(
      asset: AppAssets.neonOrbit,
      scrim: 0.55,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            children: [
              const Text(
                'Saved Sets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: store.savedSets.isEmpty
                    ? GlassPanel(
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.asset(
                                AppAssets.savedSetsArt,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const Text(
                              'No saved sets yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create a set and save it for the next decision.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: VxColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: store.savedSets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final set = store.savedSets[i];
                          return GlassPanel(
                            onTap: () {
                              AudioService.instance.play(AppAssets.soundMenuOpen);
                              store.loadSavedSet(set);
                              store.openTab(HomeTabs.drop);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Loaded “${set.name}” into Drop'),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        set.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => store.toggleFavoriteSet(set.id),
                                      icon: Icon(
                                        store.isFavoriteSet(set.id)
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: store.isFavoriteSet(set.id)
                                            ? VxColors.cyan
                                            : Colors.white54,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        AudioService.instance
                                            .play(AppAssets.soundBallRemove);
                                        store.deleteSavedSet(set.id);
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${set.options.length} options',
                                  style: const TextStyle(color: VxColors.textMuted),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: kBallSize + 8,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: set.options.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (_, i) => NeonBall(
                                      colorIndex: set.options[i].colorIndex,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              NeonButton(
                label: 'New Set',
                icon: Icons.add_rounded,
                onPressed: () {
                  store.newBlankSet();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditorScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
