import 'package:flutter/material.dart';

/// A heading that starts a block of content — "My pets", "Meet the team",
/// "All services".
///
/// Visually this is the Text it replaces, unchanged. What it adds is the
/// header flag: TalkBack and VoiceOver both let someone jump heading to
/// heading instead of swiping through every row, and a screen with no
/// headers offers them nothing to jump between — on the clinic page that
/// is roughly forty swipes to reach the service list.
///
/// [color] stays optional on purpose. Most of these headings inherit
/// their colour from the surrounding DefaultTextStyle today, and hard
/// coding one here would quietly restyle them.
class SectionTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  /// Ellipsises past this. A heading sharing a row with an action is the
  /// place this matters: a longer translation or a doubled text scale
  /// pushes the button off the edge, and the overflow stripes are the
  /// first thing anyone notices about a screen.
  final int maxLines;

  const SectionTitle(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
    );
  }
}
