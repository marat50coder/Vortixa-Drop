import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';
import '../widgets/neon_ball.dart';
import '../widgets/neon_button.dart';
import 'drop_scene_screen.dart';

class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  final _a = TextEditingController();
  final _b = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuPage(
      title: 'Duel',
      subtitle: 'Two balls. One winner.',
      child: Column(
        children: [
          GlassPanel(
            child: Column(
              children: [
                _side(0, 'Side A', _a),
                const SizedBox(height: 12),
                const Text('VS', style: TextStyle(color: VxColors.magenta, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _side(1, 'Side B', _b),
              ],
            ),
          ),
          const Spacer(),
          NeonButton(
            label: 'Duel Drop',
            icon: Icons.bolt_rounded,
            onPressed: () {
              final left = _a.text.trim().isEmpty ? 'Side A' : _a.text.trim();
              final right = _b.text.trim().isEmpty ? 'Side B' : _b.text.trim();
              final store = context.read<AppStore>();
              store.applyPreset('Duel', [left, right]);
              store.setMode(DropMode.quick);
              AudioService.instance.play(AppAssets.soundDropStart);
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

  Widget _side(int color, String hint, TextEditingController controller) {
    return Row(
      children: [
        NeonBall(colorIndex: color),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
