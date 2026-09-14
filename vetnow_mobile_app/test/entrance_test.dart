// The entrance animation: it must always finish, and must never keep a
// timer alive after its item scrolls away.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/widgets/entrance.dart';

/// MaterialApp puts its own FadeTransition and SlideTransition in the tree
/// for route transitions, so every finder here is scoped to the widget
/// under test rather than to the whole app.
Finder inside<T extends Widget>(Type parent) =>
    find.descendant(of: find.byType(parent), matching: find.byType(T));

void main() {
  testWidgets('an item ends fully visible and in place', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Entrance(index: 3, child: Text('Happy Paws'))),
    ));

    await tester.pumpAndSettle();

    final fade = tester.widget<FadeTransition>(inside<FadeTransition>(Entrance));
    expect(fade.opacity.value, 1.0);

    final slide = tester.widget<SlideTransition>(inside<SlideTransition>(Entrance));
    expect(slide.position.value, Offset.zero);
  });

  testWidgets('disposing mid-delay does not throw', (tester) async {
    // A fast scroll disposes an item before its stagger elapses. An
    // earlier version used Future.delayed for the stagger, which left a
    // pending timer behind and forwarded a disposed controller.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Entrance(index: 8, child: Text('Gone soon'))),
    ));
    await tester.pump(const Duration(milliseconds: 20));

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled means no animation wrapper at all', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Entrance(index: 2, enabled: false, child: Text('Instant'))),
    ));
    await tester.pump();

    expect(inside<FadeTransition>(Entrance), findsNothing);
    expect(find.text('Instant'), findsOneWidget);
  });

  testWidgets('the stagger is capped so a long list never stalls', (tester) async {
    // Item 40 must not wait forty steps; without the cap it would sit
    // invisible for nearly two seconds.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Entrance(index: 40, child: Text('Last pet'))),
    ));

    await tester.pumpAndSettle();
    final fade = tester.widget<FadeTransition>(inside<FadeTransition>(Entrance));
    expect(fade.opacity.value, 1.0);
  });

  testWidgets('a pressed card scales down and springs back', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PressableCard(onTap: () => taps++, child: const Text('Card')),
      ),
    ));

    double scale() => tester.widget<AnimatedScale>(inside<AnimatedScale>(PressableCard)).scale;
    expect(scale(), 1.0);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Card')));
    await tester.pump();
    expect(scale(), lessThan(1.0));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), 1.0);
    expect(taps, 1);
  });

  testWidgets('a cancelled press springs back without firing the tap',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PressableCard(onTap: () => taps++, child: const Text('Card')),
      ),
    ));

    final gesture = await tester.startGesture(tester.getCenter(find.text('Card')));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedScale>(inside<AnimatedScale>(PressableCard)).scale, 1.0);
    expect(taps, 0, reason: 'dragging off a card is not a tap');
  });
}
