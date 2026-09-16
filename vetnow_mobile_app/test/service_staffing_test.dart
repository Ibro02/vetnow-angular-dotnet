// Who gets offered for which service.
//
// The booking screen used to list the station's whole team for every
// service, so a groomer could be picked for a dental procedure and a vet
// for a nail trim. Neither happens in a real clinic, and the first to
// notice would have been the clinic.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/l10n/service_catalog.dart';
import 'package:vetnow_mobile/models/vet_service.dart';
import 'package:vetnow_mobile/models/vet_station.dart';
import 'package:vetnow_mobile/screens/booking_screen.dart';
import 'package:vetnow_mobile/services/employee_api_service.dart';
import 'package:vetnow_mobile/services/service_staffing.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('filterFor', () {
    test('grooming is the groomer\'s trade and nobody else\'s', () {
      expect(ServiceStaffing.filterFor(ServiceKind.grooming),
          StaffRoleFilter.groomers);
    });

    test('examinations and dentistry are a vet\'s work', () {
      expect(ServiceStaffing.filterFor(ServiceKind.checkup), StaffRoleFilter.vets);
      expect(ServiceStaffing.filterFor(ServiceKind.dental), StaffRoleFilter.vets);
    });

    test('vaccination admits nurses too', () {
      // Nurses give injections in every clinic there is.
      expect(ServiceStaffing.filterFor(ServiceKind.vaccination),
          StaffRoleFilter.vetsAndNurses);
    });

    test('an unknown service falls back to the whole team, not to nobody', () {
      // Anything from a future backend catalogue rather than this app's
      // four. Showing everyone is a poor filter; showing no one is a
      // dead end with no way out of it.
      expect(ServiceStaffing.filterFor(null), StaffRoleFilter.all);
    });
  });

  group('the booking screen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    tearDown(resetBackend);

    late FakeBackend backend;

    Map<String, dynamic> team(String first, int roleId, int id) => {
          'id': id,
          'firstName': first,
          'lastName': 'Test',
          'roleId': roleId,
        };

    FakeBackend healthy() => FakeBackend({
          // Role-specific endpoints first: FakeBackend matches on a path
          // substring in insertion order, and the general one would
          // otherwise swallow all of them.
          'Employee/GetVetsByVetStationId': (_) => {
                'dataItems': [team('Amina', 4, 1)],
              },
          'Employee/GetNursesByVetStationId': (_) => {
                'dataItems': [team('Selma', 3, 2)],
              },
          'Employee/GetBarbersByVetStationId': (_) => {
                'dataItems': [team('Lejla', 2, 3)],
              },
          'Employee/GetByVetStationId': (_) => {
                'dataItems': [
                  team('Amina', 4, 1),
                  team('Selma', 3, 2),
                  team('Lejla', 2, 3),
                ],
              },
          'Animal/GetByOwnerId': (_) => animals(),
          'SpeciesGetAll': (_) => speciesEnvelope(),
          'TimeSlot': (_) => <Map<String, dynamic>>[],
          'VetStation/OpeningHours': (_) =>
              {'vetStationId': 1, 'hasSchedule': false, 'days': <dynamic>[]},
        });

    Future<void> openBooking(WidgetTester tester, ServiceKind kind) async {
      backend = healthy();
      useBackend(backend);

      final rows = stations()['vetStations']! as List<dynamic>;
      final station = VetStation.fromJson(rows.first as Map<String, dynamic>);

      await usePhoneScreen(tester);
      await tester.pumpWidget(harness(
        Builder(
          builder: (context) => BookingScreen(
            station: station,
            services: [
              for (final k in ServiceKind.values) ServiceCatalog.service(context, k),
            ],
            preselected: ServiceCatalog.service(context, kind),
          ),
        ),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    testWidgets('offers only the groomer for grooming', (tester) async {
      await openBooking(tester, ServiceKind.grooming);

      expect(find.text('Lejla Test'), findsOneWidget);
      expect(find.text('Amina Test'), findsNothing);
      expect(find.text('Selma Test'), findsNothing);
    });

    testWidgets('offers only vets for a dental procedure', (tester) async {
      await openBooking(tester, ServiceKind.dental);

      expect(find.text('Amina Test'), findsOneWidget);
      expect(find.text('Lejla Test'), findsNothing);
    });

    testWidgets('offers vets and nurses for a vaccination', (tester) async {
      await openBooking(tester, ServiceKind.vaccination);

      expect(find.text('Amina Test'), findsOneWidget);
      expect(find.text('Selma Test'), findsOneWidget);
      expect(find.text('Lejla Test'), findsNothing);
    });

    testWidgets('changing the service changes who is on offer',
        (tester) async {
      await openBooking(tester, ServiceKind.dental);
      expect(find.text('Lejla Test'), findsNothing);

      await tester.tap(find.text('Šišanje i njega').first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      // And the vet is gone, rather than sitting there still selected
      // for a service they do not perform.
      expect(find.text('Lejla Test'), findsOneWidget);
      expect(find.text('Amina Test'), findsNothing);
    });
  });
}
