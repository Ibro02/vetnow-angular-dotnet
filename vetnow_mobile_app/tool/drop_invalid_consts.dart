// One-off migration helper, kept so the change is reproducible.
//
// Making the neutral colours resolve per theme turned them from compile
// time constants into getters, which invalidates every `const` widget
// that read one — 175 of them. The analyzer knows exactly where each is,
// so this drives off that rather than off a regex over the source.
//
// For every `invalid_constant` it removes the nearest `const` keyword
// before the reported position and re-analyzes, because removing one can
// reveal another nested inside it. Over-removal is safe: a `const` that
// was still valid comes back as a lint, and `dart fix --apply` restores
// it afterwards.
//
//   dart run tool/drop_invalid_consts.dart
//   dart fix --apply

import 'dart:io';

void main() async {
  for (var pass = 1; pass <= 12; pass++) {
    final errors = await _invalidConstants();
    if (errors.isEmpty) {
      stdout.writeln('pass $pass: clean');
      return;
    }

    stdout.writeln('pass $pass: ${errors.length} invalid constants');

    // Group by file, and work from the end of each file backwards so
    // earlier offsets stay valid while we edit.
    final byFile = <String, List<int>>{};
    for (final e in errors) {
      byFile.putIfAbsent(e.path, () => []).add(e.offset);
    }

    byFile.forEach((path, offsets) {
      final file = File(path);
      var source = file.readAsStringSync();

      offsets.sort();
      for (final offset in offsets.reversed) {
        final at = _nearestConstBefore(source, offset);
        if (at == null) continue;
        source = source.replaceRange(at, at + 'const '.length, '');
      }

      file.writeAsStringSync(source);
    });
  }

  stderr.writeln('gave up after 12 passes — something is not converging');
  exit(1);
}

/// Walks back from [offset] to the closest `const ` keyword.
int? _nearestConstBefore(String source, int offset) {
  final index = source.lastIndexOf('const ', offset);
  if (index < 0) return null;

  // Must be a standalone keyword, not the tail of an identifier.
  if (index > 0) {
    final before = source[index - 1];
    if (RegExp(r'[A-Za-z0-9_$]').hasMatch(before)) {
      return _nearestConstBefore(source, index - 1);
    }
  }
  return index;
}

class _Error {
  final String path;
  final int offset;
  _Error(this.path, this.offset);
}

Future<List<_Error>> _invalidConstants() async {
  // Machine format is stable and gives byte offsets, which is what makes
  // this precise rather than a guess at line and column.
  final result = await Process.run(
    'dart',
    ['analyze', '--format=machine', 'lib'],
    runInShell: true,
  );

  final out = '${result.stdout}';
  final errors = <_Error>[];

  for (final line in out.split('\n')) {
    final parts = line.trim().split('|');
    // SEVERITY|TYPE|CODE|FILE|LINE|COL|LENGTH|MESSAGE
    if (parts.length < 7) continue;
    if (parts[2] != 'INVALID_CONSTANT') continue;

    final path = parts[3];
    final lineNo = int.tryParse(parts[4]);
    final col = int.tryParse(parts[5]);
    if (lineNo == null || col == null) continue;

    errors.add(_Error(path, _offsetOf(path, lineNo, col)));
  }

  return errors;
}

final _fileCache = <String, List<String>>{};

int _offsetOf(String path, int line, int col) {
  final lines = _fileCache.putIfAbsent(
    path,
    () => File(path).readAsStringSync().split('\n'),
  );

  var offset = 0;
  for (var i = 0; i < line - 1 && i < lines.length; i++) {
    offset += lines[i].length + 1;
  }
  return offset + col - 1;
}
