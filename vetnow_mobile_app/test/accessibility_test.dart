// What a screen reader actually hears.
//
// These are regression tests for things that are invisible when you look
// at the app and obvious the moment you turn TalkBack on: icon buttons
// with no name, a tab bar that never says which tab you are on, a
// loading screen that is silent because placeholders contain no text, and
// labels announced twice because they were set in two places at once.
//
// They also cover the mechanical guidelines — Material asks for a 48dp
// minimum tap target and enough contrast to read — via Flutter's own
// accessibility guideline matchers, which is the cheapest way to keep a
// later redesign from quietly shrinking a control below the thumb.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/config/theme.dart';
import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/state/theme_state.dart';
import 'package:vetnow_mobile/widgets/hero_shell.dart';
import 'package:vetnow_mobile/widgets/luxury_nav_bar.dart';
import 'package:vetnow_mobile/widgets/pet_avatar.dart';
import 'package:vetnow_mobile/widgets/section_title.dart';
import 'package:vetnow_mobile/widgets/skeleton.dart';
import 'package:vetnow_mobile/widgets/state_views.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('bs'),
      supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.current,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

/// Every label in the semantics tree, in traversal order.
List<String> labels(WidgetTester tester) {
  final out = <String>[];
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty) out.add(node.label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(tester.getSemantics(find.byType(MaterialApp)));
  return out;
}

void main() {
  group('icon-only controls', () {
    testWidgets('a glass icon button is announced by name, not as an icon',
        (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        Center(
          child: GlassSurface(
            circle: true,
            semanticLabel: 'Obavijesti',
            onTap: () {},
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.notifications_outlined, size: 18),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Obavijesti'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
        'its tap target clears the 46pt minimum even though the painted '
        'circle is smaller', (tester) async {
      await pump(
        tester,
        Center(
          child: GlassSurface(
            circle: true,
            semanticLabel: 'Jezik',
            onTap: () {},
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.translate_rounded, size: 16),
          ),
        ),
      );

      final size = tester.getSize(find.byType(GlassSurface));
      expect(size.width, greaterThanOrEqualTo(46));
      expect(size.height, greaterThanOrEqualTo(46));
    });

    testWidgets(
        'a glass surface with no tap handler is decoration, not a silent '
        'button', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        const Center(
          child: GlassSurface(
            padding: EdgeInsets.all(8),
            child: Text('4.8'),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('4.8')),
        isNot(matchesSemantics(isButton: true)),
      );
      handle.dispose();
    });
  });

  group('bottom navigation', () {
    Future<void> pumpNav(WidgetTester tester, int selected) => pump(
          tester,
          Align(
            alignment: Alignment.bottomCenter,
            child: LuxuryNavBar(
              selectedIndex: selected,
              onSelect: (_) {},
              items: const [
                NavItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search_rounded,
                  label: 'Istrazi',
                ),
                NavItem(
                  icon: Icons.event_outlined,
                  selectedIcon: Icons.event_rounded,
                  label: 'Termini',
                ),
                NavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person_rounded,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );

    testWidgets('each tab says it is a tab, and which one is active',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, 1);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Termini')),
        matchesSemantics(
          label: 'Termini',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Istrazi')),
        matchesSemantics(
          label: 'Istrazi',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets(
        'a tab is announced once, not once for the label and once for the '
        'icon underneath', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, 0);

      expect(labels(tester).where((l) => l == 'Istrazi'), hasLength(1));
      handle.dispose();
    });
  });

  group('loading and failure', () {
    testWidgets('a wall of placeholders announces itself as loading',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        SkeletonList(count: 4, itemBuilder: () => const ClinicCardSkeleton()),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('bs'));
      expect(find.bySemanticsLabel(l10n.a11yLoading), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the shimmer boxes underneath stay out of the reading order',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        SkeletonList(count: 3, itemBuilder: () => const ReviewSkeleton()),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('bs'));
      expect(labels(tester), [l10n.a11yLoading]);
      handle.dispose();
    });

    testWidgets(
        'an error is a live region, so the swap from loading to failed is '
        'spoken', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, ErrorStateView(onRetry: () {}));

      final l10n = await AppLocalizations.delegate.load(const Locale('bs'));

      // Title and explanation come out as one utterance, flagged live so
      // it is spoken when it replaces the skeletons — no navigation
      // happens here, so nothing else would prompt the announcement.
      final node = tester.getSemantics(find.text(l10n.somethingWentWrong));
      expect(node.label, startsWith(l10n.somethingWentWrong));
      expect(node.label, contains(l10n.networkError));
      expect(node.flagsCollection.isLiveRegion, isTrue);

      // The retry button stays a separate stop, not swallowed into the
      // announcement — it is the only thing on screen to act on.
      expect(
        tester.getSemantics(find.text(l10n.retry)).flagsCollection.isButton,
        isTrue,
      );

      handle.dispose();
    });
  });

  group('headings', () {
    testWidgets('a section title is a heading a screen reader can jump to',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const Center(child: SectionTitle('Moji ljubimci')));

      expect(
        tester.getSemantics(find.text('Moji ljubimci')),
        matchesSemantics(label: 'Moji ljubimci', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('every section heading looks the same', (tester) async {
      // The colour used to be left to be inherited, which meant the same
      // widget rendered dark on one screen and mid-grey on the next,
      // depending on the DefaultTextStyle in scope. Two headings a
      // thumb-scroll apart on the clinic page were visibly different.
      await pump(tester, const Center(child: SectionTitle('Nalog')));

      final style = tester.widget<Text>(find.text('Nalog')).style!;
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, AppColors.text);
    });

    testWidgets('a heading on a dark hero can still override the colour',
        (tester) async {
      await pump(
        tester,
        const Center(child: SectionTitle('Na heroju', color: Colors.white)),
      );

      expect(tester.widget<Text>(find.text('Na heroju')).style!.color,
          Colors.white);
    });

    testWidgets('the accent rule is decoration, not something to read',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const Center(child: SectionTitle('Sve usluge', accent: true)),
      );

      // One heading, one label — the rule underneath adds nothing to the
      // reading order.
      expect(labels(tester), ['Sve usluge']);
      expect(
        tester.getSemantics(find.text('Sve usluge')),
        matchesSemantics(label: 'Sve usluge', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('decoration stays out of the way', () {
    testWidgets('a pet portrait is not announced as an unlabelled image',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PetAvatar(species: 'Dog', seed: 1),
              Text('Rex'),
            ],
          ),
        ),
      );

      expect(labels(tester), ['Rex']);
      handle.dispose();
    });
  });

  group('platform guidelines', () {
    testWidgets('the nav bar meets the Android and iOS tap-target minimums',
        (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: LuxuryNavBar(
            selectedIndex: 0,
            onSelect: (_) {},
            items: const [
              NavItem(
                icon: Icons.search_outlined,
                selectedIcon: Icons.search_rounded,
                label: 'Istrazi',
              ),
              NavItem(
                icon: Icons.event_outlined,
                selectedIcon: Icons.event_rounded,
                label: 'Termini',
              ),
            ],
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('an error state is readable', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(tester, ErrorStateView(onRetry: () {}));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });

    test('text clears WCAG AA against every surface it sits on', () {
      // Deliberately not textContrastGuideline, and the reason is worth
      // writing down.
      //
      // That guideline samples the pixels inside a semantics node and
      // infers which of them are the text. On a filled button it infers
      // wrong: it compares the button's own fill against the page behind
      // it, and never looks at the label. So it passed, happily, on a
      // secondary button that hard-coded a white fill — which in dark
      // mode was near-white text on a white slab, unreadable, and
      // scoring well precisely because the white fill contrasted nicely
      // with the dark page around it. The bug was found on a phone, by
      // eye, with the test suite green.
      //
      // These pairs are therefore checked directly: the colour the text
      // is painted in, against the colour actually behind it.
      for (final brightness in Brightness.values) {
        applyPaletteBrightness(brightness);

        final pairs = <String, List<Color>>{
          'body text on the page': [AppColors.text, AppColors.bg],
          'body text on the soft ground': [AppColors.text, AppColors.bgSoft],
          'body text on a card': [AppColors.text, AppColors.surface],
          'a quiet button label': [AppColors.text, AppColors.bgMuted],
          'secondary text on a card': [AppColors.textSecondary, AppColors.surface],
          'secondary text on the page': [AppColors.textSecondary, AppColors.bg],
          'white on a hero': [Colors.white, AppColors.ink],
        };

        pairs.forEach((what, pair) {
          final ratio = contrastRatio(pair[0], pair[1]);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$what, ${brightness.name}: ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }

      applyPaletteBrightness(Brightness.light);
    });

    test('the brand fills are recorded, not silently assumed to be fine', () {
      // White on the mint primary measures 2.07:1, which misses AA (4.5)
      // and misses even the large-text bar (3.0). Raising it means making
      // the primary action a deeper green, which changes how every screen
      // in the app looks — an owner's call, not a test's. Pinned here so
      // the number is visible and a change to it is deliberate rather
      // than accidental.
      expect(contrastRatio(Colors.white, AppColors.accent), closeTo(2.07, 0.05));
      expect(contrastRatio(Colors.white, AppColors.primary), closeTo(2.58, 0.05));
    });
  });

  group('the floating pill and the system inset', () {
    // Found on a phone, as a red flash lasting one frame.
    //
    // The pill tucks 4 into the gesture bar, so its padding was
    // `padding.bottom - 4`. At rest that is fine: a gesture bar is 24 to
    // 48. But focusing a text field hands the bottom of the screen to
    // the keyboard, padding.bottom animates to zero, and every frame it
    // spends between 4 and 0 made that subtraction negative.
    // RenderPadding asserts on a negative inset, so the entire screen
    // became Flutter's red error panel until the next frame.
    for (final inset in [0.0, 0.5, 2.0, 3.9, 4.0, 24.0, 48.0]) {
      testWidgets('lays out with a system inset of $inset', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(padding: EdgeInsets.only(bottom: inset)),
              child: Scaffold(
                bottomNavigationBar: LuxuryNavBar(
                  selectedIndex: 0,
                  onSelect: (_) {},
                  items: const [
                    NavItem(
                      icon: Icons.search_outlined,
                      selectedIcon: Icons.search_rounded,
                      label: 'Istraži',
                    ),
                    NavItem(
                      icon: Icons.event_outlined,
                      selectedIcon: Icons.event_rounded,
                      label: 'Termini',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives the inset animating away under a keyboard',
        (tester) async {
      // The real sequence, frame by frame, rather than a set of resting
      // values: 48 down to 0 the way Android reports it while the
      // keyboard slides up.
      for (final inset in [48.0, 30.0, 12.0, 3.5, 1.0, 0.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(padding: EdgeInsets.only(bottom: inset)),
              child: Scaffold(
                bottomNavigationBar: LuxuryNavBar(
                  selectedIndex: 0,
                  onSelect: (_) {},
                  items: const [
                    NavItem(
                      icon: Icons.search_outlined,
                      selectedIcon: Icons.search_rounded,
                      label: 'Istraži',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'inset $inset');
      }
    });
  });
}

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) {
    v /= 255;
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r * 255) +
      0.7152 * channel(c.g * 255) +
      0.0722 * channel(c.b * 255);
}

/// WCAG 2.1 contrast ratio between two opaque colours, 1..21.
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}
