import 'package:flutter/material.dart';
import '../config/theme.dart';

/// The shape the Explore header is cut to.
///
/// A rectangle with two rounded corners is the default every app has.
/// Sweeping the bottom edge into a shallow concave curve costs nothing,
/// reads as drawn rather than defaulted, and — because the curve is
/// deepest in the middle — leaves the search bar below sitting in a
/// cradle instead of butting against a straight line.
class HeroSweepClipper extends CustomClipper<Path> {
  /// How far the centre of the bottom edge rises above the sides.
  final double sweep;

  const HeroSweepClipper({this.sweep = 26});

  @override
  Path getClip(Size size) {
    const corner = AppRadius.xl2;

    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - corner)
      ..quadraticBezierTo(size.width, size.height, size.width - corner, size.height)
      // The single curve that does the work: both ends sit at the bottom
      // edge, the control point is pulled up past it, so the middle lifts.
      ..cubicTo(
        size.width * 0.72, size.height - sweep,
        size.width * 0.28, size.height - sweep,
        corner, size.height,
      )
      ..quadraticBezierTo(0, size.height, 0, size.height - corner)
      ..close();
  }

  @override
  bool shouldReclip(covariant HeroSweepClipper oldClipper) => oldClipper.sweep != sweep;
}

/// Traces a hero's swept bottom edge in gold, fading out towards the
/// corners so it reads as light catching a rim rather than as a border.
class HeroEdgeLight extends StatelessWidget {
  final double sweep;

  const HeroEdgeLight({super.key, this.sweep = 26});

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(painter: _EdgeLightPainter(sweep)));
}

class _EdgeLightPainter extends CustomPainter {
  final double sweep;

  _EdgeLightPainter(this.sweep);

  @override
  void paint(Canvas canvas, Size size) {
    // The same curve HeroSweepClipper cuts, stroked instead of cut — and
    // lifted a hair inside it. Drawn exactly on the boundary, the clip
    // eats the outer half of the stroke and the rest is invisible.
    const inset = 1.2;
    final h = size.height - inset;

    final path = Path()
      ..moveTo(0, h - AppRadius.xl2)
      ..quadraticBezierTo(0, h, AppRadius.xl2, h)
      ..cubicTo(
        size.width * 0.28, h - sweep,
        size.width * 0.72, h - sweep,
        size.width - AppRadius.xl2, h,
      )
      ..quadraticBezierTo(size.width, h, size.width, h - AppRadius.xl2);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0x00E8A73C), Color(0xCCE8A73C), Color(0x00E8A73C)],
          stops: [0.10, 0.5, 0.90],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _EdgeLightPainter oldDelegate) => oldDelegate.sweep != sweep;
}

/// The header panel every main screen sits under.
///
/// One widget rather than a recipe repeated per screen, so Explore,
/// Pets, Appointments and Profile cannot drift apart: same sweep, same
/// rim light, same layering, same shadow. Pass [background] for a screen
/// that wants its own texture behind the content.
///
/// The layers, deepest first: the ink gradient, an optional texture, the
/// top-left sheen every branded surface in the app carries, a vignette
/// that darkens the corners so the middle reads as lit, the content, and
/// finally the gold rim tracing the swept edge.
class HeroSurface extends StatelessWidget {
  final Widget child;

  /// Painted between the gradient and the sheen — drifting paws, say.
  final Widget? background;

  final double sweep;

  const HeroSurface({
    super.key,
    required this.child,
    this.background,
    this.sweep = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The shadow has to sit outside the clip: clipped, it would be cut
        // off at the very edge it is supposed to be falling from.
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipPath(
          clipper: HeroSweepClipper(sweep: sweep),
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.ink),
            child: Stack(
              children: [
                if (background != null) Positioned.fill(child: background!),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
                  ),
                ),
                const Positioned.fill(child: HeroVignette()),
                child,
                Positioned.fill(child: HeroEdgeLight(sweep: sweep)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A translucent "glass" surface for controls sitting on the hero.
///
/// Deliberately not a BackdropFilter. Real blur behind four chips inside
/// a scrolling header means four extra render passes on every frame, and
/// on a mid-range Android that is exactly where a list starts to stutter.
/// What actually reads as glass is the edge, not the blur: a bright
/// hairline along the top, fading to nothing at the bottom, over a
/// translucent fill.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  /// Circular instead of a rounded rectangle — for icon buttons.
  final bool circle;

  final VoidCallback? onTap;

  /// What a screen reader announces. An icon-only button without one is
  /// silent to anyone who cannot see it, which is most of what these are
  /// used for — the bell, the language switch.
  final String? semanticLabel;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.circle = false,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final radius = circle
        ? BorderRadius.circular(AppRadius.full)
        : (borderRadius ?? BorderRadius.circular(AppRadius.full));

    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        // Lit from the top, like a glass edge catching the light above it.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.20),
            Colors.white.withValues(alpha: 0.09),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.8),
      ),
      child: child,
    );

    if (onTap == null) return surface;

    final button = Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: surface,
        ),
      ),
    );

    if (!circle) return button;

    // A 34pt circle is the right size to *look* at and too small to
    // reliably *hit* — both Android and iOS ask for 44–48. The painted
    // circle stays as it is and the target grows around it, so the header
    // looks identical and stops needing a precise thumb.
    return SizedBox(
      width: _minTapTarget,
      height: _minTapTarget,
      child: Center(child: button),
    );
  }

  static const _minTapTarget = 46.0;
}

/// Darkens the corners so the middle of the header reads as lit.
///
/// The hero's own gradient is even across the whole surface, which makes
/// a large panel look flat however good the colours are. A vignette is
/// the cheapest way to give it a centre.
class HeroVignette extends StatelessWidget {
  const HeroVignette({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.1, -0.35),
            radius: 1.25,
            colors: [Color(0x00000000), Color(0x00000000), Color(0x3D06201E)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}
