import 'package:clock/clock.dart';

import 'timeslot_api_service.dart';

/// Roughly when in the day a slot falls.
///
/// Twenty free slots arrive as one undifferentiated wall of pills. Split
/// into three named stretches it reads in a second, which is what every
/// booking app people already use does — and the split costs nothing,
/// since it is the same list rearranged rather than anything new asked
/// of the server.
enum DayPart { morning, afternoon, evening }

/// Boundaries, deliberately stated once.
///
/// Noon and five are where the words change in ordinary speech, not
/// where the clinic's shifts change — the label is for the person
/// reading it, and nobody calls 16:45 "evening".
DayPart dayPartOf(DateTime when) {
  if (when.hour < 12) return DayPart.morning;
  if (when.hour < 17) return DayPart.afternoon;
  return DayPart.evening;
}

/// Drops slots that have already gone by.
///
/// The backend answers with a whole day's free slots, and until now the
/// screen showed all of them. At five in the afternoon it would happily
/// offer four o'clock, take the booking, and file it under past visits —
/// which is how a real booking for 16:00 got made at 17:00 and then
/// appeared in history the moment it was saved.
///
/// [clock] rather than DateTime.now() so the boundary is testable
/// without waiting for an actual afternoon.
List<RemoteTimeSlot> upcomingOnly(List<RemoteTimeSlot> slots) {
  final now = clock.now();
  return slots.where((s) => s.slotDateTime.isAfter(now)).toList();
}

/// The same slots, in day order, grouped by stretch of day.
///
/// Every part is present in the returned map even when empty, on
/// purpose: the screen says "popunjeno" beside a stretch that has
/// nothing left rather than hiding it. A group that silently disappears
/// reads as a bug — a group that says it is full reads as information.
Map<DayPart, List<RemoteTimeSlot>> groupByDayPart(List<RemoteTimeSlot> slots) {
  final grouped = {for (final part in DayPart.values) part: <RemoteTimeSlot>[]};

  for (final slot in slots) {
    grouped[dayPartOf(slot.slotDateTime)]!.add(slot);
  }

  for (final list in grouped.values) {
    list.sort((a, b) => a.slotDateTime.compareTo(b.slotDateTime));
  }

  return grouped;
}

/// The soonest slot still bookable, or null when the day is done.
///
/// One line at the top of the screen answering the question most people
/// actually arrived with. It costs nothing: the day is already loaded.
RemoteTimeSlot? earliestOf(List<RemoteTimeSlot> slots) {
  final upcoming = upcomingOnly(slots);
  if (upcoming.isEmpty) return null;

  return upcoming.reduce(
    (a, b) => a.slotDateTime.isBefore(b.slotDateTime) ? a : b,
  );
}

/// Midnight on the day [when] falls in.
///
/// Dates are compared constantly here — is this the selected day, is it
/// in the past, is it today — and comparing DateTimes that carry a time
/// gets it wrong in a way that only shows up in the afternoon.
DateTime dayOf(DateTime when) => DateTime(when.year, when.month, when.day);

/// True when both fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) => dayOf(a) == dayOf(b);

/// Every bookable day of the month [selected] falls in.
///
/// Not a rolling fortnight, which is what this used to be. A rolling
/// window means the strip and the month sheet disagree about what they
/// are showing — pick the 28th from the calendar and the strip would
/// be a list of days around today with the 28th nowhere on it. Tying
/// the strip to a month makes the two halves the same control: the
/// sheet chooses the month, the strip walks it.
///
/// The current month starts at today rather than at the 1st, because
/// yesterday is not a thing anyone can book.
List<DateTime> monthDays(DateTime selected) {
  final today = dayOf(clock.now());
  final lastDay = DateTime(selected.year, selected.month + 1, 0).day;

  final first = (selected.year == today.year && selected.month == today.month)
      ? today.day
      : 1;

  return [
    for (var d = first; d <= lastDay; d++)
      DateTime(selected.year, selected.month, d),
  ];
}

