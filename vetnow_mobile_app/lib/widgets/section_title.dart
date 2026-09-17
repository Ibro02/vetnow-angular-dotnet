import 'package:flutter/material.dart';

import '../config/theme.dart';

/// A heading that starts a block of content — "My pets", "Meet the team",
/// "All services".
///
/// Two jobs. The obvious one is the header flag: TalkBack and VoiceOver
/// both let someone jump heading to heading instead of swiping through
/// every row, and a screen with no headers offers them nothing to jump
/// between — on the clinic page that is roughly forty swipes to reach the
/// service list.
///
/// The less obvious one is that section headings look the same
/// everywhere. They did not: with the colour left to be inherited, the
/// same widget rendered dark on one screen and mid-grey on the next,
/// depending on whatever DefaultTextStyle happened to be in scope. Two
/// headings a thumb-scroll apart on the clinic page were visibly
/// different weights of the same thing.
class SectionTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;

  /// Overrides the default. Needed on a dark hero, where the page's own
  /// text colour would disappear.
  final Color? color;

  /// Ellipsises past this. A heading sharing a row with an action is the
  /// place this matters: a longer translation or a doubled text scale
  /// pushes the button off the edge, and the overflow stripes are the
  /// first thing anyone notices about a screen.
  final int maxLines;

  /// Draws a short brand-gradient rule beneath the title.
  ///
  /// For the top-level sections of a long page — the clinic profile runs
  /// to four screens of scrolling — where it gives the eye somewhere to
  /// land. The same device as the gold rule under the Explore headline,
  /// so it reads as part of the same app rather than as decoration
  /// invented for one screen. Off by default: on a short page it is
  /// noise.
  final bool accent;

  const SectionTitle(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.maxLines = 1,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = Semantics(
      header: true,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? AppColors.text,
        ),
      ),
    );

    if (!accent) return title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        const SizedBox(height: 7),
        Container(
          height: 3,
          width: 28,
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ],
    );
  }
}
