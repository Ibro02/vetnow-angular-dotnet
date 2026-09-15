import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Layered, luxurious "something's alive here" motion behind hero
/// sections: soft drifting glow orbs (teal + gold), twinkling sparkles,
/// a handful of faint paw prints, and — depending on where it's used —
/// either a heartbeat pulse line (Explore/guest prompts, the "clinical"
/// screens) or gently rising hearts (Login/Register, the "welcome you
/// in" screens). Everything stays low-opacity and sits fully behind
/// the header text/controls — a texture, not a distraction.
class VetHeroBackground extends StatefulWidget {
  final bool showPulse;
  final bool showFloatingHearts;

  const VetHeroBackground({
    super.key,
    this.showPulse = true,
    this.showFloatingHearts = false,
  });

  @override
  State<VetHeroBackground> createState() => _VetHeroBackgroundState();
}

class _VetHeroBackgroundState extends State<VetHeroBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Excluded as well as ignored: this is texture, and a screen reader
    // walking a decorative canvas is noise between the header and the
    // first thing actually worth hearing.
    return ExcludeSemantics(
      child: IgnorePointer(
        // The one thing on this screen that repaints every single
        // frame, for as long as it is open. Without a boundary it has
        // no layer of its own, so every frame of the drifting paws
        // also repaints the hero gradient, the sheen, the vignette,
        // the headline and the glass buttons on top of it — which is
        // exactly the cost that turns into dropped frames on a
        // mid-range phone while someone is scrolling.
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _VetPainter(
                _controller.value,
                showPulse: widget.showPulse,
                showFloatingHearts: widget.showFloatingHearts,
              ),
              // Repainted constantly and never worth caching, which
              // is what these two flags tell the engine.
              isComplex: false,
              willChange: true,
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _VetPainter extends CustomPainter {
  final double t; // 0..1 looping
  final bool showPulse;
  final bool showFloatingHearts;

  _VetPainter(this.t, {required this.showPulse, required this.showFloatingHearts});

  static const _paws = [
    (dx: 0.10, dy: 0.20, scale: 1.1, speed: 1.0, delay: 0.0),
    (dx: 0.85, dy: 0.14, scale: 0.8, speed: 0.7, delay: 0.3),
    (dx: 0.62, dy: 0.52, scale: 1.2, speed: 1.3, delay: 0.6),
    (dx: 0.26, dy: 0.60, scale: 0.75, speed: 0.9, delay: 0.15),
    (dx: 0.94, dy: 0.66, scale: 0.9, speed: 1.1, delay: 0.45),
    (dx: 0.45, dy: 0.10, scale: 0.65, speed: 1.2, delay: 0.75),
    (dx: 0.05, dy: 0.72, scale: 0.85, speed: 0.85, delay: 0.55),
    (dx: 0.75, dy: 0.75, scale: 0.7, speed: 1.05, delay: 0.85),
    (dx: 0.35, dy: 0.30, scale: 0.6, speed: 0.95, delay: 0.4),
  ];

  // A little sequence of paws that "walk" diagonally across the hero —
  // alternating left/right rotation like real tracks, brighter than
  // the ambient drifting ones so the motion actually reads as
  // footsteps rather than random noise.
  static const _trail = [
    (dx: -0.05, dy: 0.78, delay: 0.00, rot: -12.0),
    (dx: 0.10, dy: 0.66, delay: 0.06, rot: 14.0),
    (dx: 0.25, dy: 0.56, delay: 0.12, rot: -12.0),
    (dx: 0.40, dy: 0.46, delay: 0.18, rot: 14.0),
    (dx: 0.55, dy: 0.38, delay: 0.24, rot: -12.0),
  ];

  static const _sparkles = [
    (dx: 0.20, dy: 0.35, size: 3.0, speed: 1.4, delay: 0.0),
    (dx: 0.70, dy: 0.25, size: 2.2, speed: 1.1, delay: 0.25),
    (dx: 0.88, dy: 0.45, size: 2.6, speed: 1.6, delay: 0.5),
    (dx: 0.40, dy: 0.48, size: 2.0, speed: 0.9, delay: 0.7),
    (dx: 0.15, dy: 0.55, size: 2.8, speed: 1.3, delay: 0.15),
    (dx: 0.58, dy: 0.15, size: 2.2, speed: 1.0, delay: 0.85),
  ];

  // Small hearts that gently rise from the bottom and fade near the
  // top, like little bubbles of affection — used instead of the
  // heartbeat pulse on the "welcome you in" screens (Login/Register)
  // where a medical-monitor line feels like the wrong mood.
  static const _hearts = [
    (dx: 0.12, size: 10.0, speed: 0.55, delay: 0.0),
    (dx: 0.30, size: 7.0, speed: 0.7, delay: 0.35),
    (dx: 0.55, size: 12.0, speed: 0.5, delay: 0.6),
    (dx: 0.72, size: 8.0, speed: 0.65, delay: 0.15),
    (dx: 0.88, size: 9.0, speed: 0.6, delay: 0.8),
    (dx: 0.45, size: 6.5, speed: 0.75, delay: 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawGlowOrbs(canvas, size);
    for (final p in _paws) {
      final localT = (t * p.speed + p.delay) % 1.0;
      final drift = sin(localT * 2 * pi) * 6;
      final opacity = (sin(localT * pi) * 0.20).clamp(0.0, 0.20);
      final center = Offset(size.width * p.dx, size.height * p.dy + drift);
      _drawPaw(canvas, center, 17 * p.scale, opacity);
    }
    _drawWalkingTrail(canvas, size);
    for (final s in _sparkles) {
      final localT = (t * s.speed + s.delay) % 1.0;
      final twinkle = (sin(localT * 2 * pi) * 0.5 + 0.5); // 0..1
      final opacity = (twinkle * 0.55).clamp(0.0, 0.55);
      final center = Offset(size.width * s.dx, size.height * s.dy);
      _drawSparkle(canvas, center, s.size * (0.7 + twinkle * 0.5), opacity);
    }
    if (showPulse) _drawPulse(canvas, size);
    if (showFloatingHearts) _drawFloatingHearts(canvas, size);
  }

  void _drawFloatingHearts(Canvas canvas, Size size) {
    for (final h in _hearts) {
      final localT = (t * h.speed + h.delay) % 1.0;
      // Rise from just below the bottom edge to well above the top,
      // fading in on the way up and out near the very top.
      final y = size.height * 1.08 - (localT * size.height * 1.25);
      final sway = sin(localT * 4 * pi) * 10;
      final opacity = (sin(localT * pi) * 0.22).clamp(0.0, 0.22);
      final center = Offset(size.width * h.dx + sway, y);
      _drawHeart(canvas, center, h.size, opacity);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, double opacity) {
    if (opacity <= 0) return;
    final paint = Paint()..color = AppColors.gold.withValues(alpha: opacity);
    final path = Path();
    final w = size;
    path.moveTo(center.dx, center.dy + w * 0.35);
    path.cubicTo(
      center.dx - w * 0.9,
      center.dy - w * 0.35,
      center.dx - w * 0.35,
      center.dy - w * 0.95,
      center.dx,
      center.dy - w * 0.35,
    );
    path.cubicTo(
      center.dx + w * 0.35,
      center.dy - w * 0.95,
      center.dx + w * 0.9,
      center.dy - w * 0.35,
      center.dx,
      center.dy + w * 0.35,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawWalkingTrail(Canvas canvas, Size size) {
    const cycleSpeed = 0.55; // full walk cycles per loop
    for (final p in _trail) {
      final localT = ((t * cycleSpeed) + p.delay) % 1.0;
      // Fade each print in, hold, then fade out — a moving "reveal"
      // window rather than a constant static trail.
      final window = (localT * 5) % 1.0;
      final opacity = (sin(window * pi) * 0.26).clamp(0.0, 0.26);
      final center = Offset(size.width * p.dx, size.height * p.dy);
      _drawPaw(canvas, center, 15, opacity, rotationDegrees: p.rot);
    }
  }

  void _drawGlowOrbs(Canvas canvas, Size size) {
    final orb1T = (t * 0.6) % 1.0;
    final orb1Center = Offset(
      size.width * (0.15 + 0.10 * sin(orb1T * 2 * pi)),
      size.height * (0.25 + 0.08 * cos(orb1T * 2 * pi)),
    );
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.gold.withValues(alpha: 0.16), AppColors.gold.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: 90));
    canvas.drawCircle(orb1Center, 90, orb1Paint);

    final orb2T = (t * 0.45 + 0.4) % 1.0;
    final orb2Center = Offset(
      size.width * (0.80 + 0.08 * cos(orb2T * 2 * pi)),
      size.height * (0.55 + 0.10 * sin(orb2T * 2 * pi)),
    );
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.accent.withValues(alpha: 0.14), AppColors.accent.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: 110));
    canvas.drawCircle(orb2Center, 110, orb2Paint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, double opacity) {
    if (opacity <= 0) return;
    final paint = Paint()..color = AppColors.gold.withValues(alpha: opacity);
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.28, center.dy - size * 0.28);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.28, center.dy + size * 0.28);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.28, center.dy + size * 0.28);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.28, center.dy - size * 0.28);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPulse(Canvas canvas, Size size) {
    final pulsePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const unitWidth = 140.0;
    const cyclesPerLoop = 8; // must be an integer so the wrap is seamless
    const totalShift = unitWidth * cyclesPerLoop;
    final shift = (t * totalShift) % unitWidth;

    final baseY = size.height * 0.86;

    Path beatUnit(double startX) {
      final p = Path();
      p.moveTo(startX, baseY);
      p.lineTo(startX + unitWidth * 0.32, baseY);
      p.lineTo(startX + unitWidth * 0.40, baseY - 16);
      p.lineTo(startX + unitWidth * 0.48, baseY + 22);
      p.lineTo(startX + unitWidth * 0.56, baseY - 8);
      p.lineTo(startX + unitWidth * 0.64, baseY);
      p.lineTo(startX + unitWidth, baseY);
      return p;
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    var x = -unitWidth - shift;
    while (x < size.width + unitWidth) {
      canvas.drawPath(beatUnit(x), pulsePaint);
      x += unitWidth;
    }
    canvas.restore();
  }

  void _drawPaw(Canvas canvas, Offset center, double size, double opacity, {double rotationDegrees = 0}) {
    if (opacity <= 0) return;
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);

    canvas.save();
    if (rotationDegrees != 0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationDegrees * pi / 180);
      canvas.translate(-center.dx, -center.dy);
    }
    canvas.drawOval(Rect.fromCenter(center: center, width: size, height: size * 0.85), paint);
    const toeOffsets = [(-0.55, -0.75), (-0.22, -1.0), (0.22, -1.0), (0.55, -0.75)];
    for (final o in toeOffsets) {
      final toeCenter = center + Offset(o.$1 * size * 0.6, o.$2 * size * 0.5);
      canvas.drawOval(Rect.fromCenter(center: toeCenter, width: size * 0.32, height: size * 0.4), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VetPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.showPulse != showPulse ||
      oldDelegate.showFloatingHearts != showFloatingHearts;
}
