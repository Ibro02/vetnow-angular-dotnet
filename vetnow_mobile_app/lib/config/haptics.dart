import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Touch feedback, kept deliberately sparse.
///
/// Haptics stop being useful the moment everything buzzes, so there are
/// only two levels here: a light tick when the person *picks* something,
/// and a firmer one when something is *done* — a booking made, a review
/// sent. Ordinary navigation and scrolling stay silent.
///
/// Every call is fire-and-forget: on a device without a vibrator, or on
/// web, the platform channel simply does nothing, and a failure to buzz
/// must never surface as an error in a booking flow.
class Haptics {
  Haptics._();

  /// Picking a filter, a city, a time slot, a star rating.
  static void select() {
    if (kIsWeb) return;
    HapticFeedback.selectionClick();
  }

  /// An action that changed something: appointment booked, review sent.
  static void success() {
    if (kIsWeb) return;
    HapticFeedback.mediumImpact();
  }

  /// Something was refused — a taken slot, a rejected form.
  static void warn() {
    if (kIsWeb) return;
    HapticFeedback.heavyImpact();
  }
}
