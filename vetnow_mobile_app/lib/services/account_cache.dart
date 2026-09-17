import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last pets and appointments this account saw, so the app has
/// something to show without a connection.
///
/// ClinicCache has done this for Explore for a while, and it stops there
/// — which meant a phone on a lift, in a basement or out of credit
/// opened Pets and Termini to an error page, on data the app had
/// downloaded and then thrown away. Someone standing at a clinic
/// counter wanting to check when their appointment is has exactly the
/// wrong problem.
///
/// The rules that keep it honest are the ones ClinicCache set:
///
///  * A request still goes out every time. This only decides what fills
///    the screen while it is in flight, and what remains if it fails.
///  * Anything older than [maxAge] is ignored rather than shown. An
///    appointment list from last week is not a helpful thing to be
///    looking at.
///  * Per account. Two people sharing a phone must not see each other's
///    animals, and a signed-out session must not leave them on disk.
class AccountCache {
  AccountCache._();

  /// Long enough to cover a few days away from signal, short enough that
  /// a cancelled visit cannot sit there looking booked indefinitely.
  static const maxAge = Duration(days: 3);

  static String _key(String what, int userId) => 'vetnow.cache.$what.$userId';
  static String _savedAtKey(String what, int userId) =>
      'vetnow.cache.$what.$userId.savedAt';

  /// Stores [rows] exactly as the backend sent them.
  ///
  /// Raw JSON rather than mapped objects, deliberately: the mapping
  /// needs species and breed names that are fetched separately, and a
  /// cache that had to wait for those would be storing a join it may
  /// never be able to repeat offline.
  static Future<void> save(
    String what,
    int userId,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(what, userId), jsonEncode(rows));
      await prefs.setInt(
        _savedAtKey(what, userId),
        clock.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // A cache that will not write is a missing head start, never an
      // error worth showing: the live request is already on its way.
    }
  }

  /// The last saved rows, or null when there are none, they are too old,
  /// or they cannot be read.
  static Future<List<Map<String, dynamic>>?> read(String what, int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedAt = prefs.getInt(_savedAtKey(what, userId));
      if (savedAt == null) return null;

      final age =
          clock.now().difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
      // A clock moved backwards makes the age negative; that is unusable
      // rather than infinitely fresh.
      if (age.isNegative || age > maxAge) return null;

      final stored = prefs.getString(_key(what, userId));
      if (stored == null || stored.isEmpty) return null;

      final decoded = jsonDecode(stored);
      if (decoded is! List) return null;

      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      // A corrupt cache behaves exactly like no cache.
      return null;
    }
  }

  /// Forgets everything held for one account.
  ///
  /// Called on sign-out. Leaving somebody's pets on a shared phone after
  /// they have signed out is not a caching decision, it is a leak.
  static Future<void> clearFor(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final what in const ['pets', 'appointments']) {
        await prefs.remove(_key(what, userId));
        await prefs.remove(_savedAtKey(what, userId));
      }
    } catch (_) {
      // Nothing to do. The entries age out on their own.
    }
  }

  /// Every account's cached rows, for a sign-out that does not know
  /// which id it is clearing.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith('vetnow.cache.pets.') ||
              k.startsWith('vetnow.cache.appointments.'))
          .toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {
      // As above.
    }
  }
}
