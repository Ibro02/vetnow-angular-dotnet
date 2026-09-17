// The on-device failure log.
//
// Everything here is written on the unhappy path, which is exactly where
// a bug in the logging itself is most expensive: a crash reporter that
// throws turns one failure into two and loses the first one. So the cases
// below are mostly about what happens when things are already wrong —
// corrupt storage, a half-written file, a reporter that itself blows up.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetnow_mobile/config/app_info.dart';
import 'package:vetnow_mobile/services/crash_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CrashLog.onRecord = null;
  });

  tearDown(() => CrashLog.onRecord = null);

  group('recording', () {
    test('an error is kept with where it came from', () async {
      await CrashLog.record(
        StateError('slot already taken'),
        StackTrace.current,
        context: 'booking.confirm',
        fatal: false,
      );

      final entries = await CrashLog.read();
      expect(entries, hasLength(1));
      expect(entries.single.error, contains('slot already taken'));
      expect(entries.single.context, 'booking.confirm');
      expect(entries.single.fatal, isFalse);
      expect(entries.single.stack, isNotEmpty);
    });

    test('newest first — a report is read from the top', () async {
      await CrashLog.record('first', null);
      await CrashLog.record('second', null);
      await CrashLog.record('third', null);

      final entries = await CrashLog.read();
      expect(entries.map((e) => e.error), ['third', 'second', 'first']);
    });

    test('it stops growing, dropping the oldest', () async {
      for (var i = 0; i < CrashLog.maxEntries + 5; i++) {
        await CrashLog.record('error $i', null);
      }

      final entries = await CrashLog.read();
      expect(entries, hasLength(CrashLog.maxEntries));
      expect(entries.first.error, 'error ${CrashLog.maxEntries + 4}');
      expect(entries.last.error, 'error 5');
    });

    test('a long stack is trimmed to the part anyone reads', () async {
      final long = StackTrace.fromString(
        List.generate(300, (i) => '#$i  Frame.method (file.dart:$i)').join('\n'),
      );

      await CrashLog.record('boom', long);

      final stack = (await CrashLog.read()).single.stack;
      expect('\n'.allMatches(stack).length, lessThan(20));
      expect(stack, startsWith('#0'));
    });

    test('a crash and a handled failure are told apart', () async {
      await CrashLog.record('handled', null, fatal: false);
      await CrashLog.record('crash', null, fatal: true);

      final entries = await CrashLog.read();
      expect(entries.firstWhere((e) => e.error == 'crash').fatal, isTrue);
      expect(entries.firstWhere((e) => e.error == 'handled').fatal, isFalse);
    });
  });

  group('when things are already broken', () {
    test('a corrupt log reads as empty rather than throwing', () async {
      SharedPreferences.setMockInitialValues({
        'vetnow.crash.log': 'not json at all {{{',
      });

      expect(await CrashLog.read(), isEmpty);
    });

    test('so does a log holding the wrong shape', () async {
      SharedPreferences.setMockInitialValues({
        'vetnow.crash.log': '{"entries": 3}',
      });

      expect(await CrashLog.read(), isEmpty);
    });

    test('an entry with no usable timestamp is skipped, the rest survive',
        () async {
      SharedPreferences.setMockInitialValues({
        'vetnow.crash.log':
            '[{"at":"not-a-date","error":"junk"},'
            '{"at":"2026-09-15T09:00:00.000","error":"real","context":"",'
            '"stack":"","fatal":true}]',
      });

      final entries = await CrashLog.read();
      expect(entries, hasLength(1));
      expect(entries.single.error, 'real');
    });

    test('a reporter that throws does not become the second failure',
        () async {
      CrashLog.onRecord = (_) => throw StateError('the reporter is down too');

      // The point: this call completes, and the entry is still stored.
      await CrashLog.record('original problem', null);

      expect((await CrashLog.read()).single.error, 'original problem');
    });
  });

  group('the report that gets pasted into a message', () {
    test('names the build, so a stack trace belongs to known code',
        () async {
      await CrashLog.record('boom', null, context: 'explore.load');

      final report = await CrashLog.export();
      expect(report, contains(AppInfo.fullVersion));
      expect(report, contains(AppInfo.apiHost));
      expect(report, contains('boom'));
      expect(report, contains('explore.load'));
    });

    test('an empty log still produces something readable', () async {
      final report = await CrashLog.export();
      expect(report, contains(AppInfo.fullVersion));
      expect(report, contains('0'));
    });
  });

  group('clearing', () {
    test('leaves nothing behind', () async {
      await CrashLog.record('boom', null);
      await CrashLog.clear();

      expect(await CrashLog.read(), isEmpty);
    });
  });

  group('the hook for a real crash service', () {
    test('fires once per record, with what was stored', () async {
      final seen = <CrashEntry>[];
      CrashLog.onRecord = seen.add;

      await CrashLog.record('boom', null, context: 'x', fatal: true);

      expect(seen, hasLength(1));
      expect(seen.single.error, 'boom');
      expect(seen.single.fatal, isTrue);
    });
  });

  group('build identity', () {
    test('AppInfo still matches pubspec.yaml', () {
      // The version in a crash report is only useful if it is the version
      // that actually shipped. This is the cheap way to keep the constant
      // and the manifest from drifting apart.
      final pubspec = _pubspecVersion();
      expect(pubspec, isNotNull, reason: 'no version: line in pubspec.yaml');

      final parts = pubspec!.split('+');
      expect(AppInfo.version, parts.first);
      expect(AppInfo.build.toString(), parts.length > 1 ? parts[1] : '1');
    });
  });
}

String? _pubspecVersion() {
  // Relative to the package root, which is where `flutter test` runs.
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return null;

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('version:')) {
      return line.substring('version:'.length).trim();
    }
  }
  return null;
}
