// Every screen, walked the way a screen reader walks it.
//
// accessibility_test.dart covers particular widgets in detail. This is
// the other half: a sweep across the whole app looking for the one
// failure that hand-written cases never catch, because it is always on
// the screen nobody thought to write a case for.
//
// That failure is a control with nothing to say. An IconButton with no
// tooltip, a GestureDetector wrapped round a bare Icon, a tappable card
// whose only content is a picture — each is a button TalkBack announces
// as "button", with no indication of what it does. They are invisible
// to everyone who can see the icon, which is why they survive review
// and why a test is the only thing that finds them.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/models/vet_service.dart';
import 'package:vetnow_mobile/models/vet_station.dart';
import 'package:vetnow_mobile/screens/add_pet_screen.dart';
import 'package:vetnow_mobile/screens/appointment_detail_screen.dart';
import 'package:vetnow_mobile/screens/booking_screen.dart';
import 'package:vetnow_mobile/screens/diagnostics_screen.dart';
import 'package:vetnow_mobile/screens/edit_profile_screen.dart';
import 'package:vetnow_mobile/screens/explore_screen.dart';
import 'package:vetnow_mobile/screens/login_screen.dart';
import 'package:vetnow_mobile/screens/my_appointments_screen.dart';
import 'package:vetnow_mobile/screens/notifications_screen.dart';
import 'package:vetnow_mobile/screens/pet_detail_screen.dart';
import 'package:vetnow_mobile/screens/pets_screen.dart';
import 'package:vetnow_mobile/screens/profile_screen.dart';
import 'package:vetnow_mobile/screens/register_screen.dart';
import 'package:vetnow_mobile/screens/reschedule_screen.dart';
import 'package:vetnow_mobile/screens/root_shell.dart';
import 'package:vetnow_mobile/screens/staff_profile_screen.dart';
import 'package:vetnow_mobile/screens/vet_station_detail_screen.dart';
import 'package:vetnow_mobile/screens/verify_account_screen.dart';
import 'package:vetnow_mobile/services/breed_api_service.dart';
import 'package:vetnow_mobile/services/species_api_service.dart';

import 'support/fake_backend.dart';

VetStation _clinic() => VetStation.fromJson(
      (stations()['vetStations'] as List).first as Map<String, dynamic>,
    );

const _services = [
  VetService(
    name: 'Opci pregled',
    description: 'Kompletan fizicki pregled',
    priceKm: 30,
    durationMinutes: 30,
  ),
];

/// A backend that answers everything, so screens render their real
/// content rather than their error states. An error state has one
/// button on it and would pass this sweep saying nothing.
FakeBackend _healthy() => FakeBackend({
      'ProfileEndpoint': (_) => {'id': 42, 'firstName': 'Test', 'lastName': 'Korisnik'},
      'ProfileSettings': (_) => {
            'firstName': 'Amir',
            'lastName': 'Hadzic',
            'phone': '+387 61 234 567',
            'email': 'amir@vetnow.ba',
            'city': 'Sarajevo',
            'country': 'Bosna i Hercegovina',
            'address': 'Zmaja od Bosne 4',
          },
      'SpeciesGetAll': (_) => speciesEnvelope(),
      'BreedGetBySpecies': (_) => {'dataItems': <Map<String, dynamic>>[]},
      'Animal/GetByOwnerId': (_) => animals(),
      'Appointment/GetByCustomerId': (_) => [appointment(), appointment(inDays: -6)],
      'VetStationSearch': (_) => stations(),
      'VetStation/GetAll': (_) => stations(),
      'VetStation/Get': (_) => stations()['vetStations'],
      'VetStation/OpeningHours': (_) =>
          {'vetStationId': 1, 'hasSchedule': false, 'days': <dynamic>[]},
      'Review/GetByVetStation': (_) =>
          {'average': 4.4, 'count': 5, 'reviews': <Map<String, dynamic>>[]},
      'Review/Pending': (_) => <Map<String, dynamic>>[],
      'Employee/': (_) => {'dataItems': <Map<String, dynamic>>[]},
      'TimeSlot': (_) => <Map<String, dynamic>>[],
    });

/// Every tappable node on screen that would be announced as a button
/// with no name attached.
List<SemanticsNode> _namelessControls(WidgetTester tester) {
  final found = <SemanticsNode>[];

  void walk(SemanticsNode node, {required bool namedAbove}) {
    final data = node.getSemanticsData();

    final isTappable = data.hasAction(SemanticsAction.tap);
    final saysSomething = data.label.trim().isNotEmpty ||
        data.tooltip.trim().isNotEmpty ||
        data.value.trim().isNotEmpty ||
        data.hint.trim().isNotEmpty;

    // A node that merely *contains* something named is fine: a card
    // whose label lives on the text inside it reads correctly. What is
    // being looked for is a tap with nothing anywhere under it to say.
    //
    // All the way down, not one level: a button's own label sits at the
    // bottom of InkWell → Ink → Container → DefaultTextStyle → Row →
    // Flexible → Text, and checking only the immediate children reported
    // every button in the app as unnamed.
    var hasNamedDescendant = false;
    void look(SemanticsNode n) {
      if (hasNamedDescendant) return;
      n.visitChildren((child) {
        final childData = child.getSemanticsData();
        if (childData.label.trim().isNotEmpty ||
            childData.tooltip.trim().isNotEmpty ||
            childData.value.trim().isNotEmpty) {
          hasNamedDescendant = true;
          return false;
        }
        look(child);
        return true;
      });
    }

    look(node);

    // Above as well as below. A TextField's own node carries the label
    // while the EditableText inside it has the tap and no name of its
    // own, and a reader announces the two together -- so a leaf under a
    // named node is fine, and flagging it reported every text field in
    // the app as nameless.
    if (isTappable && !saysSomething && !hasNamedDescendant && !namedAbove) {
      found.add(node);
    }

    final namedHere = namedAbove || saysSomething;
    node.visitChildren((child) {
      walk(child, namedAbove: namedHere);
      return true;
    });
  }

  // From the app down, rather than from the binding's root pipeline
  // owner: that one's semanticsOwner is null, because the tree actually
  // hangs off the view's own owner.
  walk(tester.getSemantics(find.byType(MaterialApp)), namedAbove: false);
  return found;
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

  final screens = <String, Widget Function()>{
    'Explore': () => const Scaffold(body: ExploreScreen()),
    'Shell': () => const RootShell(),
    'Clinic': () => VetStationDetailScreen(station: _clinic()),
    'Booking': () => BookingScreen(station: _clinic(), services: _services),
    'Pets': () => const PetsScreen(),
    'PetDetail': () => PetDetailScreen(pet: samplePet()),
    'AddPet': () => const AddPetScreen(),
    'Appointments': () => const MyAppointmentsScreen(),
    'AppointmentDetail': () => AppointmentDetailScreen(appointment: sampleAppointment()),
    'Reschedule': () => RescheduleScreen(appointment: sampleAppointment()),
    'Profile': () => const ProfileScreen(),
    'EditProfile': () => const EditProfileScreen(),
    'Notifications': () => const NotificationsScreen(),
    'StaffProfile': () => StaffProfileScreen(staff: sampleStaff(), station: _clinic()),
    'Diagnostics': () => const DiagnosticsScreen(),
    'Login': () => const LoginScreen(),
    'Register': () => const RegisterScreen(),
    'VerifyAccount': () => const VerifyAccountScreen(userId: 42),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key}: every control says what it does', (tester) async {
      final handle = tester.ensureSemantics();
      useBackend(_healthy());

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(entry.value()));

      // Fixed frames rather than pumpAndSettle: the heroes drift and the
      // placeholders shimmer on a loop, so there is no quiet frame.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      final nameless = _namelessControls(tester);

      expect(
        nameless,
        isEmpty,
        reason: '${entry.key} has ${nameless.length} tappable node(s) a screen '
            'reader would announce as an unnamed button:\n'
            '${nameless.map((n) => '  ${n.getSemanticsData()}').join('\n')}',
      );

      handle.dispose();
    });
  }
}
