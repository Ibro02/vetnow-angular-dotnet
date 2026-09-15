import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vet_station.dart';

/// Remembers the last clinic list so the app has something to show the
/// instant it opens.
///
/// Explore used to start empty and wait for the network every single
/// time — on a slow connection that is several seconds of skeletons
/// before the first clinic appears, on every launch, for a list that
/// rarely changes. Now the last result is painted immediately and the
/// fresh one replaces it when it lands.
///
/// Two rules keep that honest:
///
/// * Cached clinics are only shown while they are recent. Ratings and
///   opening hours go stale, and a day-old "open now" is a guess, so
///   anything older than [maxAge] is ignored rather than shown.
/// * The cache is a head start, never an answer. A request still goes
///   out on every open; this only decides what fills the screen until
///   it returns.
class ClinicCache {
  ClinicCache._();

  static const _key = 'vetnow.cache.clinics';
  static const _savedAtKey = 'vetnow.cache.clinics.savedAt';

  /// Long enough to cover "I open this most days", short enough that a
  /// clinic's score or hours can't be badly out of date.
  static const maxAge = Duration(hours: 12);

  static Future<void> save(List<Map<String, dynamic>> raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(raw));
      await prefs.setInt(_savedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // A cache that fails to write is a missing optimisation, never an
      // error worth surfacing — the live request is still on its way.
    }
  }

  /// The last saved list, or null when there is none, it is too old, or
  /// it cannot be read.
  static Future<List<VetStation>?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedAt = prefs.getInt(_savedAtKey);
      if (savedAt == null) return null;

      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
      // A clock moved backwards makes `age` negative; treat that as
      // unusable rather than as infinitely fresh.
      if (age.isNegative || age > maxAge) return null;

      final stored = prefs.getString(_key);
      if (stored == null || stored.isEmpty) return null;

      final decoded = jsonDecode(stored);
      if (decoded is! List) return null;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VetStation.fromJson)
          .toList();
    } catch (_) {
      // Corrupt or unreadable cache behaves exactly like no cache.
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_savedAtKey);
    } catch (_) {
      // Nothing to do; a stale entry ages out on its own.
    }
  }
}
