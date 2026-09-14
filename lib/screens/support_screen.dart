import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_urls.dart';
import '../widgets/glass_panel.dart';
import '../widgets/menu_page.dart';
import '../widgets/neon_button.dart';
import 'webview_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuPage(
      title: 'Support',
      subtitle: 'No account. Help stays on this device.',
      child: ListView(
        children: [
          const GlassPanel(
            child: Text(
              'Vortixa Drop is an offline decision tool. Add options as neon balls, choose Quick, Multi, or Split, then hold Drop. The result is a local random pick — no login and no internet required.',
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          const GlassPanel(
            child: Text(
              'Quick needs 2+ balls. Multi needs 3+ balls and ranks a short list. Split deals the same balls into groups. Daily, Duel, Presets, and Lab only start that same local pick.',
              style: TextStyle(color: VxColors.textMuted, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          GlassPanel(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'support@vortixadrop.com'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email copied: support@vortixadrop.com')),
              );
            },
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: TextStyle(
                    color: VxColors.cyan,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'support@vortixadrop.com',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to copy. Optional web form below if you have a network.',
                  style: TextStyle(color: VxColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NeonButton(
            label: 'Open support page',
            icon: Icons.open_in_browser_rounded,
            secondary: true,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SimpleWebViewScreen(
                    title: 'Support',
                    url: AppUrls.support,
                    readable: true,
                    fullscreen: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
