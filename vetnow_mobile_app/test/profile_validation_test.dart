// The rules the edit-profile form applies before anything is sent.
//
// There was no client-side checking at all until now. Clearing a name
// and pressing save sent it, and the backend's refusal came back as an
// English sentence in a grey bar at the bottom of the screen — in an app
// that speaks Bosnian, Croatian and Serbian, with no indication of which
// field it was about.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/l10n/app_localizations.dart';
import 'package:vetnow_mobile/services/profile_validation.dart';

void main() {
  late AppLocalizations bs;

  setUpAll(() async {
    bs = await AppLocalizations.delegate.load(const Locale('bs'));
  });

  Map<ProfileField, String> check({
    String firstName = 'Amir',
    String lastName = 'Hadžić',
    String email = 'amir@vetnow.ba',
    String phone = '+387 61 234 567',
    String password = '',
  }) =>
      validateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        l10n: bs,
      );

  test('a filled-in form passes', () {
    expect(check(), isEmpty);
  });

  group('names', () {
    test('an empty first name is rejected', () {
      expect(check(firstName: '').keys, contains(ProfileField.firstName));
    });

    test('whitespace is not a name', () {
      // The screen trims before sending, so "   " would have arrived at
      // the backend as an empty string anyway.
      expect(check(firstName: '   ').keys, contains(ProfileField.firstName));
    });

    test('a single letter is rejected', () {
      expect(check(lastName: 'H').keys, contains(ProfileField.lastName));
    });

    test('two letters are enough', () {
      // Deliberately not five. Real short names exist -- Bo, Li, An --
      // and a form that refuses somebody's actual name is worse than one
      // that accepts a typo.
      expect(check(firstName: 'Bo', lastName: 'Li'), isEmpty);
    });

    test('diacritics count as letters', () {
      expect(check(firstName: 'Đžana', lastName: 'Šišić'), isEmpty);
    });
  });

  group('email', () {
    test('an empty address is rejected', () {
      expect(check(email: '').keys, contains(ProfileField.email));
    });

    for (final bad in [
      'amir',
      'amir@',
      '@vetnow.ba',
      'amir@vetnow',
      'amir@@vetnow.ba',
      'amir vetnow@x.ba',
      'amir@.ba',
      'amir@vetnow.',
    ]) {
      test('"$bad" is rejected', () {
        expect(check(email: bad).keys, contains(ProfileField.email));
      });
    }

    for (final good in [
      'a@b.co',
      'amir.hadzic@vetnow.ba',
      'amir+vet@mail.example.com',
      'AMIR@VETNOW.BA',
    ]) {
      test('"$good" is accepted', () {
        expect(check(email: good), isEmpty);
      });
    }
  });

  group('phone', () {
    test('is optional', () {
      // Plenty of accounts have none, and demanding one in order to fix
      // a surname would be absurd.
      expect(check(phone: ''), isEmpty);
    });

    test('accepts the shapes people actually type', () {
      for (final good in ['+387 61 234 567', '033/123-456', '(033) 123 456', '061234567']) {
        expect(check(phone: good), isEmpty, reason: good);
      }
    });

    test('rejects letters', () {
      expect(check(phone: 'zovi me').keys, contains(ProfileField.phone));
    });

    test('rejects too few digits', () {
      expect(check(phone: '+387').keys, contains(ProfileField.phone));
    });
  });

  group('password', () {
    test('blank means keep the current one, not an error', () {
      expect(check(password: ''), isEmpty);
    });

    test('a short one is rejected', () {
      expect(check(password: 'abc').keys, contains(ProfileField.password));
    });

    test('eight characters are enough', () {
      expect(check(password: 'dovoljno'), isEmpty);
    });
  });

  test('every problem is reported at once, not one at a time', () {
    // The reason this is a function returning a map rather than a set of
    // Form validators: stopping at the first failure makes someone fix a
    // field, press save, and meet the next one. Four times over.
    final problems = check(
      firstName: '',
      lastName: '',
      email: 'nope',
      phone: 'zovi me',
      password: 'abc',
    );

    expect(problems.keys, hasLength(5));
  });

  test('every message is in the app language, not English', () {
    final problems = check(firstName: '', email: 'nope');

    for (final message in problems.values) {
      expect(message, isNotEmpty);
      expect(
        RegExp(r'\b(must|required|invalid|please|enter|least)\b', caseSensitive: false)
            .hasMatch(message),
        isFalse,
        reason: 'looks like English: "$message"',
      );
    }
  });
}
