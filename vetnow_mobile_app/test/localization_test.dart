// The three .arb files, checked against each other and against the code.
//
// Two failures worth catching before a device does:
//
//   * A key present in one language and missing in another. The
//     generated class has no fallback worth the name — the screen shows
//     the wrong language or nothing — and it is exactly the mistake a
//     hurried translation pass makes.
//   * Strings nothing references. Eighteen had accumulated by the time
//     anyone looked: leftovers from an invented "top rated" sort, an
//     open-now filter, a staff-on-duty line. They are dead weight in the
//     binary and, worse, they read like features when someone opens the
//     file looking for what the app does.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _languages = ['bs', 'hr', 'sr'];

/// Message keys in one .arb, ignoring the `@key` metadata entries.
Set<String> _keysOf(String language) {
  final file = File('lib/l10n/app_$language.arb');
  final text = file.readAsStringSync();

  return RegExp(r'^\s*"([A-Za-z][A-Za-z0-9_]*)"\s*:', multiLine: true)
      .allMatches(text)
      .map((m) => m.group(1)!)
      .toSet();
}

/// Every Dart file that could reference a string.
///
/// Includes lib/l10n/service_catalog.dart, which is where the service and
/// role names are used; excludes only the generated app_localizations
/// files, which define the getters rather than calling them.
String _sources() {
  final buffer = StringBuffer();

  for (final root in ['lib', 'test']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('app_localizations')) continue;
      buffer.writeln(entity.readAsStringSync());
    }
  }

  return buffer.toString();
}

void main() {
  test('every language defines exactly the same keys', () {
    final byLanguage = {for (final l in _languages) l: _keysOf(l)};
    final all = byLanguage.values.expand((k) => k).toSet();

    final gaps = <String>[];
    for (final key in all) {
      final missing =
          _languages.where((l) => !byLanguage[l]!.contains(key)).toList();
      if (missing.isNotEmpty) gaps.add('$key — missing in ${missing.join(', ')}');
    }

    expect(gaps, isEmpty, reason: 'Translation gaps:\n${gaps.join('\n')}');
  });

  test('no string is defined and never used', () {
    final source = _sources();

    final unused = _keysOf('bs')
        .where((key) => !RegExp('\\b$key\\b').hasMatch(source))
        .toList()
      ..sort();

    expect(
      unused,
      isEmpty,
      reason: 'Defined but never referenced. Either wire them up or '
          'remove them from all three .arb files:\n${unused.join('\n')}',
    );
  });

  test('no string is left empty', () {
    // An empty value renders as a blank label rather than as an obvious
    // mistake, so it survives a visual check.
    final blanks = <String>[];

    for (final language in _languages) {
      final text = File('lib/l10n/app_$language.arb').readAsStringSync();
      final matches = RegExp(
        r'^\s*"([A-Za-z][A-Za-z0-9_]*)"\s*:\s*"\s*"',
        multiLine: true,
      ).allMatches(text);

      for (final m in matches) {
        blanks.add('${m.group(1)} in $language');
      }
    }

    expect(blanks, isEmpty, reason: 'Empty strings:\n${blanks.join('\n')}');
  });

  test('every arb file is valid JSON and ends where it should', () {
    // This suite did not catch a truncation that shipped.
    //
    // A tooling pass cut 162 lines off the end of all three .arb files.
    // The checks above compare the languages against each other, and
    // since all three were cut identically their key sets still matched
    // -- "every language defines the same keys" was true of three
    // equally broken files. The unused-string check passed for the same
    // reason: fewer strings, all of them still referenced.
    //
    // And the whole suite stayed green because the generated
    // app_localizations*.dart had been written before the cut and still
    // held every string. Nothing noticed until `flutter build` ran
    // gen-l10n again and refused the file.
    //
    // So: each file is parsed on its own terms here, against no one but
    // itself.
    for (final locale in _languages) {
      final file = File('lib/l10n/app_$locale.arb');
      final raw = file.readAsStringSync();

      expect(
        raw.trimRight().endsWith('}'),
        isTrue,
        reason: 'app_$locale.arb does not end with a closing brace -- '
            'it looks truncated',
      );

      expect(
        () => jsonDecode(raw),
        returnsNormally,
        reason: 'app_$locale.arb is not valid JSON',
      );
    }
  });

  test('no language has lost strings the others kept', () {
    // The count is asserted against a floor rather than a fixed number:
    // strings get added all the time, and a test that has to be edited
    // on every addition gets edited without being read.
    for (final locale in _languages) {
      final keys = _keysOf(locale);
      expect(
        keys.length,
        greaterThan(250),
        reason: 'app_$locale.arb has only ${keys.length} strings, which is '
            'far fewer than this app has screens for -- something removed '
            'them',
      );
    }
  });
}
