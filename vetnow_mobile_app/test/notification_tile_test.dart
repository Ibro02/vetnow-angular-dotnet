// Notification rows: the two shapes that screen renders, and the rule
// that separates them — a row only looks like a button when there is
// something to do.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/config/theme.dart';
import 'package:vetnow_mobile/widgets/notification_tile.dart';

Future<void> pumpTile(WidgetTester tester, Widget tile) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: tile))));
  await tester.pump();
}

void main() {
  testWidgets('an actionable row shows its pill and calls back on tap', (tester) async {
    var taps = 0;
    await pumpTile(
      tester,
      NotificationTile(
        icon: Icons.star_rounded,
        iconGradient: AppGradients.gold,
        title: 'Happy Paws Vet Clinic',
        subtitle: 'Danas u 08:30',
        actionLabel: 'Ocijeni',
        onTap: () => taps++,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Happy Paws Vet Clinic'), findsOneWidget);
    expect(find.text('Danas u 08:30'), findsOneWidget);
    expect(find.text('Ocijeni'), findsOneWidget);

    await tester.tap(find.text('Ocijeni'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('an informational row is not tappable and shows its note', (tester) async {
    await pumpTile(
      tester,
      const NotificationTile(
        icon: Icons.event_available_rounded,
        iconGradient: AppGradients.brand,
        title: 'PetCare Animal Hospital',
        subtitle: 'Sutra u 10:00',
        trailingNote: 'Shadow',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Shadow'), findsOneWidget);
    // No InkWell means no ripple and no false affordance.
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a very long clinic name is clipped, not overflowed', (tester) async {
    await pumpTile(
      tester,
      const SizedBox(
        width: 320,
        child: NotificationTile(
          icon: Icons.event_available_rounded,
          iconGradient: AppGradients.brand,
          title: 'Veterinarska stanica sa jako jako dugim imenom koje nikako ne stane',
          subtitle: 'Sutra u 10:00',
          trailingNote: 'Shadow',
        ),
      ),
    );

    // An overflow paints a yellow-and-black bar and throws in debug; this
    // is the row most likely to hit it, since it has three columns.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row with no subtitle still lays out', (tester) async {
    await pumpTile(
      tester,
      const NotificationTile(
        icon: Icons.star_rounded,
        iconGradient: AppGradients.gold,
        title: 'Bez datuma',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the section label carries its count', (tester) async {
    await pumpTile(tester, const NotificationSectionLabel(text: 'Nadolazeći termini', count: 3));
    expect(find.text('Nadolazeći termini'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
