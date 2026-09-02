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
import 'editor_screen.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  static const _prompts = [
    'What should you eat tonight?',
    'What comes first today?',
    'How do you spend the next hour?',
    'Who do you text first?',
    'What do you watch tonight?',
    'Where do you go after this?',
    'What habit do you keep today?',
  ];

  static String promptFor(DateTime now) {
    final key = now.year * 400 + now.month * 32 + now.day;
    return _prompts[key % _prompts.length];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final prompt = promptFor(DateTime.now());
    return MenuPage(
      title: 'Daily',
      subtitle: 'One fresh question. Local pick only.',
      child: Column(
        children: [
          GlassPanel(
            child: Column(
              children: [
                const Text(
                  'TODAY',
                  style: TextStyle(
                    color: VxColors.cyan,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            store.workingOptions.length < 2
                ? 'Load a set or write options for this prompt.'
                : '${store.workingOptions.length} balls ready',
            style: const TextStyle(color: VxColors.textMuted),
          ),
          const Spacer(),
          NeonButton(
            label: 'Edit options',
            icon: Icons.tune_rounded,
            secondary: true,
            onPressed: () {
              store.setWorkingName('Daily');
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          NeonButton(
            label: 'Drop today’s pick',
            icon: Icons.south_rounded,
            onPressed: () {
              store.setMode(DropMode.quick);
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
            },
          ),
        ],
      ),
    );
  }
}
