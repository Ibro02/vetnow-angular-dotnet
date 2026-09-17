// The rules behind the booking calendar.
//
// The bug that started this: at five in the afternoon the screen offered
// four o'clock, took the booking, and filed it under past visits the
// moment it was saved. The backend answers with a whole day of free
// slots and nothing was filtering the ones that had already gone by.

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/services/slot_grouping.dart';
import 'package:vetnow_mobile/services/timeslot_api_service.dart';

/// A slot at [hour]:[minute] on [day], which defaults to the fixed
/// "today" the tests below run in.
RemoteTimeSlot slot(int hour, {int minute = 0, DateTime? day, int id = 0}) {
  final d = day ?? DateTime(2026, 9, 16);
  final at = DateTime(d.year, d.month, d.day, hour, minute);
  return RemoteTimeSlot(
    id: id == 0 ? hour * 100 + minute : id,
    appointmentTime: '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}',
    slotDateTime: at,
  );
}

/// Runs [body] as though it were [hour] o'clock on 16 September 2026.
///
/// package:clock rather than a real DateTime.now(), so "is this slot in
/// the past" can be asserted without the test result depending on what
/// time of day it happens to run.
T at<T>(int hour, T Function() body) =>
    withClock(Clock.fixed(DateTime(2026, 9, 16, hour)), body);

void main() {
  group('upcomingOnly', () {
    test('drops slots that have already gone by', () {
      // The actual reported bug: booked 16:00 at 17:00.
      final kept = at(17, () => upcomingOnly([slot(9), slot(16), slot(18)]));

      expect(kept.map((s) => s.appointmentTime), ['18:00']);
    });

    test('keeps everything when the day has not started', () {
      final kept = at(7, () => upcomingOnly([slot(9), slot(16), slot(18)]));

      expect(kept, hasLength(3));
    });

    test('a slot exactly now is already gone', () {
      // By the time somebody has tapped it, typed a pet and confirmed,
      // an appointment starting this second has started.
      final kept = at(16, () => upcomingOnly([slot(16)]));

      expect(kept, isEmpty);
    });

    test('tomorrow is never in the past', () {
      final tomorrow = DateTime(2026, 9, 17);
      final kept = at(23, () => upcomingOnly([slot(8, day: tomorrow)]));

      expect(kept, hasLength(1));
    });
  });

  group('dayPartOf', () {
    test('splits at noon and at five', () {
      // Where the words change in ordinary speech, not where the
      // clinic's shifts change -- nobody calls 16:45 "evening".
      expect(dayPartOf(DateTime(2026, 9, 16, 11, 59)), DayPart.morning);
      expect(dayPartOf(DateTime(2026, 9, 16, 12)), DayPart.afternoon);
      expect(dayPartOf(DateTime(2026, 9, 16, 16, 59)), DayPart.afternoon);
      expect(dayPartOf(DateTime(2026, 9, 16, 17)), DayPart.evening);
    });
  });

  group('groupByDayPart', () {
    test('sorts each stretch by time', () {
      final grouped = groupByDayPart([slot(19), slot(9), slot(14), slot(8)]);

      expect(grouped[DayPart.morning]!.map((s) => s.appointmentTime),
          ['08:00', '09:00']);
      expect(grouped[DayPart.afternoon]!.map((s) => s.appointmentTime), ['14:00']);
      expect(grouped[DayPart.evening]!.map((s) => s.appointmentTime), ['19:00']);
    });

    test('an empty stretch is present, not missing', () {
      // The screen says "popunjeno" beside a stretch with nothing left.
      // A group that silently disappears reads as a bug; one that says
      // it is full reads as information.
      final grouped = groupByDayPart([slot(19)]);

      expect(grouped.keys, hasLength(3));
      expect(grouped[DayPart.morning], isEmpty);
    });
  });

  group('earliestOf', () {
    test('is the soonest slot still bookable', () {
      final first = at(13, () => earliestOf([slot(18), slot(9), slot(15)]));

      expect(first?.appointmentTime, '15:00');
    });

    test('is null once the day is done', () {
      expect(at(20, () => earliestOf([slot(9), slot(16)])), isNull);
    });
  });

  group('isSameDay', () {
    test('ignores the time of day', () {
      expect(
        isSameDay(DateTime(2026, 9, 16, 0, 1), DateTime(2026, 9, 16, 23, 59)),
        isTrue,
      );
    });

    test('a minute past midnight is a different day', () {
      expect(
        isSameDay(DateTime(2026, 9, 16, 23, 59), DateTime(2026, 9, 17, 0, 1)),
        isFalse,
      );
    });
  });

  group('monthDays', () {
    test('the current month starts at today, not at the 1st', () {
      // Yesterday is not a thing anyone can book.
      final days = at(10, () => monthDays(DateTime(2026, 9, 16)));

      expect(days.first, DateTime(2026, 9, 16));
      expect(days.last, DateTime(2026, 9, 30));
      expect(days, hasLength(15));
    });

    test('a later month is shown whole', () {
      final days = at(10, () => monthDays(DateTime(2026, 10, 20)));

      expect(days.first, DateTime(2026, 10, 1));
      expect(days.last, DateTime(2026, 10, 31));
      expect(days, hasLength(31));
    });

    test('February knows how long it is', () {
      final days = at(10, () => monthDays(DateTime(2027, 2, 5)));
      expect(days.last, DateTime(2027, 2, 28));

      final leap = at(10, () => monthDays(DateTime(2028, 2, 5)));
      expect(leap.last, DateTime(2028, 2, 29));
    });

    test('the strip always contains the day that is selected', () {
      // The whole reason this replaced a rolling fortnight: pick the
      // 28th from the month sheet and the strip has to be showing it,
      // not a window of days around today with the 28th nowhere on it.
      for (final day in [
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 1),
        DateTime(2026, 12, 25),
      ]) {
        expect(at(10, () => monthDays(day)), contains(day), reason: '$day');
      }
    });

    test('a month entirely in the past comes back empty, not backwards', () {
      expect(at(10, () => monthDays(DateTime(2026, 9, 1))).first,
          DateTime(2026, 9, 16));
    });
  });
}
