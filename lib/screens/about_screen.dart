import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuPage(
      title: 'About',
      subtitle: 'Vortixa Drop 1.0.1',
      child: ListView(
        children: [
          Image.asset(AppAssets.gameName, height: 88, fit: BoxFit.contain),
          const SizedBox(height: 16),
          const GlassPanel(
            child: Text(
              'Vortixa Drop is an offline decision tool. Options become neon balls, lock onto an orbit, and one result stays on this device. No account. No feed. No notifications.',
              style: TextStyle(color: Colors.white, height: 1.4, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          const GlassPanel(
            child: Text(
              'Quick picks one winner. Multi ranks a short list. Split deals teams. Daily, Duel, and Lab are extra ways to start the same local pick.',
              style: TextStyle(color: VxColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
