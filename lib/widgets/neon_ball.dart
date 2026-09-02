import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';

/// Shared diameter for every ball in lists, drop, and results.
const double kBallSize = 48;

class NeonBall extends StatelessWidget {
  const NeonBall({
    super.key,
    required this.colorIndex,
    this.size = kBallSize,
    this.highlighted = false,
    this.label,
    this.badge,
    this.onTap,
  });

  final int colorIndex;
  final double size;
  final bool highlighted;
  final String? label;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final index = colorIndex % AppAssets.balls.length;
    final tint = VxColors.ballTints[index];

    Widget ball = SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          AppAssets.balls[index],
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );

    if (highlighted) {
      // Tight ring hugging the ball; no external bloom that leaks
      // into neighbouring widgets.
      ball = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ball,
          IgnorePointer(
            child: SizedBox(
              width: size,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: SizedBox(
              width: size + 6,
              height: size + 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tint.withValues(alpha: 0.55),
                    width: 1.4,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final marked = badge == null
        ? ball
        : Stack(
            clipBehavior: Clip.none,
            children: [
              ball,
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xF0121228),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VxColors.cyan),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: VxColors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          );

    final content = label == null
        ? marked
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              marked,
              const SizedBox(height: 6),
              SizedBox(
                width: size * 2.2,
                child: Text(
                  label!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VxColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
