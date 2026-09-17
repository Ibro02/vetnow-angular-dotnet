import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Closes a list.
///
/// A short list on a tall phone dissolves into an empty half-screen, and
/// an empty half-screen is ambiguous: it looks the same whether you have
/// reached the end or something is still loading below. A quiet mark
/// says which — and it is the difference between a page that ends and a
/// page that just stops.
///
/// Deliberately small and unclickable: the paw is the app's own mark,
/// which is what stops it reading as a stray dot. Shown only when there
/// is something above it — under an empty state it would be saying
/// "that's all" about nothing.
class ListEnd extends StatelessWidget {
  const ListEnd({super.key});

  /// Short and fixed. An earlier version used Expanded with a maxWidth
  /// constraint, which does nothing: Expanded hands down a tight width
  /// and a Container's own constraints cannot loosen it, so the rules ran
  /// the full width of the screen and the mark read as a divider between
  /// two sections rather than as the end of one.
  static const double _ruleWidth = 40;

  @override
  Widget build(BuildContext context) {
    final rule = Container(
      height: 1,
      width: _ruleWidth,
      color: AppColors.border.withValues(alpha: 0.7),
    );

    // Excluded rather than labelled: "end of list" is something a screen
    // reader already conveys by running out of things to read.
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s6, bottom: AppSpacing.s4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            rule,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
              child: Icon(
                Icons.pets,
                size: 13,
                color: AppColors.textMuted.withValues(alpha: 0.55),
              ),
            ),
            rule,
          ],
        ),
      ),
    );
  }
}
