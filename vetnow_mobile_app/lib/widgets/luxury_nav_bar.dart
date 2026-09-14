import 'package:flutter/material.dart';
import '../config/haptics.dart';
import '../config/theme.dart';

class NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// A floating "pill" navigation bar instead of the stock Material
/// bottom bar — dark ink→primaryDark gradient, a soft glow, and a
/// gold-tinted capsule that glides behind whichever tab is selected.
/// This is the single most visible spot in the app (present on every
/// screen), so it carries a lot of the "this isn't a template" feel.
class LuxuryNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<NavItem> items;
  final ValueChanged<int> onSelect;

  const LuxuryNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Force full transparency around the pill explicitly — Scaffold
    // sometimes paints its own Material behind bottomNavigationBar
    // (theme-dependent), which is exactly the "beige box" this widget
    // exists to avoid.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset > 0 ? bottomInset - 4 : 14),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: AppGradients.ink,
          borderRadius: BorderRadius.circular(AppRadius.full),
          // Hairline of light along the top edge — the pill stops looking
          // like a cut-out and starts looking like a raised object.
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.38),
              blurRadius: 30,
              offset: const Offset(0, 14),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                // Same top-left light as the heroes, so the nav bar and the
                // hero above it look carved from one material.
                const Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: slotWidth * selectedIndex + 6,
                  top: 6,
                  bottom: 6,
                  width: slotWidth - 12,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.07)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.38), width: 1),
                      // Faint warm halo so the active tab glows rather than
                      // merely being outlined.
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          blurRadius: 14,
                          spreadRadius: -3,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (i) {
                    final selected = i == selectedIndex;
                    final item = items[i];
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!selected) Haptics.select();
                          onSelect(i);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.55),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                duration: const Duration(milliseconds: 250),
                                scale: selected ? 1.12 : 1.0,
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  selected ? item.selectedIcon : item.icon,
                                  size: 21,
                                  color: selected ? AppColors.gold : Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(item.label),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}
