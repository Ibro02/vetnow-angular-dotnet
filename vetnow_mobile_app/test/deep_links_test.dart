// Turning a link into a destination.
//
// Link parsing is where a typo produces the worst kind of bug: not a
// crash, but a link that confidently opens the wrong clinic. It is also
// the one part of deep linking that can be tested without a device — the
// platform channel that delivers the link cannot be — so it is tested
// thoroughly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/root_shell.dart';

import 'support/fake_backend.dart';

import 'package:vetnow_mobile/services/deep_links.dart';

DeepLink? parse(String uri) => parseDeepLink(Uri.parse(uri));

void main() {
  shellCases();

  group('the app scheme', () {
    test('opens a clinic by id', () {
      expect(parse('vetnow://clinic/3'), const ClinicLink(3));
    });

    test('accepts the local spelling too', () {
      // Links get written by hand and pasted into messages; both words
      // mean the same page and it is cheaper to accept both than to
      // explain which one is right.
      expect(parse('vetnow://klinika/7'), const ClinicLink(7));
    });

    test('is not case sensitive', () {
      expect(parse('vetnow://Clinic/3'), const ClinicLink(3));
    });

    test('reaches each tab', () {
      expect(parse('vetnow://appointments'), const TabLink(Destination.appointments));
      expect(parse('vetnow://termini'), const TabLink(Destination.appointments));
      expect(parse('vetnow://profile'), const TabLink(Destination.profile));
      expect(parse('vetnow://profil'), const TabLink(Destination.profile));
      expect(parse('vetnow://explore'), const TabLink(Destination.explore));
    });
  });

  group('web links', () {
    test('mean exactly the same thing', () {
      expect(parse('https://vetnow.ba/clinic/3'), const ClinicLink(3));
      expect(parse('https://www.vetnow.ba/clinic/3'), const ClinicLink(3));
      expect(
        parse('https://vetnow.ba/appointments'),
        const TabLink(Destination.appointments),
      );
    });

    test('a trailing slash changes nothing', () {
      expect(parse('https://vetnow.ba/clinic/3/'), const ClinicLink(3));
    });

    test('query strings and fragments are ignored, not parsed', () {
      expect(parse('https://vetnow.ba/clinic/3?utm_source=email'), const ClinicLink(3));
      expect(parse('https://vetnow.ba/clinic/3#reviews'), const ClinicLink(3));
    });

    test('the bare domain opens the app', () {
      expect(parse('https://vetnow.ba'), const TabLink(Destination.explore));
      expect(parse('https://vetnow.ba/'), const TabLink(Destination.explore));
    });
  });

  group('links that are wrong', () {
    test('a non-numeric id opens Explore rather than the wrong clinic', () {
      // The alternative is parsing "abc" as 0 and opening whatever clinic
      // happens to have that id, which is worse than doing nothing.
      expect(parse('vetnow://clinic/abc'), const TabLink(Destination.explore));
      expect(parse('https://vetnow.ba/clinic/3x'), const TabLink(Destination.explore));
    });

    test('a clinic link with no id opens Explore', () {
      expect(parse('vetnow://clinic'), const TabLink(Destination.explore));
      expect(parse('vetnow://clinic/'), const TabLink(Destination.explore));
    });

    test('an unknown path opens the app instead of failing', () {
      // Old links outlive the pages they pointed at. Opening the front
      // door reads as an out-of-date link; doing nothing reads as a
      // broken app.
      expect(parse('vetnow://something-we-removed'), const TabLink(Destination.explore));
      expect(parse('https://vetnow.ba/blog/2024/post'), const TabLink(Destination.explore));
    });

    test('a negative or huge id is still parsed as an id', () {
      // Not this layer's job to decide which ids exist; the lookup that
      // follows will simply find nothing and say so.
      expect(parse('vetnow://clinic/-1'), const ClinicLink(-1));
      expect(parse('vetnow://clinic/999999'), const ClinicLink(999999));
    });
  });

  group('equality', () {
    test('two links to the same place are the same link', () {
      // The shell compares against the last link it acted on, so that a
      // rebuild does not reopen the same clinic. That only works if
      // equality is by value.
      expect(const ClinicLink(3), const ClinicLink(3));
      expect(const ClinicLink(3), isNot(const ClinicLink(4)));
      expect(
        const TabLink(Destination.profile),
        const TabLink(Destination.profile),
      );
      expect(parse('vetnow://clinic/3'), parse('https://vetnow.ba/clinic/3'));
    });
  });
}

// ─────────────────────────────────────────────────────────────

/// The shell acting on a link, rather than just parsing one.
///
/// Everything above is a pure function; this is the part that has to
/// actually reach the right screen, which is where an off-by-one in the
/// tab order or a missed rebuild would show up.
void shellCases() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(resetBackend);

  FakeBackend backend() => FakeBackend({
        'VetStationSearch': (_) => stations(),
        'VetStation/GetAll': (_) => stations(),
        'VetStation/Get': (_) => stations()['vetStations'],
        'VetStation/OpeningHours': (_) => <Map<String, dynamic>>[],
        'Employee/': (_) => {'dataItems': <Map<String, dynamic>>[]},
        'Review/GetByVetStation': (_) => {'average': 4.4, 'count': 5, 'reviews': []},
        'Review/Pending': (_) => <Map<String, dynamic>>[],
        'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'Animal/GetByOwnerId': (_) => animals(),
        'ProfileEndpoint': (_) => {'id': 42, 'firstName': 'Test'},
      });

  Future<ValueNotifier<DeepLink?>> pumpShell(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    useBackend(backend());
    final link = ValueNotifier<DeepLink?>(null);
    addTearDown(link.dispose);

    await tester.pumpWidget(harness(const RootShell(), link: link));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    return link;
  }

  testWidgets('a clinic link opens that clinic', (tester) async {
    final link = await pumpShell(tester);

    link.value = const ClinicLink(1);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    // The clinic's own page, not the list it was tapped from.
    expect(find.text('Ferhadija 15, Sarajevo'), findsWidgets);
  });

  testWidgets('a tab link switches tabs without pushing a route',
      (tester) async {
    final link = await pumpShell(tester);
    final l10n = await bosnian();

    link.value = const TabLink(Destination.profile);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    expect(find.text(l10n.navProfile), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a clinic that no longer exists leaves the app on Explore',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Everything answers except the clinic lookup, which finds nothing.
    useBackend(FakeBackend({
      'VetStationSearch': (_) => stations(),
      'VetStation/Get': (_) => <Map<String, dynamic>>[],
      'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
    }));
    final link = ValueNotifier<DeepLink?>(null);
    addTearDown(link.dispose);

    await tester.pumpWidget(harness(const RootShell(), link: link));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    link.value = const ClinicLink(9999);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    // No crash, no blank pushed route — just the app, open.
    expect(tester.takeException(), isNull);
    expect(find.byType(RootShell), findsOneWidget);
  });
}
