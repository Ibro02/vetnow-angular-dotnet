// Guards the source against being re-encoded.
//
// This exists because it happened. A tooling pass rewrote
// lib/screens/login_screen.dart and turned the paw print in the sign-in
// tagline into four accented letters of noise — text that ships,
// renders, and looks like the app is broken, while the analyzer,
// every other test and the build all stay perfectly green.
//
// The mangled form is deliberately not written out here: this file
// scans itself along with everything else, so an example in a
// comment would be a permanent false positive.
//
// Mojibake is UTF-8 that has been encoded twice: the bytes of "🐾"
// (F0 9F 90 BE) each get treated as a separate Latin-1 character and
// re-encoded, giving C3 B0 C2 9F C2 90 C2 BE. The giveaway is a C3 or C2
// lead byte followed by C2 continuations, which never happens in
// correctly encoded text — so it can be looked for directly.
//
// The strings are also full of Bosnian diacritics and em dashes, so this
// is not a theoretical risk.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// C3/C2 lead followed by one or more C2 continuations.
final _doubleEncoded = RegExp(r'[\xc3\xc2][\x80-\xbf](?:\xc2[\x80-\xbf])+');

Iterable<File> _sourceFiles() sync* {
  for (final root in ['lib', 'test', 'docs']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!RegExp(r'\.(dart|arb|md|yaml)$').hasMatch(entity.path)) continue;
      yield entity;
    }
  }
}

void main() {
  test('no source file has been double-encoded', () {
    final damaged = <String>[];

    for (final file in _sourceFiles()) {
      // Read as raw bytes mapped one-to-one onto characters, so the
      // pattern above matches byte values rather than decoded text.
      final raw = String.fromCharCodes(file.readAsBytesSync());

      for (final match in _doubleEncoded.allMatches(raw)) {
        final line = '\n'.allMatches(raw.substring(0, match.start)).length + 1;
        damaged.add('${file.path}:$line');
      }
    }

    expect(
      damaged,
      isEmpty,
      reason: 'Double-encoded UTF-8 found. Something rewrote these files '
          'without preserving their encoding:\n${damaged.join('\n')}',
    );
  });

  test('every source file is valid UTF-8', () {
    // A stricter check, and a cheaper one to reason about: if a file no
    // longer decodes, something has mangled it regardless of how.
    final broken = <String>[];

    for (final file in _sourceFiles()) {
      try {
        file.readAsStringSync();
      } on FileSystemException {
        broken.add(file.path);
      } on FormatException {
        broken.add(file.path);
      }
    }

    expect(broken, isEmpty, reason: 'Not valid UTF-8:\n${broken.join('\n')}');
  });
}
