import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../services/audio_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';

class PresetsScreen extends StatelessWidget {
  const PresetsScreen({super.key});

  static const library = <(String, String, List<String>)>[
    ('Eat', 'Food when you cannot choose', ['Pizza', 'Sushi', 'Burger', 'Salad', 'Ramen', 'Tacos']),
    ('Watch', 'What to put on the screen', ['Movie', 'Series', 'YouTube', 'Anime', 'Doc']),
    ('Start', 'First move of the day', ['Inbox', 'Workout', 'Deep work', 'Break', 'Walk']),
    ('Coin', 'Simple two-way flip', ['Heads', 'Tails']),
    ('Yes / No', 'A clean binary', ['Yes', 'No']),
    ('Team', 'Assign people or sides', ['A', 'B', 'C', 'D']),
    ('Mood', 'How the evening goes', ['Out', 'Home', 'Gym', 'Call a friend']),
    ('Weekend', 'Saturday plan', ['Trip', 'Clean', 'Sleep', 'Party', 'Hobby']),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MenuPage(
      title: 'Presets',
      subtitle: 'Tap a pack to load it into Drop.',
      child: ListView.separated(
        itemCount: library.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final pack = library[i];
          return GlassPanel(
            onTap: () {
              AudioService.instance.play(AppAssets.soundBallAdd);
              store.applyPreset(pack.$1, pack.$3);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Loaded “${pack.$1}”')),
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
