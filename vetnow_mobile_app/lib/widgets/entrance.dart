import 'package:flutter/material.dart';

/// Fades and lifts a list item into place, a beat after the one above it.
///
/// A list that appears all at once reads as a screen redraw; the same
/// list arriving top-to-bottom reads as it being built for you. The
/// effect only works if it stays almost subliminal, so this is short
/// (220ms), small (a 14pt lift) and never repeats — it plays once, when
/// the item is first built, and then gets out of the way.
///
/// The stagger is capped: without it, the fortieth pet in a list would
/// sit invisible for over a second, and a long list would feel slower
/// rather than more considered.
class Entrance extends StatefulWidget {
  final Widget child;

  /// Position in the list. Decides how long this item waits.
  final int index;

  /// Skipped entirely when false — for lists that are being refreshed
  /// rather than shown for the first time.
  final bool enabled;

  const Entrance({
    super.key,
    required this.child,
    required this.index,
    this.enabled = true,
  });

  static const _stepMs = 45;
  static const _playMs = 220;
  static const _maxStaggered = 8;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  // The delay is part of the animation rather than a Timer in front of
  // it. A Future.delayed would have to be cancelled on dispose — and a
  // list scrolled quickly disposes items mid-delay — so instead one
  // controller runs for delay + play, and an Interval holds the item
  // still for the first stretch of it. Nothing to leak, nothing to
  // cancel, and pumpAndSettle in a test actually settles.
  late final int _delayMs = widget.index.clamp(0, Entrance._maxStaggered) * Entrance._stepMs;
  late final int _totalMs = _delayMs + Entrance._playMs;
  late final double _start = _delayMs / _totalMs;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Interval(_start, 1, curve: Curves.easeOut),
  );

  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.10),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Interval(_start, 1, curve: Curves.easeOutCubic),
  ));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Shrinks slightly while held, and springs back on release.
///
/// Cards that only change colour on tap feel like regions of a page;
/// cards that give under a finger feel like objects. The scale is
/// deliberately tiny — enough to notice in the hand, not enough to see
/// in a screenshot.
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableCard({super.key, required this.child, this.onTap});

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _held = false;

  void _set(bool value) {
    if (_held != value && mounted) setState(() => _held = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      // Opaque so the whole card area is the target, including its
      // padding, rather than only the painted children.
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _held ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
