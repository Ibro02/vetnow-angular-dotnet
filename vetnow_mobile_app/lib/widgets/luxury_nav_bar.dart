import 'package:flutter/material.dart';
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
          gradient: const LinearGradient(
            colors: [AppColors.ink, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(color: AppColors.ink.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
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
                        colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 1),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (i) {
                    final selected = i == selectedIndex;
                    final item = items[i];
                    return Expanded(
                      child: InkWell(
                        onTap: () => onSelect(i),
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
