import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_info.dart';

/// One recorded failure.
class CrashEntry {
  final DateTime at;

  /// Where it happened — "Explore.load", "booking.confirm". Free text,
  /// written by whoever caught it.
  final String context;

  final String error;
  final String stack;

  /// False for anything caught and handled. A dropped request is worth
  /// recording and is not a crash; separating the two keeps the real
  /// ones findable.
  final bool fatal;

  const CrashEntry({
    required this.at,
    required this.context,
    required this.error,
    required this.stack,
    required this.fatal,
  });

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'context': context,
        'error': error,
        'stack': stack,
        'fatal': fatal,
      };

  static CrashEntry? fromJson(Map<String, dynamic> json) {
    final at = DateTime.tryParse(json['at'] as String? ?? '');
    if (at == null) return null;
    return CrashEntry(
      at: at,
      context: json['context'] as String? ?? '',
      error: json['error'] as String? ?? '',
      stack: json['stack'] as String? ?? '',
      fatal: json['fatal'] as bool? ?? false,
    );
  }
}

/// Keeps the last handful of failures on the device so they can be read
/// back later.
///
/// This is not Crashlytics and does not pretend to be: nothing is sent
/// anywhere, because sending needs a service account that does not exist
/// yet. What it does solve is the thing that actually blocks fixing a bug
/// someone reports — "it crashed" with no idea where. The diagnostics
/// screen reads this back and copies it to the clipboard, so a report
/// arrives with a stack trace attached.
///
/// When a Sentry or Crashlytics project does exist, [onRecord] is the one
/// place to hook it up; everything else stays as it is.
class CrashLog {
  CrashLog._();

  static const _key = 'vetnow.crash.log';

  /// Ten is enough to see a pattern and small enough that writing it back
  /// on every error stays cheap. Oldest is dropped first.
  static const int maxEntries = 10;

  /// Called for every recorded failure, after it is stored. Left null in
  /// the app; the seam for an upload later.
  static void Function(CrashEntry entry)? onRecord;

  static Future<void> record(
    Object error,
    StackTrace? stack, {
    String context = '',
    bool fatal = false,
  }) async {
    final entry = CrashEntry(
      at: DateTime.now(),
      context: context,
      error: error.toString(),
      // Full traces run to hundreds of lines and the useful part is at
      // the top; the rest is framework plumbing identical in every report.
      stack: _trim(stack),
      fatal: fatal,
    );

    // Always visible while developing, whatever the storage does.
    if (kDebugMode) {
      debugPrint('CrashLog${context.isEmpty ? '' : ' [$context]'}: $error');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = await read();
      final next = [entry, ...existing].take(maxEntries).toList();
      await prefs.setString(
        _key,
        jsonEncode(next.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // A log that cannot write must not become the thing that crashes.
    }

    try {
      onRecord?.call(entry);
    } catch (_) {
      // Same reasoning: a broken reporter is not worth a second failure.
    }
  }

  static Future<List<CrashEntry>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CrashEntry.fromJson)
          .whereType<CrashEntry>()
          .toList();
    } catch (_) {
      // Corrupt or half-written: an unreadable log is the same as none.
      return const [];
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Nothing to do — the next write overwrites it anyway.
    }
  }

  /// The whole log as one block of text, ready to paste into a message.
  ///
  /// Carries the build it came from: a stack trace without a version is
  /// guesswork about which code it belongs to.
  static Future<String> export() async {
    final entries = await read();
    final buffer = StringBuffer()
      ..writeln('VetNow ${AppInfo.fullVersion}')
      ..writeln('API: ${AppInfo.apiHost}')
      ..writeln('Records: ${entries.length}')
      ..writeln();

    for (final e in entries) {
      buffer
        ..writeln('--- ${e.at.toIso8601String()}'
            '${e.fatal ? ' (fatal)' : ''}'
            '${e.context.isEmpty ? '' : ' @ ${e.context}'}')
        ..writeln(e.error);
      if (e.stack.isNotEmpty) buffer.writeln(e.stack);
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _trim(StackTrace? stack) {
    if (stack == null) return '';
    final lines = stack.toString().split('\n');
    return lines.take(12).join('\n').trim();
  }

  /// Routes every uncaught failure in the app into this log.
  ///
  /// Three separate channels have to be covered, and missing any one of
  /// them means a whole class of crash goes unrecorded:
  ///
  ///  * [FlutterError.onError] — exceptions thrown during build, layout
  ///    or paint.
  ///  * [PlatformDispatcher.instance.onError] — asynchronous errors that
  ///    escaped every zone, which is most of what a forgotten `await`
  ///    produces.
  ///  * [ErrorWidget.builder] — not an error channel but the thing the
  ///    person sees. Flutter's default is a full-screen red panel with a
  ///    Dart exception on it, which in a shipped app reads as the app
  ///    being broken beyond use.
  ///
  /// Call before `runApp`.
  static void install() {
    final previous = FlutterError.onError;

    FlutterError.onError = (details) {
      previous?.call(details);
      unawaited(record(
        details.exception,
        details.stack,
        context: details.context?.toString() ?? 'flutter',
        fatal: true,
      ));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(record(error, stack, context: 'uncaught', fatal: true));
      // Handled: the log has it, and letting it kill the isolate would
      // close the app on the person for something they cannot act on.
      return true;
    };

    // Kept red and loud in debug — that panel is how you find the bug.
    if (!kDebugMode) {
      // Not an empty box for its own sake: it occupies the space the
      // broken widget would have and says nothing, so a rating badge
      // that failed to build does not take the clinic page down with
      // it. The failure is in the log either way.
      ErrorWidget.builder = (_) => const SizedBox.shrink();
    }
  }
}
