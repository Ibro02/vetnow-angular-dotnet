import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/deep_links.dart';
import '../state/auth_state.dart';
import '../services/vet_station_api_service.dart';
import '../widgets/luxury_nav_bar.dart';
import 'explore_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';
import 'vet_station_detail_screen.dart';

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

  /// The link already acted on, so a rebuild does not open the same
  /// clinic a second time.
  DeepLink? _handled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Signing in lands on Explore, wherever it was started from.
    //
    // The login screen is a route over the current tab, so someone who
    // tapped "sign in" from Profile came back to Profile, and someone
    // who came through the booking gate came back to a clinic page. Both
    // are a dead end: the thing to do after signing in is to look at
    // clinics.
    final auth = AuthScope.of(context);
    if (auth.justSignedIn) {
      auth.justSignedIn = false;
      // Post-frame because this runs during a build, and because the
      // login route is usually still mid-pop at this point.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tabIndex = 0);
      });
    }

    final pending = DeepLinkScope.of(context)?.value;
    if (pending == null || pending == _handled) return;
    _handled = pending;

    // After the frame: this runs during a build, and both switching tabs
    // and pushing a route are things that cannot happen mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(pending));
  }

  Future<void> _follow(DeepLink link) async {
    switch (link) {
      case TabLink(:final destination):
        if (!mounted) return;
        setState(() => _tabIndex = Destination.values.indexOf(destination));

      case ClinicLink(:final id):
        // Explore first, so backing out of the clinic page lands
        // somewhere sensible rather than on an empty stack.
        if (mounted) setState(() => _tabIndex = 0);

        final station = await VetStationApiService.getById(id);
        if (!mounted || station == null) return;

        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VetStationDetailScreen(station: station)),
        );
    }
  }

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
