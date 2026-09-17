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

  /// Built once, not per build.
  ///
  /// A CurvedAnimation registers itself as a listener on its parent,
  /// so creating one inside build() adds another listener on every
  /// frame and never removes any of them. This loader runs during
  /// every request in the app, which is the worst possible place to
  /// leak one listener per frame.
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 750))
      ..repeat(reverse: true);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value; // 0..1
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
