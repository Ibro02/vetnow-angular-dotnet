import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

/// Re-fetches a screen's data when the app comes back to the foreground
/// after having been away for a while.
///
/// Phones do not close apps, people just switch away from them. A booking
/// screen left open on Monday is still on screen on Thursday, showing
/// Monday's free slots — and the first thing that happens is someone taps
/// a slot that was taken two days ago and gets an error they cannot
/// explain. Appointments has the same problem in reverse: a visit
/// cancelled from the web still shows as booked.
///
/// The threshold is what keeps this from being annoying. Switching to the
/// messages app to copy an address and coming straight back should not
/// wipe the screen and re-fetch; being away since yesterday should.
// Mixed in alongside WidgetsBindingObserver rather than implementing it:
// the observer's own methods stay concrete, so this only has to override
// the one it cares about.
//
//   class _FooState extends State<Foo>
//       with WidgetsBindingObserver, ResumeRefresh<Foo> {
mixin ResumeRefresh<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  /// Away for longer than this and the data on screen is assumed stale.
  ///
  /// Two minutes covers "I went to check something and came back" without
  /// covering "I put my phone in my pocket".
  Duration get staleAfter => const Duration(minutes: 2);

  /// What to re-run. Called on the foreground transition, not on every
  /// lifecycle event.
  Future<void> onResumeRefresh();

  // clock.now() rather than DateTime.now() throughout, so the staleness
  // threshold is testable. A widget test's pump(Duration) moves the
  // framework's clock, not the wall clock, and asserting "nine hours
  // later" against DateTime.now() would silently be asserting "one
  // millisecond later".
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Only the first departure counts. Android fires inactive→paused
        // on the way out and the reverse on the way in; taking the latest
        // would reset the clock and nothing would ever look stale.
        _leftAt ??= clock.now();
        break;

      case AppLifecycleState.resumed:
        final leftAt = _leftAt;
        _leftAt = null;
        if (leftAt == null) break;
        if (clock.now().difference(leftAt) < staleAfter) break;
        // Not awaited: the lifecycle callback must return promptly, and
        // the screen shows its own loading state.
        if (mounted) onResumeRefresh();
        break;

      case AppLifecycleState.inactive:
        // The transient state during a notification shade pull or an
        // incoming call. Not a departure.
        break;
    }
  }
}
