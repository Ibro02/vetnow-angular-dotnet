import 'dart:async';

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/deep_links.dart';
import '../state/auth_state.dart';
import '../state/resume_refresh.dart';
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
        setState(() {
          _tabIndex = Destination.values.indexOf(destination);
          _opened.add(_tabIndex);
        });

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

  static const int _tabCount = 3;

  /// One per tab, so a tab that is already alive can be told it is
  /// being looked at again. See [Revisitable]. The key goes on the
  /// screen itself, not on a wrapper — currentState is null for a
  /// stateless one.
  final List<GlobalKey<State>> _tabKeys =
      List.generate(_tabCount, (_) => GlobalKey<State>());

  Widget _tab(int i) => switch (i) {
        0 => ExploreScreen(key: _tabKeys[0]),
        1 => MyAppointmentsScreen(key: _tabKeys[1], embedded: true),
        _ => ProfileScreen(key: _tabKeys[2], embedded: true),
      };

  /// Tabs that have been opened at least once.
  ///
  /// An IndexedStack keeps every child it is given alive, which is the
  /// point — but it also builds all of them on the first frame, so a
  /// signed-in launch would fire the appointments and profile requests
  /// before anyone had asked to see either. A tab is built the first
  /// time it is opened and kept from then on.
  final Set<int> _opened = {0};

  /// Switches to [i], and tells a tab that was already built that it
  /// is on screen again.
  ///
  /// A tab opened for the first time builds and fetches by itself; one
  /// that has been alive in the stack all along would otherwise still
  /// be showing whatever it last loaded — book a visit from Explore,
  /// tap Termini, and the new appointment would not be in the list.
  void _openTab(int i) {
    final alreadyBuilt = _opened.contains(i);
    setState(() {
      _tabIndex = i;
      _opened.add(i);
    });
    if (!alreadyBuilt) return;

    final Object? state = _tabKeys[i].currentState;
    if (state is Revisitable) unawaited(state.onRevisit());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      // Back goes to Explore before it leaves the app.
      //
      // On Android, back from the Profile tab closed VetNow outright,
      // which is not what the gesture means anywhere else on the
      // phone. From Explore it still exits, because there is nowhere
      // further back to go.
      canPop: _tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _tabIndex = 0);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgSoft,
        extendBody: true,
        // IndexedStack, not _tabs[_tabIndex]: swapping the child
        // outright replaced the element, so every tab switch threw away
        // the screen's State. A search you had typed on Explore was
        // gone, the scroll position with it, and the clinic list was
        // fetched again from the top — once per switch, on mobile data.
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tabIndex,
            children: [
              for (var i = 0; i < _tabCount; i++)
                if (_opened.contains(i)) _tab(i) else const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: LuxuryNavBar(
          selectedIndex: _tabIndex,
          onSelect: _openTab,
          items: [
            NavItem(icon: Icons.search_outlined, selectedIcon: Icons.search_rounded, label: l10n.navExplore),
            NavItem(icon: Icons.event_outlined, selectedIcon: Icons.event_rounded, label: l10n.navAppointments),
            NavItem(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: l10n.navProfile),
          ],
        ),
      ),
    );
  }
}
