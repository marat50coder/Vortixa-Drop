import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/app_urls.dart';
import '../data/app_store.dart';
import '../data/shot_keep.dart';
import '../services/audio_service.dart';
import '../widgets/face_chip.dart';
import '../widgets/glass_panel.dart';
import '../widgets/neon_button.dart';
import '../widgets/scene_background.dart';
import 'webview_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return SceneBackground(
      asset: AppAssets.neonOrbit,
      scrim: 0.58,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(AppAssets.gameName, height: 110, fit: BoxFit.contain),
            const SizedBox(height: 16),
            GlassPanel(
              child: Row(
                children: [
                  FaceChip(
                    path: store.facePath,
                    stamp: store.faceStamp,
                    size: 76,
                    showCamMark: true,
                    onTap: () => _editFace(context, store),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.facePath == null
                              ? 'Take a photo or choose one from your library.'
                              : 'Tap to replace or remove this photo.',
                          style: const TextStyle(
                            color: VxColors.textMuted,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonButton(
                          label: store.facePath == null
                              ? 'Add photo'
                              : 'Change',
                          icon: Icons.camera_alt_rounded,
                          expanded: true,
                          secondary: true,
                          onPressed: () => _editFace(context, store),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassPanel(
              child: Column(
                children: [
                  _toggle(
                    title: 'Sound',
                    value: store.settings.sound,
                    onChanged: (v) {
                      AudioService.instance.play(AppAssets.soundTap);
                      store.setSound(v);
                    },
                  ),
                  _toggle(
                    title: 'Haptics',
                    value: store.settings.haptics,
                    onChanged: store.setHaptics,
                  ),
                  _toggle(
                    title: 'Animations',
                    value: store.settings.animations,
                    onChanged: store.setAnimations,
                  ),
                  _toggle(
                    title: 'Skip last winner',
                    value: store.settings.skipRepeat,
                    onChanged: store.setSkipRepeat,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassPanel(
              child: Column(
                children: [
                  _tile(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Clear History',
                    onTap: () async {
                      await store.clearHistory();
                      AudioService.instance.play(AppAssets.soundSave);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('History cleared')),
                      );
                    },
                  ),
                  _tile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _openWeb(
                      context,
                      title: 'Privacy Policy',
                      url: AppUrls.privacyPolicy,
                      readable: true,
                    ),
                  ),
                  _tile(
                    icon: Icons.support_agent_rounded,
                    title: 'Support',
                    onTap: () => _openWeb(
                      context,
                      title: 'Support',
                      url: AppUrls.support,
                      readable: true,
                      fullscreen: true,
                    ),
                  ),
                  _tile(
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Vortixa Drop',
                        applicationVersion: '1.0.1',
                        applicationIcon: Image.asset(
                          AppAssets.icon,
                          width: 48,
                          height: 48,
                        ),
                        children: const [
                          Text(
                            'Offline neon decision tool. Add options, drop them through Vortixa, and get a local result. No account required.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: value,
      activeThumbColor: VxColors.cyan,
      onChanged: onChanged,
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: VxColors.cyan),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: onTap,
    );
  }

  Future<void> _editFace(BuildContext context, AppStore store) async {
    AudioService.instance.play(AppAssets.soundTap);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheet) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          child: GlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kept only on this device.',
                  style: TextStyle(
                    color: VxColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _tile(
                  icon: Icons.photo_camera_rounded,
                  title: 'Take a photo',
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await store.takeFace(FaceSource.camera);
                  },
                ),
                _tile(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose from library',
                  onTap: () async {
                    Navigator.of(sheet).pop();
                    await store.takeFace(FaceSource.gallery);
                  },
                ),
                if (store.facePath != null)
                  _tile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Remove photo',
                    onTap: () async {
                      Navigator.of(sheet).pop();
                      await store.wipeFace();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWeb(
    BuildContext context, {
    required String title,
    required String url,
    bool readable = false,
    bool fullscreen = false,
  }) async {
    AudioService.instance.play(AppAssets.soundMenuOpen);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SimpleWebViewScreen(
          title: title,
          url: url,
          readable: readable,
          fullscreen: fullscreen,
        ),
      ),
    );
  }
}
