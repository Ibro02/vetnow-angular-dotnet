import 'package:flutter/material.dart';
import '../config/theme.dart';

/// The bar on every secondary screen — Booking, Notifications, Edit
/// profile, Reschedule, Verify.
///
/// It carries the same ink gradient as the main headers, and now the
/// same treatment: the top-left sheen every branded surface in the app
/// has, and a gold hairline along the bottom edge.
///
/// No swept curve here, deliberately. The main headers can afford one
/// because content flows under them; an app bar sits against the top of
/// a scroll view, and a curved bottom would leave a sliver of the page
/// showing through at both corners on every screen.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GradientAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 0.1,
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      // The bar paints its own gradient, so Material must not tint it
      // again when content scrolls underneath.
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      flexibleSpace: const _BarSurface(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BarSurface extends StatelessWidget {
  const _BarSurface();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.ink)),
          const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
          // A straight version of the rim light on the main headers:
          // brightest in the middle, gone by the edges, so the bar ends
          // on a line of light rather than a hard cut.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 1.4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x00E8A73C), Color(0x99E8A73C), Color(0x00E8A73C)],
                  stops: [0.08, 0.5, 0.92],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
