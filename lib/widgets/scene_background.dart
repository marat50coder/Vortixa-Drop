import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class SceneBackground extends StatelessWidget {
  const SceneBackground({
    super.key,
    required this.asset,
    required this.child,
    this.scrim = 0.42,
  });

  final String asset;
  final Widget child;
  final double scrim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: VxColors.voidBlack),
        Image.asset(
          asset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        ColoredBox(color: Colors.black.withValues(alpha: scrim)),
        child,
      ],
    );
  }
}
