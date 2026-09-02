import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import 'scene_background.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.asset = AppAssets.neonOrbit,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SceneBackground(
      asset: asset,
      scrim: 0.56,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VxColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
