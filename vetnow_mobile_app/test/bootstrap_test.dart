// main() itself.
//
// Every other test pumps VetNowApp directly, which skips the code that
// actually runs when someone taps the icon: installing the error
// handlers, starting the deep-link listener, calling runApp. That is the
// least covered code in the app and has the worst failure mode — if it
// throws, there is no app left to show an error in.
//
// main() is called exactly once here, in the first test. Calling it
// again in the same file leaves the previous run's tickers alive, the
// test clock then goes backwards between tests, and AnimationController
// asserts — a failure about the harness rather than about the app.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/main.dart' as entrypoint;
import 'package:vetnow_mobile/main.dart';
import 'package:vetnow_mobile/services/crash_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('main() starts the app and settles onto a screen',
      (tester) async {
    entrypoint.main();

    // Fixed frames rather than pumpAndSettle: the hero texture animates
    // forever by design, so there is no quiet moment to settle into.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    expect(find.byType(VetNowApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Installed by main(), before the first frame. Returning true is what
    // keeps a stray future from taking the isolate down — closing the app
    // on someone over a bug they cannot act on is the worst available
    // response to it.
    final handler = PlatformDispatcher.instance.onError;
    expect(handler, isNotNull);
    expect(handler!(StateError('stray future'), StackTrace.current), isTrue);
  });

  testWidgets('a widget that throws during build is recorded, not lost',
      (tester) async {
    await CrashLog.clear();
    final before = FlutterError.onError;
    CrashLog.install();

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (_) => throw StateError('build blew up')),
    ));
    await tester.pump();

    // The framework surfaces it to the test as well; consume it so the
    // test does not fail on the error it deliberately caused.
    tester.takeException();

    final entries = await CrashLog.read();
    expect(entries, isNotEmpty);
    expect(entries.first.error, contains('build blew up'));
    expect(entries.first.fatal, isTrue);

    FlutterError.onError = before;
  });

  testWidgets('a broken widget leaves the rest of the screen alone',
      (tester) async {
    // In release the red panel is replaced by an empty box, so one failed
    // badge cannot take a whole clinic page down with it. In debug the
    // red panel stays — that panel is how a bug gets found — so this
    // asserts the surrounding content rather than the replacement.
    final before = FlutterError.onError;
    CrashLog.install();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const Text('above'),
            Builder(builder: (_) => throw StateError('nope')),
            const Text('below'),
          ],
        ),
      ),
    ));
    await tester.pump();
    tester.takeException();

    expect(find.text('above'), findsOneWidget);
    expect(find.text('below'), findsOneWidget);

    FlutterError.onError = before;
  });
}
