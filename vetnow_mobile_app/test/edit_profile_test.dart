// The edit-profile screen's behaviour around a rejected save.
//
// The rules themselves are covered in profile_validation_test.dart. What
// is tested here is what the screen does with them: the field goes red,
// the message appears under it, nothing is sent, and the complaint goes
// away as soon as someone starts fixing it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/screens/edit_profile_screen.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(resetBackend);

  FakeBackend healthy() => FakeBackend({
        'ProfileSettings/Get': (_) => {
              'firstName': 'Amir',
              'lastName': 'Hadžić',
              'phone': '+387 61 234 567',
              'email': 'amir.hadzic@vetnow.ba',
              'city': 'Sarajevo',
              'country': 'Bosna i Hercegovina',
              'address': 'Zmaja od Bosne 4',
            },
        'ProfileSettings/Edit': (_) => {'ok': true},
      });

  late FakeBackend backend;

  Future<void> openForm(WidgetTester tester) async {
    backend = healthy();
    useBackend(backend);
    await usePhoneScreen(tester);
    await tester.pumpWidget(harness(const EditProfileScreen()));
    await tester.pumpAndSettle();
  }

  /// The button sits below the fold on a phone, and the form is a
  /// lazy ListView, so it is not built until it is scrolled to.
  Future<void> tapSave(WidgetTester tester) async {
    await scrollToBottom(tester);
    await tester.tap(find.text('Sačuvaj izmjene'));
    await tester.pumpAndSettle();
  }

  int savesSent() =>
      backend.calls.where((c) => c.url.path.contains('ProfileSettings/Edit')).length;

  testWidgets('loads the account into the form', (tester) async {
    await openForm(tester);

    expect(find.text('Amir'), findsOneWidget);
    expect(find.text('amir.hadzic@vetnow.ba'), findsOneWidget);
  });

  testWidgets('an emptied name is refused before anything is sent',
      (tester) async {
    await openForm(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Amir'), '');
    await tapSave(tester);

    // The message is under the field, in the app's language, not in a
    // grey bar at the bottom of the screen in English.
    expect(find.text('Unesi ime'), findsOneWidget);
    expect(savesSent(), 0);
  });

  testWidgets('the complaint clears as soon as it is being fixed',
      (tester) async {
    await openForm(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Amir'), '');
    await tapSave(tester);
    expect(find.text('Unesi ime'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Amir');
    await tester.pumpAndSettle();

    // Not left red while somebody is actively dealing with it.
    expect(find.text('Unesi ime'), findsNothing);
  });

  testWidgets('several problems are all reported at once', (tester) async {
    await openForm(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Amir'), '');
    await tester.enterText(find.widgetWithText(TextField, 'Hadžić'), '');
    await tester.enterText(
        find.widgetWithText(TextField, 'amir.hadzic@vetnow.ba'), 'nije-email');
    await tapSave(tester);

    expect(find.text('Unesi ime'), findsOneWidget);
    expect(find.text('Unesi prezime'), findsOneWidget);
    expect(find.text('Ovo ne izgleda kao email adresa'), findsOneWidget);
    expect(savesSent(), 0);
  });

  testWidgets('a blank password is not a problem', (tester) async {
    // Empty means "keep the current one" -- that is the whole contract
    // of the field, so it must not block a save.
    await openForm(tester);

    await tapSave(tester);

    expect(savesSent(), 1);
  });

  testWidgets('a good form still saves', (tester) async {
    await openForm(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Amir'), 'Amira');
    await tapSave(tester);

    expect(savesSent(), 1);
  });
}
