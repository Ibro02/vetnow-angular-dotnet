import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Which silhouette a pet gets. Ten species share six shapes, because a
/// hamster and a guinea pig read the same at 40 pixels and pretending
/// otherwise would just make both of them worse.
enum PetKind { dog, cat, rabbit, bird, fish, turtle }

/// Maps a species name to a silhouette.
///
/// Matching is loose on purpose: the backend's species list is free text
/// a clinic admin types, so "Budgerigar", "Parrot" and anything else
/// bird-ish should all land on the bird. Anything unrecognised falls back
/// to the dog, which is the species most pets in this app actually are.
PetKind petKindFor(String species) {
  final s = species.toLowerCase();

  bool has(List<String> needles) => needles.any(s.contains);

  if (has(['cat', 'mac', 'mač', 'kitten'])) return PetKind.cat;
  if (has(['rabbit', 'zec', 'bunny', 'hamster', 'guinea', 'zamor', 'ferret', 'tvor'])) {
    return PetKind.rabbit;
  }
  if (has(['bird', 'ptic', 'parrot', 'papag', 'budgerig', 'kanar', 'canary'])) {
    return PetKind.bird;
  }
  if (has(['fish', 'rib', 'goldfish'])) return PetKind.fish;
  if (has(['turtle', 'kornj', 'tortoise'])) return PetKind.turtle;
  return PetKind.dog;
}

/// A pet's portrait: a silhouette on a gradient, drawn rather than
/// loaded, so it costs nothing and stays sharp at any size.
///
/// Every pet used to wear the identical grey paw icon, which made a list
/// of ten pets read as one pet repeated. Each species now has its own
/// shape, and each pet its own gradient — picked from its id, so a pet
/// looks the same on every screen and every launch.
///
/// The gradients are pairings of existing brand tokens; the palette is
/// unchanged.
class PetAvatar extends StatelessWidget {
  final String species;

  /// Used to pick the gradient, so it is stable per pet.
  final int seed;

  final double size;

  /// Fills its parent instead of using [size] — for the grid card, where
  /// the portrait is the whole tile.
  final bool expand;

  const PetAvatar({
    super.key,
    required this.species,
    required this.seed,
    this.size = 48,
    this.expand = false,
  });

  static const _palettes = <List<Color>>[
    [AppColors.primaryLight, AppColors.primary],
    [AppColors.accent, AppColors.accentActive],
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.accentHover, AppColors.primaryDark],
    [AppColors.primaryLight, AppColors.accent],
    [AppColors.accent, AppColors.primary],
  ];

  List<Color> get _gradient => _palettes[seed.abs() % _palettes.length];

  @override
  Widget build(BuildContext context) {
    final kind = petKindFor(species);

    final painted = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The same top-left light as every other branded surface.
          const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
          CustomPaint(
            painter: _PetSilhouettePainter(kind),
            // Repainting a static silhouette on every frame of a list
            // scroll is pure waste; the shape only depends on the kind.
            isComplex: false,
            willChange: false,
          ),
        ],
      ),
    );

    if (expand) return painted;

    return ClipOval(
      child: SizedBox(width: size, height: size, child: painted),
    );
  }
}

/// Draws one species silhouette in white, centred in the available box.
///
/// Everything is laid out on a 100×100 grid and scaled, so the same
/// geometry works at 36px on a list row and at 160px on a detail header.
class _PetSilhouettePainter extends CustomPainter {
  final PetKind kind;

  _PetSilhouettePainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    // Fit the 100-unit design square inside the box, then inset it a
    // little so the silhouette never touches the circular clip.
    final scale = math.min(size.width, size.height) / 100 * 0.70;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    switch (kind) {
      case PetKind.dog:
        _dog(canvas, paint);
        break;
      case PetKind.cat:
        _cat(canvas, paint);
        break;
      case PetKind.rabbit:
        _rabbit(canvas, paint);
        break;
      case PetKind.bird:
        _bird(canvas, paint);
        break;
      case PetKind.fish:
        _fish(canvas, paint);
        break;
      case PetKind.turtle:
        _turtle(canvas, paint);
        break;
    }

    canvas.restore();
  }

  /// A rounded ellipse, the building block of every one of these.
  void _oval(Canvas c, Paint p, double cx, double cy, double w, double h, [double rotation = 0]) {
    c.save();
    c.translate(cx, cy);
    if (rotation != 0) c.rotate(rotation);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: w, height: h), p);
    c.restore();
  }

  // Same front-facing family as the cat and the rabbit — one head, two
  // ears — and the ears are the whole difference: a dog's drop from the
  // top corners and hang beside the head, where a cat's point up.
  void _dog(Canvas c, Paint p) {
    _oval(c, p, -36, 6, 26, 50, 0.30);
    _oval(c, p, 36, 6, 26, 50, -0.30);
    _oval(c, p, 0, -2, 60, 56);
    _oval(c, p, 0, 22, 34, 26);
  }

  // Narrow head, upright triangular ears, whiskers.
  void _cat(Canvas c, Paint p) {
    // Ear bases sit inside the head outline, not above it — drawn any
    // higher and the triangles float free of the face.
    final leftEar = Path()
      ..moveTo(-36, -6)
      ..lineTo(-30, -48)
      ..lineTo(-2, -20)
      ..close();
    final rightEar = Path()
      ..moveTo(36, -6)
      ..lineTo(30, -48)
      ..lineTo(2, -20)
      ..close();
    c.drawPath(leftEar, p);
    c.drawPath(rightEar, p);

    _oval(c, p, 0, 4, 66, 58);

    // Whiskers: thin strokes reaching past the cheeks, which is what
    // separates a cat silhouette from any other round head.
    final whisker = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final dy in [-4.0, 6.0]) {
      c.drawLine(Offset(-30, dy), Offset(-56, dy - 6), whisker);
      c.drawLine(Offset(30, dy), Offset(56, dy - 6), whisker);
    }
  }

  // Two tall ears above a compact head.
  void _rabbit(Canvas c, Paint p) {
    _oval(c, p, -15, -40, 20, 56, -0.12);
    _oval(c, p, 15, -40, 20, 56, 0.12);
    _oval(c, p, 0, 16, 56, 48);
  }

  // A whole bird, side on — the same choice as the fish and the turtle.
  //
  // Face-first it never worked: a round head with a beak under it reads
  // as a root vegetable, whichever way the beak points. In profile the
  // small high head, the leaning body and the fanned tail are legible
  // even at list-row size.
  void _bird(Canvas c, Paint p) {
    final tail = Path()
      ..moveTo(-24, 10)
      ..lineTo(-64, 30)
      ..lineTo(-58, 4)
      ..close();
    c.drawPath(tail, p);

    _oval(c, p, -4, 8, 58, 46, -0.22);
    _oval(c, p, 18, -26, 34, 33);

    final beak = Path()
      ..moveTo(33, -31)
      ..lineTo(56, -25)
      ..lineTo(33, -18)
      ..close();
    c.drawPath(beak, p);

    // A wing, so the body isn't a bare oval.
    _oval(c, p, -2, 10, 34, 20, -0.25);
  }

  // Body and a fanned tail.
  void _fish(Canvas c, Paint p) {
    _oval(c, p, 6, 0, 76, 48);

    final tail = Path()
      ..moveTo(-28, 0)
      ..lineTo(-58, -26)
      ..lineTo(-50, 0)
      ..lineTo(-58, 26)
      ..close();
    c.drawPath(tail, p);

    final fin = Path()
      ..moveTo(0, -22)
      ..lineTo(10, -44)
      ..lineTo(24, -18)
      ..close();
    c.drawPath(fin, p);
  }

  // Domed shell, head poking out, two feet.
  void _turtle(Canvas c, Paint p) {
    _oval(c, p, 34, 4, 28, 24);
    _oval(c, p, -30, 26, 22, 14, -0.3);
    _oval(c, p, 22, 30, 22, 14, 0.3);

    final shell = Path()
      ..moveTo(-44, 16)
      ..quadraticBezierTo(-44, -40, 0, -40)
      ..quadraticBezierTo(44, -40, 44, 16)
      ..close();
    c.drawPath(shell, p);
  }

  @override
  bool shouldRepaint(covariant _PetSilhouettePainter oldDelegate) => oldDelegate.kind != kind;
}
