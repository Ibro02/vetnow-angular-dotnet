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

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.circle = false,
    this.onTap,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: surface,
      ),
    );
  }
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
