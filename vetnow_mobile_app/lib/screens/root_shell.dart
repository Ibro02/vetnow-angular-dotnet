import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/luxury_nav_bar.dart';
import 'explore_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';

/// App shell: bottom nav across the three top-level destinations.
/// Explore is always fully usable as a guest; Appointments/Profile stay
/// visible but show an AuthPrompt until the user logs in (see those
/// screens) — nobody gets locked out of the tab bar itself.
///
/// The nav bar itself is a custom floating "pill" (see LuxuryNavBar)
/// instead of the stock Material bottom bar every other app ships
/// with — it's the one UI element present on every single screen, so
/// it carries an outsized share of the app's premium feel.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tabIndex = 0;

  final List<Widget> _tabs = const [
    ExploreScreen(),
    MyAppointmentsScreen(embedded: true),
    ProfileScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      extendBody: true,
      body: SafeArea(bottom: false, child: _tabs[_tabIndex]),
      bottomNavigationBar: LuxuryNavBar(
        selectedIndex: _tabIndex,
        onSelect: (i) => setState(() => _tabIndex = i),
        items: [
          NavItem(icon: Icons.search_outlined, selectedIcon: Icons.search_rounded, label: l10n.navExplore),
          NavItem(icon: Icons.event_outlined, selectedIcon: Icons.event_rounded, label: l10n.navAppointments),
          NavItem(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: l10n.navProfile),
        ],
      ),
    );
  }
}
