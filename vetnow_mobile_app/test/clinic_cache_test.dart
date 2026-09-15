// The clinic cache.
//
// Its whole job is to make the app open with content instead of a screen
// of skeletons — but it must never do that at the cost of showing
// something wrong. Ratings and opening hours go stale, so these tests
// are mostly about the cache refusing to answer when it shouldn't.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/services/clinic_cache.dart';

Map<String, dynamic> clinic({int id = 1, String name = 'Happy Paws'}) => {
      'id': id,
      'name': name,
      'contactNumber': '+387 33 123 456',
      'city': 'Sarajevo',
      'address': 'Ferhadija 15',
      'averageRating': 4.6,
      'reviewCount': 7,
      'isOpenNow': true,
      'inOffice': true,
      'onField': false,
      'parking': true,
      'wheelchair': false,
      'wifi': true,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing cached means nothing to show', () async {
    expect(await ClinicCache.read(), isNull);
  });

  test('a saved list comes back parsed', () async {
    await ClinicCache.save([clinic(), clinic(id: 2, name: 'PetCare')]);

    final read = await ClinicCache.read();
    expect(read, isNotNull);
    expect(read!.length, 2);
    expect(read.first.name, 'Happy Paws');
    // The fields the list actually renders have to survive the round trip.
    expect(read.first.rating, 4.6);
    expect(read.first.reviewCount, 7);
    expect(read.first.locationLine, 'Ferhadija 15, Sarajevo');
    expect(read.first.openNow, isTrue);
  });

  test('a stale entry is ignored rather than shown', () async {
    // A day-old "open now" is a guess, and a day-old score may be wrong.
    SharedPreferences.setMockInitialValues({
      'vetnow.cache.clinics': jsonEncode([clinic()]),
      'vetnow.cache.clinics.savedAt': DateTime.now()
          .subtract(ClinicCache.maxAge + const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });

    expect(await ClinicCache.read(), isNull);
  });

  test('an entry just inside the window is still served', () async {
    SharedPreferences.setMockInitialValues({
      'vetnow.cache.clinics': jsonEncode([clinic()]),
      'vetnow.cache.clinics.savedAt': DateTime.now()
          .subtract(ClinicCache.maxAge - const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });

    expect(await ClinicCache.read(), isNotNull);
  });

  test('a timestamp in the future is treated as unusable', () async {
    // A clock that moved backwards would otherwise make an old entry
    // look infinitely fresh.
    SharedPreferences.setMockInitialValues({
      'vetnow.cache.clinics': jsonEncode([clinic()]),
      'vetnow.cache.clinics.savedAt':
          DateTime.now().add(const Duration(days: 2)).millisecondsSinceEpoch,
    });

    expect(await ClinicCache.read(), isNull);
  });

  test('corrupt content behaves exactly like no cache', () async {
    SharedPreferences.setMockInitialValues({
      'vetnow.cache.clinics': 'not json at all',
      'vetnow.cache.clinics.savedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Never a crash on a cold start — this runs before the first frame.
    expect(await ClinicCache.read(), isNull);
  });

  test('content without a timestamp is not trusted', () async {
    SharedPreferences.setMockInitialValues({
      'vetnow.cache.clinics': jsonEncode([clinic()]),
    });

    expect(await ClinicCache.read(), isNull);
  });

  test('saving again replaces the previous list', () async {
    await ClinicCache.save([clinic(), clinic(id: 2)]);
    await ClinicCache.save([clinic(id: 3, name: 'Animal Wellness')]);

    final read = await ClinicCache.read();
    expect(read!.length, 1);
    expect(read.single.name, 'Animal Wellness');
  });

  test('clearing removes both the list and its timestamp', () async {
    await ClinicCache.save([clinic()]);
    await ClinicCache.clear();

    expect(await ClinicCache.read(), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('vetnow.cache.clinics'), isNull);
    expect(prefs.getInt('vetnow.cache.clinics.savedAt'), isNull);
  });
}
