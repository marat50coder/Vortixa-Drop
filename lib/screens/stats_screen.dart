import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';
import '../widgets/neon_ball.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final ranked = [...store.workingOptions]
      ..sort((a, b) => b.wins.compareTo(a.wins));
    final byMode = <DropMode, int>{};
    for (final h in store.history) {
      byMode[h.mode] = (byMode[h.mode] ?? 0) + 1;
    }
    return MenuPage(
      title: 'Stats',
      subtitle: 'Local only. Nothing leaves this phone.',
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(child: _stat('Streak', '${store.settings.streakCount}')),
              const SizedBox(width: 10),
              Expanded(child: _stat('Best', '${store.settings.bestStreak}')),
              const SizedBox(width: 10),
              Expanded(child: _stat('Drops', '${store.settings.totalDrops}')),
            ],
          ),
          const SizedBox(height: 12),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modes used',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick ${byMode[DropMode.quick] ?? 0}  ·  Multi ${byMode[DropMode.multi] ?? 0}  ·  Split ${byMode[DropMode.split] ?? 0}',
                  style: const TextStyle(color: VxColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Current set leaders',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (ranked.isEmpty)
            const Text('No balls yet.', style: TextStyle(color: VxColors.textMuted))
          else
            ...ranked.take(6).map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassPanel(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      NeonBall(colorIndex: o.colorIndex),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          o.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${o.wins} wins',
                        style: const TextStyle(color: VxColors.cyan, fontWeight: FontWeight.w800),
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

  Widget _stat(String label, String value) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: const TextStyle(color: VxColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
