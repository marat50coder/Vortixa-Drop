import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class HorizontalProgressBar extends StatelessWidget {
  const HorizontalProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
  });

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filled = constraints.maxWidth * value;
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
              if (filled > 0)
                Container(
                  width: filled,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height),
                    gradient: VxColors.neonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: VxColors.magenta.withValues(alpha: 0.45),
                        blurRadius: height * 2.4,
                      ),
                      BoxShadow(
                        color: VxColors.cyan.withValues(alpha: 0.35),
                        blurRadius: height * 1.6,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
