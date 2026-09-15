import 'package:flutter/material.dart';

import '../config/theme.dart';

/// The disc that stands in for a person's photo.
///
/// Nobody in this system has one — not the vets, not the nurses, not the
/// people who leave reviews — so every one of them wore the same grey
/// person glyph on the same gradient. Three vets on a clinic page read as
/// one vet listed three times, and a column of reviews read as one person
/// writing all of them.
///
/// Initials on a gradient picked from the person's name, so the same
/// person looks the same everywhere and on every launch, and two people
/// side by side look like two people. The same treatment the clinics and
/// the pets already have, built from the same brand tokens — this varies
/// the pairing, not the palette.
class PersonAvatar extends StatelessWidget {
  final String name;
  final double size;

  /// Overrides the name-derived gradient. For the one place a person's
  /// identity is already established by context — their own profile
  /// header — where matching the page matters more than telling them
  /// apart from anyone else.
  final List<Color>? colors;

  const PersonAvatar({
    super.key,
    required this.name,
    this.size = 52,
    this.colors,
  });

  static const _palettes = <List<Color>>[
    [AppColors.primary, AppColors.primaryDark],
    [AppColors.accent, AppColors.accentActive],
    [AppColors.primaryLight, AppColors.primary],
    [AppColors.accentHover, AppColors.primaryDark],
    [AppColors.primaryLight, AppColors.accent],
    [AppColors.primaryDark, AppColors.ink],
  ];

  /// Keyed on the name rather than on an id, because the same widget has
  /// to colour a review whose author has no id attached.
  ///
  /// Hashed over the *same* words the initials come from, not the raw
  /// string. One record says "Dr. Amina Hodzic" and the next says
  /// "Amina Hodzic"; hashing the raw text gave the same person two
  /// different colours on two screens, which is the failure this
  /// widget exists to prevent rather than one to introduce.
  int get _seed {
    var hash = 0;
    for (final unit in _significantWords.join(' ').toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x1fffffff;
    }
    return hash;
  }

  List<Color> get _gradient =>
      colors ?? _palettes[_seed % _palettes.length];

  /// The name with titles and punctuation-only fragments removed.
  ///
  /// Titles are dropped because every vet on a clinic page starts with
  /// "Dr.": keeping them would give half the team the same initial and
  /// undo the point of the widget.
  List<String> get _significantWords {
    const titles = {'dr', 'dr.', 'mr', 'mr.', 'prof', 'prof.', 'vet', 'vet.'};

    return name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .where((w) => !titles.contains(w.toLowerCase()))
        .where((w) => RegExp(r'[A-Za-zČĆŽŠĐčćžšđ]').hasMatch(w[0]))
        .toList();
  }

  /// "Dr. Amina Hodžić" → "AH".
  String get _initials {
    final words = _significantWords;
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _gradient.last.withValues(alpha: 0.30),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The same top-left light as every other branded surface, so
          // the disc is lit rather than flat-filled.
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.inkSheen,
            ),
          ),
          Center(
            child: initials.isEmpty
                ? Icon(Icons.person, color: Colors.white, size: size * 0.46)
                : Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
