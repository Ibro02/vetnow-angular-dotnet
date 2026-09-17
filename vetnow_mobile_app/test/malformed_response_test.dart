// What happens when the server sends something unexpected.
//
// The backend is a separate .NET project on its own release schedule.
// A field renamed, a nullable column that finally went null, an int that
// arrives quoted — none of those are hypothetical, and none of them are
// caught by a test that only feeds parsers the shape they were written
// against.
//
// Two different failures are worth separating:
//
//   * A malformed *envelope* — the whole response is the wrong shape.
//     Failing the request is correct; the screen has an error state and
//     a retry button for exactly this.
//   * A malformed *row* in an otherwise good list. Here failing the
//     whole request is the wrong answer: nine good clinics should not
//     disappear because the tenth has a null name.
//
// The second is the one that matters, and the one this file is mostly
// about.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/explore_screen.dart';
import 'package:vetnow_mobile/screens/pets_screen.dart';
import 'package:vetnow_mobile/services/api_client.dart';
import 'package:vetnow_mobile/services/breed_api_service.dart';
import 'package:vetnow_mobile/services/species_api_service.dart';
import 'package:vetnow_mobile/widgets/state_views.dart';

import 'support/fake_backend.dart';

/// Answers every request with one body, whatever was asked for.
class _Always extends http.BaseClient {
  final String body;
  final int status;

  _Always(this.body, {this.status = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(harness(screen));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpeciesApiService.invalidate();
    BreedApiService.invalidate();
  });

  tearDown(() {
    resetBackend();
    SpeciesApiService.invalidate();
    BreedApiService.invalidate();
  });

  group('the species list', () {
    Future<List<SpeciesOption>> fetch(Object? body) {
      ApiClient.client = _Always(jsonEncode(body));
      return SpeciesApiService.getAll();
    }

    test('an envelope that is not a map yields nothing, rather than throwing',
        () async {
      expect(await fetch(['not', 'an', 'envelope']), isEmpty);
    });

    test('dataItems missing, or not a list, yields nothing', () async {
      expect(await fetch({'totalCount': 0}), isEmpty);
      SpeciesApiService.invalidate();
      BreedApiService.invalidate();
      expect(await fetch({'dataItems': 'oops'}), isEmpty);
    });

    test('one bad row does not take the good ones with it', () async {
      // The case that actually costs something: a picker that goes empty
      // because one species out of twelve has a null id.
      final result = await fetch({
        'dataItems': [
          {'id': 1, 'speciesName': 'Pas'},
          {'id': null, 'speciesName': 'Neispravna'},
          'not even a map',
          {'id': 3, 'speciesName': 'Kornjača'},
        ],
      });

      expect(result.map((s) => s.name), ['Pas', 'Kornjača']);
    });

    test('an id sent as a string is still an id', () async {
      // .NET serialises ints as ints, but a proxy, a config change or a
      // hand-written test double may not.
      final result = await fetch({
        'dataItems': [
          {'id': '7', 'speciesName': 'Zec'},
          {'id': 8.0, 'speciesName': 'Ptica'},
        ],
      });

      expect(result.map((s) => s.id), [7, 8]);
    });

    test('a missing name becomes a placeholder, not a blank row', () async {
      final result = await fetch({
        'dataItems': [
          {'id': 1},
          {'id': 2, 'speciesName': '   '},
        ],
      });

      expect(result, hasLength(2));
      expect(result.every((s) => s.name.trim().isNotEmpty), isTrue);
    });

    test('a failure is not cached — the next call tries again', () async {
      ApiClient.client = _Always('{"message":"down"}', status: 500);
      await expectLater(SpeciesApiService.getAll(), throwsA(isA<ApiException>()));

      // Without dropping the cached future, one hiccup at launch would
      // leave the species picker broken for the whole session.
      ApiClient.client = _Always(jsonEncode({
        'dataItems': [
          {'id': 1, 'speciesName': 'Pas'},
        ],
      }));

      expect((await SpeciesApiService.getAll()).single.name, 'Pas');
    });
  });

  group('Explore, against a server that answers wrongly', () {
    testWidgets('an envelope of the wrong shape shows the error state, not a '
        'blank page', (tester) async {
      ApiClient.client = _Always('"just a string"');

      await _pump(tester, const Scaffold(body: ExploreScreen()));

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorStateView), findsOneWidget);
    });

    testWidgets('an empty envelope is an empty list, not an error',
        (tester) async {
      ApiClient.client = _Always('{"vetStations":[]}');

      await _pump(tester, const Scaffold(body: ExploreScreen()));

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorStateView), findsNothing);
    });

    testWidgets('a clinic with null text fields still renders', (tester) async {
      // Every string on VetStation has a `?? ''` behind it. This is the
      // test that says so out loud, because the day one of them loses it
      // the screen turns red rather than showing a blank line.
      ApiClient.client = _Always(jsonEncode({
        'vetStations': [
          {
            'id': 1,
            'name': null,
            'city': null,
            'address': null,
            'contactNumber': null,
            'averageRating': null,
            'reviewCount': null,
          },
        ],
      }));

      await _pump(tester, const Scaffold(body: ExploreScreen()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('one bad clinic does not empty the whole list', (tester) async {
      // The case worth caring about. Nine good clinics should not
      // disappear because the tenth arrived with a null id.
      ApiClient.client = _Always(jsonEncode({
        'vetStations': [
          {'id': 1, 'name': 'Happy Paws Vet Clinic', 'city': 'Sarajevo'},
          {'id': null, 'name': 'Broken Clinic'},
          {'id': 3, 'name': 'Animal Wellness Center', 'city': 'Tuzla'},
        ],
      }));

      await _pump(tester, const Scaffold(body: ExploreScreen()));

      expect(tester.takeException(), isNull);
      expect(find.text('Happy Paws Vet Clinic'), findsOneWidget);
      expect(find.text('Animal Wellness Center'), findsOneWidget);
      expect(find.byType(ErrorStateView), findsNothing);
    });

    testWidgets('HTML from a proxy or a login page is an error, not a crash',
        (tester) async {
      // A captive portal, a misrouted request, an expired gateway — all
      // answer 200 with HTML, which is the one case a JSON client tends
      // not to be written for.
      ApiClient.client = _Always('<!doctype html><title>Sign in</title>');

      await _pump(tester, const Scaffold(body: ExploreScreen()));

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorStateView), findsOneWidget);
    });
  });

  group('Pets, against a server that answers wrongly', () {
    testWidgets('an animal list of the wrong shape does not crash the screen',
        (tester) async {
      useBackend(FakeBackend({
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'Animal/GetByOwnerId': (_) => {'unexpected': 'shape'},
        'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
      }));

      await _pump(tester, const PetsScreen());

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorStateView), findsOneWidget);
    });
  });
}
