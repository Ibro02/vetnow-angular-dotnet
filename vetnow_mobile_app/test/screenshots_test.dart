@Tags(['screenshots'])
library;

// Renders every screen to a PNG so they can be looked at.
//
// Not an assertion suite — nothing here can fail on a pixel. It exists
// because the screens behind the login cannot be driven by hand (the
// browser harness will not type into a Flutter text field), so this is
// the only way to actually see Pets, Appointments, Profile and the
// diagnostics page.
//
// Run with:
//   flutter test test/screenshots_test.dart --update-goldens --tags screenshots
//
// Output lands in test/goldens/screens/.

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
import 'package:vetnow_mobile/services/breed_api_service.dart';
import 'package:vetnow_mobile/services/species_api_service.dart';
import 'package:vetnow_mobile/state/theme_state.dart';

import 'support/fake_backend.dart';

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
      'Appointment/GetByCustomerId': (_) =>
          [appointment(), appointment(id: 102, inDays: 12, animalName: 'Mica')],
      'ProfileEndpoint': (_) => {
            'id': 42,
            'firstName': 'Amir',
            'lastName': 'Hadžić',
            'email': 'amir.hadzic@test.com',
          },
      'VetStationSearch': (_) => stations(),
      'VetStation/GetAll': (_) => stations(),
      'VetStation/Get': (_) => stations()['vetStations'],
      'VetStation/OpeningHours': (_) => <Map<String, dynamic>>[],
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
      'Employee/': (_) => {'dataItems': <Map<String, dynamic>>[]},
      'TimeSlot': (_) => <Map<String, dynamic>>[],
      'BreedGetBySpecies': (_) => {'dataItems': <Map<String, dynamic>>[]},
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SpeciesApiService.invalidate();
    BreedApiService.invalidate();
  });

  tearDown(() {
    resetBackend();
    applyPaletteBrightness(Brightness.light);
  });

  final screens = <String, Widget Function()>{
    'explore': () => const Scaffold(body: ExploreScreen()),
    'pets': () => const PetsScreen(),
    'appointments': () => const MyAppointmentsScreen(),
    'profile': () => const ProfileScreen(),
    'diagnostics': () => const DiagnosticsScreen(),
    'notifications': () => const NotificationsScreen(),
    'add-pet': () => const AddPetScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'clinic': () => VetStationDetailScreen(station: _clinic()),
    'booking': () => BookingScreen(station: _clinic(), services: _services),
    'pet-detail': () => PetDetailScreen(pet: samplePet()),
    'appointment-detail': () =>
        AppointmentDetailScreen(appointment: sampleAppointment()),
    'reschedule': () => RescheduleScreen(appointment: sampleAppointment()),
    'staff-profile': () =>
        StaffProfileScreen(staff: sampleStaff(), station: _clinic()),
    'edit-profile': () => const EditProfileScreen(),
    'verify-account': () => const VerifyAccountScreen(userId: 42),
  };

  for (final entry in screens.entries) {
    for (final brightness in Brightness.values) {
      final name = '${entry.key}-${brightness.name}';

      testWidgets(name, (tester) async {
        applyPaletteBrightness(brightness);
        useBackend(_backend());

        tester.view.physicalSize = _phone;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(harness(entry.value()));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/screens/$name.png'),
        );
      });
    }
  }
}
