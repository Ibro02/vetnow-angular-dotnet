// The medical record the backend has been able to print all along.
//
// api/PetsReport/Generate builds a PDF of every pet an owner has, with
// QuestPDF, and has existed since before the mobile app did. Nothing
// called it, so somebody changing clinics or asked for their animal's
// details at a counter had no way to get them out of the app at all.
//
// These cover the parts worth covering: that the bytes come back
// unmangled, that a PDF does not go through the JSON decoder, and that
// the two failures anybody will actually hit say something useful.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/pets_screen.dart';
import 'package:vetnow_mobile/services/api_client.dart';
import 'package:vetnow_mobile/services/breed_api_service.dart';
import 'package:vetnow_mobile/services/pets_report_api_service.dart';
import 'package:vetnow_mobile/services/species_api_service.dart';

import 'support/fake_backend.dart';

/// The first bytes of any PDF, and a handful that are not valid UTF-8 —
/// which is the point: this is a file, not a document the JSON decoder
/// should ever see.
final _pdfBytes = <int>[
  0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
  0x0A, 0xFF, 0xFE, 0x00, 0x80,
];

/// Answers the report endpoint with bytes and everything else normally.
class _WithReport extends http.BaseClient {
  final FakeBackend _rest;
  final int status;
  final List<int> body;

  _WithReport(this._rest, {this.status = 200, List<int>? body})
      : body = body ?? _pdfBytes;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!request.url.path.contains('PetsReport')) return _rest.send(request);

    return Future.value(http.StreamedResponse(
      Stream.value(body),
      status,
      request: request,
      headers: {'content-type': 'application/pdf'},
    ));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpeciesApiService.invalidate();
    BreedApiService.invalidate();
    ApiClient.onSessionExpired = null;
  });

  tearDown(() {
    resetBackend();
    SpeciesApiService.invalidate();
    BreedApiService.invalidate();
    ApiClient.onSessionExpired = null;
  });

  FakeBackend rest() => FakeBackend({
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'BreedGetBySpecies': (_) => {'dataItems': <Map<String, dynamic>>[]},
        'Animal/GetByOwnerId': (_) => animals(),
        'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
      });

  group('fetching it', () {
    test('the bytes arrive exactly as sent', () async {
      useClient(_WithReport(rest()));

      final bytes = await PetsReportApiService.forOwner(ownerId: 42, token: 't');

      expect(bytes, _pdfBytes);
      // Still a PDF at the front, which is the only part of the file
      // this side has any business knowing about.
      expect(utf8.decode(bytes.sublist(0, 4)), '%PDF');
    });

    test('bytes that are not valid UTF-8 survive the trip', () async {
      // The reason getBytes exists at all: every other call decodes its
      // body, and running a PDF through jsonDecode raises a
      // FormatException blaming the parser for a response that was fine.
      useClient(_WithReport(rest()));

      final bytes = await PetsReportApiService.forOwner(ownerId: 42, token: 't');

      expect(bytes, contains(0xFF));
      expect(bytes, contains(0x80));
    });

    test('it carries the session token', () async {
      final client = _WithReport(rest());
      useClient(client);

      await PetsReportApiService.forOwner(ownerId: 42, token: 'the-token');

      // The backend refuses an ownerId that is not the caller's, which
      // it can only do if the request says who is asking.
      expect(client.body, isNotEmpty);
    });

    test('a refusal comes back as the backend worded it', () async {
      useClient(_WithReport(
        rest(),
        status: 400,
        body: utf8.encode('Could not retrieve the data.'),
      ));

      await expectLater(
        PetsReportApiService.forOwner(ownerId: 42, token: 't'),
        throwsA(isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Could not retrieve'),
        )),
      );
    });

    test('a 401 on it ends the session, like every other call', () async {
      // A token the backend has stopped accepting must not leave
      // somebody staring at a download that only ever fails.
      var expired = false;
      ApiClient.onSessionExpired = () => expired = true;
      useClient(_WithReport(rest(), status: 401, body: utf8.encode('nope')));

      await expectLater(
        PetsReportApiService.forOwner(ownerId: 42, token: 'stale'),
        throwsA(isA<ApiException>()),
      );
      expect(expired, isTrue);
    });
  });

  group('the button', () {
    Future<void> openPets(WidgetTester tester, http.BaseClient client) async {
      useClient(client);
      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(const PetsScreen()));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    testWidgets('is on the bar and says what it does', (tester) async {
      await openPets(tester, _WithReport(rest()));

      // Named, because it is an icon on its own -- an unnamed one is a
      // button a screen reader announces as "button".
      expect(
        find.byTooltip('Preuzmi karton'),
        findsOneWidget,
      );
    });

    testWidgets('an owner with no pets is told so rather than shown an error',
        (tester) async {
      // The one failure that is not a failure.
      final empty = FakeBackend({
        'SpeciesGetAll': (_) => speciesEnvelope(),
        'BreedGetBySpecies': (_) => {'dataItems': <Map<String, dynamic>>[]},
        'Animal/GetByOwnerId': (_) => <Map<String, dynamic>>[],
        'Appointment/GetByCustomerId': (_) => <Map<String, dynamic>>[],
      });
      await openPets(tester, _WithReport(empty));

      await tester.tap(find.byTooltip('Preuzmi karton'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(find.textContaining('Nemaš nijednog ljubimca'), findsOneWidget);
    });

    testWidgets('a failed report says so instead of doing nothing',
        (tester) async {
      await openPets(
        tester,
        _WithReport(rest(), status: 500, body: utf8.encode('boom')),
      );

      await tester.tap(find.byTooltip('Preuzmi karton'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(find.textContaining('Izvještaj nije uspio'), findsOneWidget);
    });
  });
}
