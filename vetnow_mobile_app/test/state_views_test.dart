// Error and empty states, and whether the app survives a large system
// font.
//
// The two states are the point of the first group: a failed request and
// an empty list are different things, and before this they looked the
// same on two screens — Appointments literally passed the error through
// as its empty-state text, so "you have nothing booked" and "we could
// not ask" were the same sentence with no way to retry either.
//
// The text-scale group exists because someone with large text set on
// their phone is exactly the person who will never file a bug about it.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/widgets/hero_shell.dart';
import 'package:vetnow_mobile/widgets/section_hero.dart';
import 'package:vetnow_mobile/widgets/state_views.dart';

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(375, 812),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('bs'),
      supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: widget!,
      ),
      home: child,
    ),
  );
  await tester.pump();
}

void main() {
  group('ErrorStateView', () {
    testWidgets('says something went wrong and offers a way back',
        (tester) async {
      var retries = 0;
      await pump(tester, Scaffold(body: ErrorStateView(onRetry: () => retries++)));

      expect(find.text('Nešto je pošlo po zlu'), findsOneWidget);
      expect(find.text('Pokušaj ponovo'), findsOneWidget);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pump();
      expect(retries, 1);
    });

    testWidgets('shows the server\'s own wording when there is one',
        (tester) async {
      await pump(
        tester,
        Scaffold(body: ErrorStateView(message: 'Termin je već zauzet.', onRetry: () {})),
      );
      expect(find.text('Termin je već zauzet.'), findsOneWidget);
    });

    testWidgets('the network sentinel is never shown raw', (tester) async {
      // Screens set _error = 'network' when there is no server at all.
      // That is a flag, not a sentence anyone should read.
      await pump(tester, Scaffold(body: ErrorStateView(message: 'network', onRetry: () {})));
      expect(find.text('network'), findsNothing);
    });

    testWidgets('stays pull-to-refreshable', (tester) async {
      // This is the screen people tug at when the signal comes back, so
      // it has to be a scrollable that always scrolls.
      await pump(tester, Scaffold(body: ErrorStateView(onRetry: () {})));

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<AlwaysScrollableScrollPhysics>());
    });
  });

  group('EmptyStateView', () {
    testWidgets('reads as empty, not as broken', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: EmptyStateView(icon: Icons.event_busy_outlined, text: 'Nema nadolazećih termina.'),
        ),
      );

      expect(find.text('Nema nadolazećih termina.'), findsOneWidget);
      // No alarm, and nothing to retry — nothing failed.
      expect(find.text('Pokušaj ponovo'), findsNothing);
      expect(find.text('Nešto je pošlo po zlu'), findsNothing);
    });
  });

  group('large system font', () {
    Widget hero() => const SectionHero(
          leading: Icon(Icons.pets),
          title: 'Moji ljubimci',
          subtitle: 'Sve na jednom mjestu',
          chips: [
            HeroChip(icon: Icons.pets, value: '10', label: 'Ljubimci'),
            HeroChip(icon: Icons.event, value: '2', label: 'Termini'),
          ],
        );

    testWidgets('the header survives 1.5x text', (tester) async {
      await pump(
        tester,
        Scaffold(body: SingleChildScrollView(child: hero())),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the header survives 2x text on a narrow phone', (tester) async {
      // The accessibility setting people actually use, on the smallest
      // screen worth supporting.
      await pump(
        tester,
        Scaffold(body: SingleChildScrollView(child: hero())),
        size: const Size(288, 640),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the error state survives 2x text', (tester) async {
      await pump(
        tester,
        Scaffold(body: ErrorStateView(onRetry: () {})),
        size: const Size(288, 640),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('screen readers', () {
    testWidgets('an icon-only glass button announces what it does',
        (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        Scaffold(
          body: Center(
            child: GlassSurface(
              circle: true,
              padding: const EdgeInsets.all(9),
              semanticLabel: 'Obavještenja',
              onTap: () {},
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ),
      );

      // Without the label this button is silent to anyone who cannot see
      // the icon — which is the entire point of an icon-only control.
      expect(
        find.bySemanticsLabel('Obavještenja'),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}
