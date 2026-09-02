import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const _cards = [
    ('Drop', 'Write options as neon balls, then hold Drop. Vortixa locks them on an orbit and one ball emerges.'),
    ('Multi', 'Needs 3+ balls. Several winners stay, ranked #1 #2 #3. Use it for a short list, not a single pick.'),
    ('Split', 'Balls orbit, then deal into lanes. Fair groups for teams, chores, or seats.'),
    ('Daily', 'A new question each day. Same local random — no account, no feed.'),
    ('Duel', 'Two names, one drop. Fast when you only have a pair.'),
    ('Offline', 'History, sets, and streaks stay on this device.'),
  ];

  @override
  Widget build(BuildContext context) {
    return MenuPage(
      title: 'Guide',
      subtitle: 'How Vortixa actually works.',
      child: ListView.separated(
        itemCount: _cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final card = _cards[i];
          return GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.$1,
                  style: const TextStyle(
                    color: VxColors.cyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.$2,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
