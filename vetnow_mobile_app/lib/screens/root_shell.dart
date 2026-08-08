import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import 'explore_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';

/// App shell: bottom nav across the three top-level destinations.
/// Explore is always fully usable as a guest; Appointments/Profile stay
/// visible but show an AuthPrompt until the user logs in (see those
/// screens) — nobody gets locked out of the tab bar itself.
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
      body: SafeArea(bottom: false, child: _tabs[_tabIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent50,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search, color: AppColors.accent),
            label: l10n.navExplore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event, color: AppColors.accent),
            label: l10n.navAppointments,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: AppColors.accent),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
