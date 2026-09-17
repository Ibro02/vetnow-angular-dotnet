import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/vet_station.dart';
import '../services/photo_bytes.dart';

/// The coloured block that stands in for a clinic's photo.
///
/// `stationImage` is null for every clinic the backend has, so this used to
/// be the same teal square with the same paw on every card — three clinics
/// that looked like one clinic listed three times. Each clinic now gets a
/// gradient and its own initials, picked from its id so the same clinic
/// always looks the same, on every screen and every launch.
///
/// The gradients are built only from existing brand tokens, so the palette
/// is unchanged — this varies the pairing, not the colours.
class ClinicAvatar extends StatelessWidget {
  final VetStation station;

  /// Diameter of the initials disc. The block itself fills its parent.
  final double discSize;
  final double fontSize;

  /// Rounds the block on its own, for places that aren't already clipping.
  final BorderRadius? borderRadius;

  const ClinicAvatar({
    super.key,
    required this.station,
    this.discSize = 42,
    this.fontSize = 15,
    this.borderRadius,
  });

  static const _palettes = <List<Color>>[
    [AppColors.primaryLight, AppColors.primary],
    [AppColors.accent, AppColors.accentActive],
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.accentHover, AppColors.primaryDark],
    [AppColors.primaryLight, AppColors.accent],
    [AppColors.primaryDark, AppColors.ink],
  ];

  List<Color> get _gradient => _palettes[station.id.abs() % _palettes.length];

  /// First letters of the first two meaningful words: "Happy Paws Vet
  /// Clinic" → "HP". Falls back to one letter, then to nothing (the paw
  /// mark below covers that case).
  String get _initials {
    final words = station.name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-zČĆŽŠĐčćžšđ]').hasMatch(w[0]))
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // A clinic's own picture, when it has one.
    //
    // Every clinic the backend holds today has stationImage null, which
    // is why the generated block below exists at all. But the column is
    // there and an admin panel can fill it, and the day one does the
    // photo should simply appear rather than waiting for somebody to
    // notice the app is still drawing initials over it.
    final photo = decodePhoto(station.stationImage);
    if (photo != null) {
      final image = Image.memory(
        photo,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, _, __) => _generated(),
      );

      return borderRadius == null
          ? image
          : ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return _generated();
  }

  /// The gradient block with the clinic's initials, for a clinic with no
  /// picture of its own — which today is all of them.
  Widget _generated() {
    final initials = _initials;

    final content = Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // The same top-left light as every other branded surface, so the
        // thumbnail is lit rather than flat-filled.
        const Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
        ),
        Center(
          child: Container(
            width: discSize,
            height: discSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: initials.isEmpty
                ? Icon(Icons.pets, color: Colors.white, size: discSize * 0.5)
                : Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );

    // The initials are a stand-in for the clinic's name, which is
    // written out right beside them — announced, they are a cryptic
    // "HP" read before the words it abbreviates.
    if (borderRadius == null) return ExcludeSemantics(child: content);
    return ExcludeSemantics(
      child: ClipRRect(borderRadius: borderRadius!, child: content),
    );
  }
}

/// Shared tag so the clinic block flies from the Explore card into the
/// detail header instead of the two screens cutting to each other.
String clinicHeroTag(int stationId) => 'clinic-avatar-$stationId';
