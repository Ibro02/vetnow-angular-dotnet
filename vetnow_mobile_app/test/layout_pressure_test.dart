// Every main screen, on a small phone and with the text turned up.
//
// Overflow is the most visible bug this app can ship: yellow and black
// stripes across a screen read as broken in a way a missing feature never
// does. It is also the easiest to miss, because the machine it is
// developed on has a wide window and default text.
//
// Two pressures, applied together:
//
//   * A 320×568 screen. Still sold, still in use, and the narrowest
//     thing the app has to survive.
//   * Text scaled to 1.5 and 2.0. Android's accessibility settings go
//     past 2.0, but 2.0 is the point Material itself stops guaranteeing
//     layouts, and a screen that survives it survives the common case of
//     someone who simply cannot read small type.
//
// The assertion is deliberately blunt: render it, and nothing threw.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:vetnow_mobile/models/vet_service.dart';
import 'package:vetnow_mobile/models/vet_station.dart';
import 'package:vetnow_mobile/screens/appointment_detail_screen.dart';
import 'package:vetnow_mobile/screens/booking_screen.dart';
import 'package:vetnow_mobile/screens/edit_profile_screen.dart';
import 'package:vetnow_mobile/screens/pet_detail_screen.dart';
import 'package:vetnow_mobile/screens/reschedule_screen.dart';
import 'package:vetnow_mobile/screens/staff_profile_screen.dart';
import 'package:vetnow_mobile/screens/verify_account_screen.dart';
import 'package:vetnow_mobile/screens/add_pet_screen.dart';
import 'package:vetnow_mobile/screens/diagnostics_screen.dart';
import 'package:vetnow_mobile/screens/login_screen.dart';
import 'package:vetnow_mobile/screens/notifications_screen.dart';
import 'package:vetnow_mobile/screens/register_screen.dart';
import 'package:vetnow_mobile/screens/vet_station_detail_screen.dart';
import 'package:vetnow_mobile/screens/explore_screen.dart';
import 'package:vetnow_mobile/screens/my_appointments_screen.dart';
import 'package:vetnow_mobile/screens/pets_screen.dart';
import 'package:vetnow_mobile/screens/profile_screen.dart';
import 'package:vetnow_mobile/screens/root_shell.dart';
import 'package:vetnow_mobile/state/theme_state.dart';

import 'support/fake_backend.dart';

/// The smallest screen worth supporting.
const _small = Size(320, 568);

/// A typical modern phone, for the scaled-text cases.
const _phone = Size(390, 844);

VetStation _clinic() => VetStation.fromJson(
      (stations()['vetStations'] as List).first as Map<String, dynamic>,
    );

/// The booking flow is the one path in the app that earns anything, and
/// it had never been rendered anywhere.
const _services = [
  VetService(
    name: 'Opci pregled',
    description: 'Kompletan fizicki pregled',
    priceKm: 30,
    durationMinutes: 30,
  ),
  VetService(
    name: 'Vakcinacija',
    description: 'Osnovne vakcine i vakcina protiv bjesnila',
    priceKm: 25,
    durationMinutes: 20,
  ),
];

FakeBackend _backend() => FakeBackend({
      'SpeciesGetAll': (_) => speciesEnvelope(),
      'Animal/GetByOwnerId': (_) => animals(),
      'Appointment/GetByCustomerId': (_) => [appointment(), appointment(id: 102)],
      'ProfileEndpoint': (_) => {
            'id': 42,
            'firstName': 'Test',
            'lastName': 'Korisnik',
            'email': 'test@vetnow.ba',
          },
      'VetStationSearch': (_) => stations(),
      'VetStation/GetAll': (_) => stations(),
      'Review/GetByVetStation': (_) => {'average': 4.4, 'count': 5, 'reviews': []},
      'Review/Pending': (_) => <Map<String, dynamic>>[],
      // Without this the edit-profile screen renders its error state
      // instead of its form, and the layout suite passes it on a
      // message rather than on the thing that has fields in it.
      'ProfileSettings': (_) => {
            'firstName': 'Amir',
            'lastName': 'Hadzic',
            'phone': '+387 61 234 567',
            'email': 'amir.hadzic@test.com',
            'city': 'Sarajevo',
            'country': 'Bosna i Hercegovina',
            'address': 'Zmaja od Bosne 4',
          },
      'VetStation/Get': (_) => stations()['vetStations'],
      'VetStation/OpeningHours': (_) => <Map<String, dynamic>>[],
      'Employee/': (_) => {'dataItems': <Map<String, dynamic>>[]},
      'TimeSlot': (_) => <Map<String, dynamic>>[],
      'BreedGetBySpecies': (_) => {'dataItems': <Map<String, dynamic>>[]},
    });

Future<void> _render(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  required double textScale,
  bool signedIn = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    harness(screen, signedIn: signedIn, textScale: textScale),
  );

  // Fixed frames rather than pumpAndSettle: Explore's hero has a
  // continuously drifting background and the placeholders shimmer on a
  // loop, so there is no quiet moment to settle into and pumpAndSettle
  // simply times out. Ten frames is past every entrance animation and
  // past the first data arriving, which is all this needs.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    applyPaletteBrightness(Brightness.light);
  });

  tearDown(() {
    resetBackend();
    applyPaletteBrightness(Brightness.light);
  });

  final screens = <String, Widget Function()>{
    // Explore has no Scaffold of its own; it lives inside the shell's.
    'Explore': () => const Scaffold(body: ExploreScreen()),
    'Pets': () => const PetsScreen(),
    'Appointments': () => const MyAppointmentsScreen(),
    'Profile': () => const ProfileScreen(),
    'Diagnostics': () => const DiagnosticsScreen(),
    'Shell': () => const RootShell(),
    // The rest of the app. Every one of these was found to overflow
    // somewhere the first time it was put under this pressure, which is
    // the argument for the list being exhaustive rather than a sample.
    'Clinic': () => VetStationDetailScreen(station: _clinic()),
    'Notifications': () => const NotificationsScreen(),
    'AddPet': () => const AddPetScreen(),
    'Login': () => const LoginScreen(),
    'Register': () => const RegisterScreen(),
    'Booking': () => BookingScreen(station: _clinic(), services: _services),
    'PetDetail': () => PetDetailScreen(pet: samplePet()),
    'AppointmentDetail': () =>
        AppointmentDetailScreen(appointment: sampleAppointment()),
    'Reschedule': () => RescheduleScreen(appointment: sampleAppointment()),
    'StaffProfile': () =>
        StaffProfileScreen(staff: sampleStaff(), station: _clinic()),
    'EditProfile': () => const EditProfileScreen(),
    'VerifyAccount': () => const VerifyAccountScreen(userId: 42),
  };

  for (final entry in screens.entries) {
    group(entry.key, () {
      testWidgets('fits a 320pt screen', (tester) async {
        useBackend(_backend());
        await _render(tester, entry.value(), size: _small, textScale: 1.0);

        expect(tester.takeException(), isNull);
      });

      testWidgets('survives text at 1.5x', (tester) async {
        useBackend(_backend());
        await _render(tester, entry.value(), size: _phone, textScale: 1.5);

        expect(tester.takeException(), isNull);
      });

      testWidgets('survives text at 2x', (tester) async {
        useBackend(_backend());
        await _render(tester, entry.value(), size: _phone, textScale: 2.0);

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders in dark mode', (tester) async {
        applyPaletteBrightness(Brightness.dark);
        useBackend(_backend());
        await _render(tester, entry.value(), size: _phone, textScale: 1.0);

        expect(tester.takeException(), isNull);
      });
    });
  }

  group('guest', () {
    // The tabs a guest can reach but not use. These render an auth prompt
    // rather than the screen, which is a different layout and was never
    // put under the same pressure.
    for (final entry in {
      'Appointments': () => const MyAppointmentsScreen(),
      'Profile': () => const ProfileScreen(),
    }.entries) {
      testWidgets('${entry.key} prompt fits a small screen', (tester) async {
        useBackend(_backend());
        await _render(
          tester,
          entry.value(),
          size: _small,
          textScale: 1.5,
          signedIn: false,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
