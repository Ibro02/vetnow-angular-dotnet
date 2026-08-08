import 'package:flutter/material.dart';

/// A small pulsing paw icon used everywhere a loading spinner would
/// normally go (buttons, confirmations) — on brand, a little playful,
/// still calm enough not to be distracting.
class PawLoader extends StatefulWidget {
  final double size;
  final Color color;

  const PawLoader({super.key, this.size = 20, this.color = Colors.white});

  @override
  State<PawLoader> createState() => _PawLoaderState();
}

class _PawLoaderState extends State<PawLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value; // 0..1
        return Transform.scale(
          scale: 0.78 + (0.22 * t),
          child: Opacity(
            opacity: 0.55 + (0.45 * t),
            child: child,
          ),
        );
      },
      child: Icon(Icons.pets_rounded, size: widget.size, color: widget.color),
    );
  }
}
