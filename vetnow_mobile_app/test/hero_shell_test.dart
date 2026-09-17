// The shared header surface.
//
// Four screens hang off HeroSurface now, and three of them sit behind a
// login, so a layout mistake here would be invisible until someone signed
// in. These render each header at phone sizes and check the things that
// break quietly: an unbounded constraint, an overflow, or a decorative
// layer that starts swallowing taps.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/widgets/gradient_app_bar.dart';
import 'package:vetnow_mobile/widgets/hero_shell.dart';
import 'package:vetnow_mobile/widgets/section_hero.dart';

Future<void> pump(WidgetTester tester, Widget child, {Size size = const Size(375, 812)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
}

void main() {
  group('HeroSurface', () {
    testWidgets('lays out around its content without unbounded constraints',
        (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            child: HeroSurface(child: Padding(padding: EdgeInsets.all(20), child: Text('Header'))),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('its decoration never swallows a tap meant for the content',
        (tester) async {
      // The rim light and the vignette are painted above the content in the
      // stack. Both have to be IgnorePointer, or the buttons in every
      // header in the app stop responding.
      var taps = 0;
      await pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: HeroSurface(
              background: const ColoredBox(color: Color(0x11FFFFFF)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GlassSurface(
                  circle: true,
                  padding: const EdgeInsets.all(9),
                  onTap: () => taps++,
                  child: const Icon(Icons.notifications_outlined, size: 17),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('the sweep clipper produces a closed path at any width', (tester) async {
      for (final width in [288.0, 375.0, 430.0]) {
        final path = const HeroSweepClipper().getClip(Size(width, 200));
        expect(path.getBounds().isEmpty, isFalse, reason: 'width $width');
        // The centre of the bottom edge is lifted, so a point just below
        // the sweep must fall outside the shape.
        expect(path.contains(Offset(width / 2, 199)), isFalse, reason: 'width $width');
        expect(path.contains(Offset(width / 2, 100)), isTrue, reason: 'width $width');
      }
    });
  });

  group('SectionHero', () {
    Widget hero({String title = 'Moji ljubimci'}) => SectionHero(
          leading: const Icon(Icons.pets),
          title: title,
          subtitle: 'Sve na jednom mjestu',
          chips: const [
            HeroChip(icon: Icons.pets, value: '10', label: 'Ljubimci'),
            HeroChip(icon: Icons.event, value: '2', label: 'Termini'),
          ],
        );

    testWidgets('renders its title, subtitle and chips', (tester) async {
      await pump(tester, Scaffold(body: SingleChildScrollView(child: hero())));

      expect(tester.takeException(), isNull);
      expect(find.text('Moji ljubimci'), findsOneWidget);
      expect(find.text('Sve na jednom mjestu'), findsOneWidget);
      expect(find.byType(HeroChip), findsNWidgets(2));
    });

    testWidgets('a long title is clipped rather than overflowing', (tester) async {
      await pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: hero(title: 'Moji ljubimci i svi njihovi termini kroz historiju'),
          ),
        ),
        size: const Size(288, 640),
      );

      // Three columns of chips on a narrow phone is where this breaks.
      expect(tester.takeException(), isNull);
    });
  });

  group('GradientAppBar', () {
    testWidgets('shows its title and takes the standard bar height', (tester) async {
      await pump(
        tester,
        const Scaffold(
          appBar: GradientAppBar(title: 'Obavještenja'),
          body: SizedBox(),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Obavještenja'), findsOneWidget);
      expect(const GradientAppBar(title: 'x').preferredSize.height, kToolbarHeight);
    });

    testWidgets('actions stay tappable over the painted surface', (tester) async {
      var taps = 0;
      await pump(
        tester,
        Scaffold(
          appBar: GradientAppBar(
            title: 'Obavještenja',
            actions: [
              IconButton(onPressed: () => taps++, icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ),
          body: const SizedBox(),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('GlassSurface', () {
    testWidgets('without onTap it is inert, with onTap it is a button', (tester) async {
      await pump(
        tester,
        const Scaffold(
          body: Center(
            child: GlassSurface(padding: EdgeInsets.all(8), child: Text('Chip')),
          ),
        ),
      );
      expect(find.byType(InkWell), findsNothing);

      var taps = 0;
      await pump(
        tester,
        Scaffold(
          body: Center(
            child: GlassSurface(
              padding: const EdgeInsets.all(8),
              onTap: () => taps++,
              child: const Text('Chip'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Chip'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
