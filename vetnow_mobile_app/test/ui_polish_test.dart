// Tests for the presentation widgets added in the UI pass.
//
// The skeleton cases exist because the first version of ClinicCardSkeleton
// threw an infinite-constraint layout error the moment it was rendered —
// a whole screen of red, caught only because the app's own smoke test
// happened to build it. Rendering each skeleton on its own is the cheap
// way to keep that from coming back.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/models/vet_station.dart';
import 'package:vetnow_mobile/widgets/clinic_avatar.dart';
import 'package:vetnow_mobile/widgets/skeleton.dart';

VetStation station({int id = 1, String name = 'Happy Paws Vet Clinic'}) => VetStation(
      id: id,
      name: name,
      stationImage: '',
      contactNumber: '',
      inOffice: true,
      onField: false,
      parking: false,
      wheelchair: false,
      wifi: false,
    );

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      // The real delegates, not a bare MaterialApp: several of these
      // widgets read translated strings (the skeletons announce
      // "loading" to a screen reader), and a harness that skips the
      // localization scope tests a tree the app never builds.
      locale: const Locale('bs'),
      supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('skeletons', () {
    testWidgets('a clinic card skeleton lays out without unbounded constraints',
        (tester) async {
      await pump(tester, const ClinicCardSkeleton());
      expect(tester.takeException(), isNull);
      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('an appointment card skeleton lays out', (tester) async {
      await pump(tester, const AppointmentCardSkeleton());
      expect(tester.takeException(), isNull);
    });

    testWidgets('a review skeleton lays out', (tester) async {
      await pump(tester, const ReviewSkeleton());
      expect(tester.takeException(), isNull);
    });

    testWidgets('SkeletonList renders the requested number and shimmers',
        (tester) async {
      await pump(tester, SkeletonList(count: 4, itemBuilder: () => const ClinicCardSkeleton()));
      expect(tester.takeException(), isNull);
      expect(find.byType(ClinicCardSkeleton), findsNWidgets(4));
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('the shimmer animation stops when the widget goes away',
        (tester) async {
      // A repeating controller that outlives its widget keeps the test
      // binding busy forever and leaks a ticker in the app.
      await pump(tester, SkeletonList(count: 1, itemBuilder: () => const ReviewSkeleton()));
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
      expect(tester.takeException(), isNull);
    });
  });

  group('clinic avatar', () {
    testWidgets('shows the first letters of the first two words', (tester) async {
      await pump(tester, SizedBox(height: 120, child: ClinicAvatar(station: station())));
      expect(find.text('HP'), findsOneWidget);
    });

    testWidgets('a one-word name gets a single letter', (tester) async {
      await pump(
        tester,
        SizedBox(height: 120, child: ClinicAvatar(station: station(name: 'Vetkom'))),
      );
      expect(find.text('V'), findsOneWidget);
    });

    testWidgets('a nameless clinic falls back to the paw mark', (tester) async {
      await pump(
        tester,
        SizedBox(height: 120, child: ClinicAvatar(station: station(name: ''))),
      );
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('the same clinic always gets the same colours', (tester) async {
      // The whole point of keying off the id: a clinic that looked teal on
      // the list must not look green on its own page, or on the next launch.
      // Read off the rendered tree, not off build()'s return value: the
      // wrappers around the painted stack are presentation and change
      // more often than the colour choice under test.
      Future<Gradient> gradientOf(VetStation s) async {
        await pump(tester, SizedBox(height: 120, child: ClinicAvatar(station: s)));
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(ClinicAvatar),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (box.decoration as BoxDecoration).gradient!;
      }

      final first = await gradientOf(station(id: 3));
      final second = await gradientOf(station(id: 3, name: 'Renamed Clinic'));
      final other = await gradientOf(station(id: 4));

      expect((first as LinearGradient).colors, (second as LinearGradient).colors);
      expect((other as LinearGradient).colors, isNot(first.colors));
    });

    testWidgets('hero tags are unique per clinic and stable', (tester) async {
      expect(clinicHeroTag(1), clinicHeroTag(1));
      expect(clinicHeroTag(1), isNot(clinicHeroTag(2)));
    });
  });
}
