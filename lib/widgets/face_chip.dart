import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Round profile face. The photo is cropped to cover so letterbox bars
/// never show, then nudged a bit larger so the ring does not clip a halo.
class FaceChip extends StatelessWidget {
  const FaceChip({
    super.key,
    required this.path,
    this.stamp = 0,
    this.size = 56,
    this.onTap,
    this.showCamMark = false,
  });

  final String? path;
  final int stamp;
  final double size;
  final VoidCallback? onTap;
  final bool showCamMark;

  static const double _cropZoom = 1.22;

  @override
  Widget build(BuildContext context) {
    final double ring = size > 48 ? 2.2 : 1.8;
    final Widget face = path == null
        ? Icon(
            Icons.person_rounded,
            size: size * 0.48,
            color: Colors.white.withValues(alpha: 0.85),
          )
        : ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: Transform.scale(
                scale: _cropZoom,
                child: Image.file(
                  File(path!),
                  key: ValueKey<String>('face-$stamp-$path'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.person_rounded,
                    size: size * 0.48,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          );

    final Widget disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: path == null ? VxColors.buttonGradient : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: VxColors.cyan.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (path != null) const ColoredBox(color: VxColors.deepNavy),
          face,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.92),
                  width: ring,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final Widget stacked = showCamMark
        ? SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                disc,
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: size * 0.34,
                    height: size * 0.34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: VxColors.buttonGradient,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: size * 0.16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          )
        : disc;

    if (onTap == null) return stacked;
    return GestureDetector(onTap: onTap, child: stacked);
  }
}
