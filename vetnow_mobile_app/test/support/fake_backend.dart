import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:vetnow_mobile/config/theme.dart';
import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/models/appointment.dart';
import 'package:vetnow_mobile/models/pet.dart';
import 'package:vetnow_mobile/models/staff_member.dart';
import 'package:vetnow_mobile/services/api_client.dart';
import 'package:vetnow_mobile/services/deep_links.dart';
import 'package:vetnow_mobile/state/auth_state.dart';
import 'package:vetnow_mobile/state/locale_state.dart';
import 'package:vetnow_mobile/state/theme_state.dart';

/// A backend that answers from a routing table instead of a socket.
///
/// The screens behind the login — Pets, Appointments, Profile — were the
/// least covered part of the app for a dull reason: every one of them
/// starts by asking the server for something, so there was no way to
/// render one in a test without a server. Since ApiClient took an
/// injectable client that stopped being true, and these are the cases
/// that were never exercised at all.
///
/// Routes are matched on a substring of the path, in insertion order, so
/// a test only has to name the endpoints it cares about.
class FakeBackend extends http.BaseClient {
  final Map<String, dynamic Function(http.BaseRequest request)> routes;

  /// Every request that arrived, for asserting what a screen actually
  /// asked for — including the ones it should not have.
  final List<http.BaseRequest> calls = [];

  FakeBackend(this.routes);

  /// Paths that should fail as if the network were down.
  final Set<String> offline = {};

  /// Paths that should answer with a 500.
  final Set<String> broken = {};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls.add(request);
    final path = request.url.path;

    if (offline.any(path.contains)) {
      throw const _Dropped();
    }
    if (broken.any(path.contains)) {
      return _respond(request, 500, '"Server je pao."');
    }

    for (final entry in routes.entries) {
      if (path.contains(entry.key)) {
        return _respond(request, 200, jsonEncode(entry.value(request)));
      }
    }

    // Loud on purpose: an unrouted call in a test is almost always a
    // screen asking for something the test did not expect it to need.
    return _respond(request, 404, '"No fake route for $path"');
  }

  http.StreamedResponse _respond(http.BaseRequest request, int status, String body) {
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  /// True if any request carried the auth header.
  bool get sawToken => calls.any((c) => c.headers.containsKey('my-auth-token'));

  String? tokenFor(String pathFragment) => calls
      .firstWhere(
        (c) => c.url.path.contains(pathFragment),
        orElse: () => http.Request('GET', Uri.parse('http://x/')),
      )
      .headers['my-auth-token'];
}

class _Dropped implements Exception {
  const _Dropped();
  @override
  String toString() => 'SocketException: connection dropped';
}

/// The app's scopes around one screen, with a session already in place.
///
/// [signedIn] false gives the guest tree, which is what the auth prompts
/// are rendered from.
Widget harness(
  Widget child, {
  bool signedIn = true,
  AuthState? auth,
  double textScale = 1.0,
  ValueNotifier<DeepLink?>? link,
}) {
  final authState = auth ?? AuthState();

  if (signedIn) {
    authState
      ..isLoggedIn = true
      ..isRestoring = false
      ..token = 'test-token'
      ..userId = 42
      ..displayName = 'Test Korisnik'
      ..email = 'test@vetnow.ba';
  } else {
    authState
      ..isLoggedIn = false
      ..isRestoring = false;
  }

  return DeepLinkScope(
    notifier: link ?? ValueNotifier<DeepLink?>(null),
    child: ThemeScope(
      notifier: ThemeState(),
      child: LocaleScope(
        notifier: LocaleState(),
        child: AuthScope(
          notifier: authState,
          child: MaterialApp(
            locale: const Locale('bs'),
            supportedLocales: const [Locale('bs'), Locale('hr'), Locale('sr')],
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          // Without this the Scaffold takes Material's own light default
          // while every widget that reads AppColors directly follows the
          // palette — so a dark-mode test renders dark cards on a white
          // page, which is neither what the app does nor a bug in it.
          theme: AppTheme.current,
            // Applied through the builder, not around MaterialApp: MaterialApp
            // installs its own MediaQuery from the view, so one wrapped
            // outside it is simply replaced and the scale never reaches a
            // single Text.
            builder: (context, navigator) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: navigator!,
            ),
            home: child,
          ),
        ),
      ),
    ),
  );
}

Future<AppLocalizations> bosnian() => AppLocalizations.delegate.load(const Locale('bs'));

/// Installs [backend] for the duration of a test.
void useBackend(FakeBackend backend) => ApiClient.client = backend;

void resetBackend() => ApiClient.client = http.Client();

// ─── Response shapes, matching what the real endpoints return ───

Map<String, dynamic> speciesEnvelope() => {
      'totalCount': 3,
      'currentPage': 1,
      'pageSize': 100,
      'dataItems': [
        {'id': 1, 'name': 'Pas'},
        {'id': 2, 'name': 'Mačka'},
        {'id': 3, 'name': 'Kornjača'},
      ],
    };

List<Map<String, dynamic>> animals() => [
      {
        'id': 11,
        'name': 'Rex',
        'animalSpeciesId': 1,
        'birthDate': '2021-04-02T00:00:00',
        'isFavourite': true,
      },
      {
        'id': 12,
        'name': 'Mica',
        'animalSpeciesId': 2,
        'birthDate': '2023-11-20T00:00:00',
        'isFavourite': false,
      },
    ];

/// One booked visit, [inDays] from now. Negative for a past visit.
Map<String, dynamic> appointment({
  int id = 101,
  int inDays = 3,
  String animalName = 'Rex',
  String clinic = 'Happy Paws Vet Clinic',
}) {
  final at = DateTime.now().add(Duration(days: inDays));
  return {
    'id': id,
    'employeeId': 5,
    'vetStationId': 1,
    'animalId': 11,
    'timeSlotId': 900 + id,
    'slotDateTime': at.toIso8601String(),
    'appointmentTime': '10:00',
    'animalName': animalName,
    'speciesName': 'Pas',
    'employeeFirstName': 'Amina',
    'employeeLastName': 'Hodžić',
    'vetStationName': clinic,
  };
}

/// Gives a test the screen size of a real phone.
///
/// The default test surface is 800×600, which is a landscape tablet and
/// not a shape this app is ever used in — layouts overflow there that are
/// fine on a phone, and layouts break on a phone that are fine there.
/// Everything below is asserted at a size someone actually holds.
Future<void> usePhoneScreen(WidgetTester tester, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Drags the first scrollable to the end.
///
/// `scrollUntilVisible` does not help on screens whose list is built
/// eagerly: the finder matches a widget that exists but is off-screen, so
/// the helper returns without scrolling and the following tap lands
/// outside the viewport.
Future<void> scrollToBottom(WidgetTester tester, {int drags = 6}) async {
  for (var i = 0; i < drags; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
}

/// The clinic search envelope: `{ vetStations: [...] }`.
Map<String, dynamic> stations() => {
      'vetStations': [
        {
          'id': 1,
          'name': 'Happy Paws Vet Clinic',
          'stationImage': '',
          'contactNumber': '+387 33 123 456',
          'inOffice': true,
          'onField': true,
          'parking': true,
          'wheelchair': true,
          'wifi': true,
          'city': 'Sarajevo',
          'country': 'Bosna i Hercegovina',
          'address': 'Ferhadija 15',
          'email': 'info@happypaws.ba',
          'description': 'Kompletna veterinarska njega.',
          'averageRating': 4.4,
          'reviewCount': 5,
          'verifiedPartner': true,
          'isOpenNow': true,
        },
        {
          'id': 2,
          'name': 'PetCare Animal Hospital Mostar',
          'stationImage': '',
          'contactNumber': '+387 36 987 654',
          'inOffice': true,
          'onField': false,
          'parking': false,
          'wheelchair': false,
          'wifi': false,
          'city': 'Mostar',
          'country': 'Bosna i Hercegovina',
          'address': 'Bulevar 42',
          'email': 'info@petcare.ba',
          'description': '',
          'averageRating': 4.0,
          'reviewCount': 2,
          'verifiedPartner': false,
          'isOpenNow': false,
        },
      ],
    };

// ─── Fixtures for the screens that take a model, not an id ───────────
//
// Six screens were invisible to both suites simply because they need a
// Pet or an Appointment handed to them, and there was nothing to hand.

Pet samplePet({
  int id = 11,
  String name = 'Rex',
  bool favourite = true,
}) =>
    Pet(
      id: id,
      name: name,
      species: 'Pas',
      speciesId: 1,
      breed: 'Njemački ovčar',
      birthDate: DateTime(2021, 4, 2),
      weightKg: 32.5,
      microchipNumber: '941000012345678',
      isFavourite: favourite,
    );

Appointment sampleAppointment({
  int id = 101,
  int inDays = 3,
  AppointmentStatus status = AppointmentStatus.upcoming,
}) =>
    Appointment(
      id: id,
      employeeId: 5,
      vetStationId: 1,
      clinicName: 'Happy Paws Vet Clinic',
      clinicAddress: 'Ferhadija 15, Sarajevo',
      clinicPhone: '+387 33 123 456',
      staffName: 'Dr. Amina Hodžić',
      staffRole: 'Veterinar',
      petName: 'Rex',
      serviceName: 'Opći pregled',
      serviceDescription: 'Kompletan fizički pregled',
      priceKm: 30,
      durationMinutes: 30,
      dateTime: DateTime.now().add(Duration(days: inDays)),
      status: status,
    );

StaffMember sampleStaff() => const StaffMember(
      id: 5,
      name: 'Dr. Amina Hodžić',
      role: 'Veterinar',
      bio: 'Specijalista za male životinje s petnaest godina prakse.',
      rating: 4.9,
      reviewCount: 86,
    );
