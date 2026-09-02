import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: VxColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VxColors.stroke),
        boxShadow: [
          BoxShadow(
            color: VxColors.cyan.withValues(alpha: 0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return GestureDetector(onTap: onTap, child: panel);
  }
}
