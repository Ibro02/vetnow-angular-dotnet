// Coming back to a screen that has been sitting in the background.
//
// The bug this prevents is quiet: a phone does not close apps, so a
// booking screen opened on Monday is still on screen on Thursday showing
// Monday's free slots. The first thing that happens is a tap on a slot
// that was taken two days ago, and an error nobody can explain.
//
// The other half is not being annoying about it — switching away to copy
// an address and coming straight back must not wipe the screen.

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/state/resume_refresh.dart';

class _Probe extends StatefulWidget {
  final Duration staleAfter;
  final VoidCallback onRefresh;

  const _Probe({
    required this.onRefresh,
    this.staleAfter = const Duration(minutes: 2),
  });

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe>
    with WidgetsBindingObserver, ResumeRefresh<_Probe> {
  @override
  Duration get staleAfter => widget.staleAfter;

  @override
  Future<void> onResumeRefresh() async => widget.onRefresh();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  // A clock the test moves by hand. pump(Duration) advances the
  // framework's timers but not the wall clock, so asserting "nine hours
  // later" against DateTime.now() would really be asserting "one
  // millisecond later" — and every threshold test would pass for the
  // wrong reason.
  late DateTime now;
  late int refreshes;

  void advance(Duration by) => now = now.add(by);

  /// Runs [body] with the hand-wound clock in force.
  Future<void> withTestClock(Future<void> Function() body) {
    now = DateTime(2026, 9, 15, 9);
    refreshes = 0;
    return withClock(Clock(() => now), body);
  }

  Future<void> pumpProbe(WidgetTester tester, {Duration? staleAfter}) {
    return tester.pumpWidget(MaterialApp(
      home: _Probe(
        onRefresh: () => refreshes++,
        staleAfter: staleAfter ?? const Duration(minutes: 2),
      ),
    ));
  }

  /// The sequence Android actually sends on the way out and back.
  Future<void> leaveAndReturn(WidgetTester tester, {required Duration away}) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    advance(away);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  testWidgets('a long absence refreshes the screen', (tester) async {
    await withTestClock(() async {
      await pumpProbe(tester);
      await leaveAndReturn(tester, away: const Duration(hours: 9));

      expect(refreshes, 1);
    });
  });

  testWidgets('a quick trip to another app does not', (tester) async {
    await withTestClock(() async {
      await pumpProbe(tester);
      await leaveAndReturn(tester, away: const Duration(seconds: 20));

      expect(refreshes, 0);
    });
  });

  testWidgets('the threshold is a boundary, not a suggestion', (tester) async {
    await withTestClock(() async {
      await pumpProbe(tester, staleAfter: const Duration(minutes: 2));

      await leaveAndReturn(tester, away: const Duration(minutes: 1, seconds: 59));
      expect(refreshes, 0);

      await leaveAndReturn(tester, away: const Duration(minutes: 2));
      expect(refreshes, 1);
    });
  });

  testWidgets('pulling down the notification shade is not leaving',
      (tester) async {
    await withTestClock(() async {
      await pumpProbe(tester);

      // inactive without paused: an incoming call banner, the shade, the
      // app switcher opened and dismissed. The app never left.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      advance(const Duration(hours: 2));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(refreshes, 0);
    });
  });

  testWidgets('a second background event does not restart the clock',
      (tester) async {
    await withTestClock(() async {
      await pumpProbe(tester, staleAfter: const Duration(minutes: 45));

      // Android can send more than one background-family event while the
      // app is away — paused on the way out, hidden later. Taking the
      // latest as the departure time would keep pushing the clock
      // forward, and an app left overnight would come back looking fresh.
      //
      // Measured from the first event this is an hour away and refreshes.
      // Measured from the second it is half an hour and would not.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      advance(const Duration(minutes: 30));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      advance(const Duration(minutes: 30));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(refreshes, 1);
    });
  });

  testWidgets('returning twice refreshes twice, not once', (tester) async {
    await withTestClock(() async {
      await pumpProbe(tester);

      await leaveAndReturn(tester, away: const Duration(hours: 1));
      await leaveAndReturn(tester, away: const Duration(hours: 1));

      expect(refreshes, 2);
    });
  });

  testWidgets('a resume with no departure behind it does nothing',
      (tester) async {
    await withTestClock(() async {
      // The first resumed event after launch has no paused before it.
      // Refreshing here would double the work on every cold start, on top
      // of the load the screen already runs in initState.
      await pumpProbe(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(refreshes, 0);
    });
  });

  testWidgets('a screen navigated away from stops listening', (tester) async {
    await withTestClock(() async {
      await pumpProbe(tester);

      // Gone from the tree. If dispose did not remove the observer this
      // would refresh a dead State, which throws.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      await leaveAndReturn(tester, away: const Duration(hours: 1));

      expect(refreshes, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
