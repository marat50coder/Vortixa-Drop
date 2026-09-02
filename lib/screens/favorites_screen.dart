import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../services/audio_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';
import '../widgets/neon_ball.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final favs = store.savedSets
        .where((s) => store.isFavoriteSet(s.id))
        .toList();
    return MenuPage(
      title: 'Favorites',
      subtitle: 'Star a set on the Sets screen to pin it here.',
      child: favs.isEmpty
          ? const Center(
              child: Text(
                'No favorites yet.',
                style: TextStyle(color: VxColors.textMuted),
              ),
            )
          : ListView.separated(
              itemCount: favs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final set = favs[i];
                return GlassPanel(
                  onTap: () {
                    AudioService.instance.play(AppAssets.soundMenuOpen);
                    store.loadSavedSet(set);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loaded “${set.name}”')),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: kBallSize,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: set.options.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, j) =>
                              NeonBall(colorIndex: set.options[j].colorIndex),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
