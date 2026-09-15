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

    testWidgets('it does not restyle the text it replaced', (tester) async {
      await pump(tester, const Center(child: SectionTitle('Nalog')));

      final style = tester.widget<Text>(find.text('Nalog')).style!;
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w700);
      // Left unset on purpose: these headings inherit their colour from
      // the page they sit on.
      expect(style.color, isNull);
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

    testWidgets('an error state is readable, and stays readable in dark mode',
        (tester) async {
      final handle = tester.ensureSemantics();

      await pump(tester, ErrorStateView(onRetry: () {}));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      applyPaletteBrightness(Brightness.dark);
      await pump(tester, ErrorStateView(onRetry: () {}));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      applyPaletteBrightness(Brightness.light);

      handle.dispose();
    });
  });
}
