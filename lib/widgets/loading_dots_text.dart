import 'package:flutter/material.dart';

class LoadingDotsText extends StatefulWidget {
  const LoadingDotsText({
    super.key,
    this.label = 'Loading',
    this.style,
  });

  final String label;
  final TextStyle? style;

  @override
  State<LoadingDotsText> createState() => _LoadingDotsTextState();
}

class _LoadingDotsTextState extends State<LoadingDotsText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dots = 1 + (_controller.value * 3).floor().clamp(0, 2);
        return Text('${widget.label}${'.' * dots}', style: widget.style);
      },
    );
  }
}
