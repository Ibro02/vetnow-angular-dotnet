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

  const SectionTitle(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
    );
  }
}
