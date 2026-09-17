import 'dart:async';

import 'package:flutter/foundation.dart';

import 'crash_log.dart';

/// Parses a list of JSON rows, dropping the ones that cannot be read.
///
/// Every list in this app used to be parsed with `list.map(Model.fromJson)`,
/// which is all-or-nothing: one clinic with a null id threw a TypeError
/// out of the whole request, and the screen showed a connection error
/// over nine clinics that were perfectly fine. That is the wrong trade.
/// A row nobody can read is one missing row; a list nobody can read is a
/// broken app.
///
/// The dropped rows are not swallowed silently — each one goes to the
/// crash log with the context it came from, so "the list is one short"
/// remains something that can be investigated rather than a mystery.
///
/// Deliberately not applied to single-object responses. If the clinic you
/// tapped cannot be parsed, there is nothing to show and failing is the
/// honest answer.
List<T> parseRows<T>(
  Object? source,
  T Function(Map<String, dynamic> row) parse, {
  required String context,
}) {
  if (source is! List) return const [];

  final parsed = <T>[];
  var dropped = 0;

  for (final row in source) {
    if (row is! Map<String, dynamic>) {
      dropped++;
      continue;
    }

    try {
      parsed.add(parse(row));
    } catch (error, stack) {
      dropped++;
      // Recorded rather than rethrown. Not awaited: the caller is a
      // parser with a screen waiting on it, and writing the log is
      // housekeeping.
      if (kDebugMode) {
        debugPrint('$context: dropped a row that would not parse — $error');
      }
      unawaited(CrashLog.record(
        error,
        stack,
        context: '$context.row',
      ));
    }
  }

  if (dropped > 0 && kDebugMode) {
    debugPrint('$context: $dropped of ${source.length} rows dropped');
  }

  return parsed;
}
