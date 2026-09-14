/// A clinic's real opening hours, from GET /api/VetStation/OpeningHours.
///
/// The app used to print one hard-coded line — the same hours for every
/// clinic, and wrong: it claimed 18:00 when the staff schedules in the
/// database end at 16:00.
class OpeningHours {
  final int vetStationId;

  /// False when no member of staff has a schedule, so there is nothing
  /// honest to show — different from "closed all week".
  final bool hasSchedule;

  final bool isOpenNow;
  final String? todayOpensAt;
  final String? todayClosesAt;

  /// Always seven entries, Monday first.
  final List<OpeningDay> days;

  const OpeningHours({
    required this.vetStationId,
    this.hasSchedule = false,
    this.isOpenNow = false,
    this.todayOpensAt,
    this.todayClosesAt,
    this.days = const [],
  });

  /// "08:00 – 16:00" for today, or null when today is a closed day.
  String? get todayRange {
    if (todayOpensAt == null || todayClosesAt == null) return null;
    return '$todayOpensAt – $todayClosesAt';
  }

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      vetStationId: json['vetStationId'] as int? ?? 0,
      hasSchedule: json['hasSchedule'] as bool? ?? false,
      isOpenNow: json['isOpenNow'] as bool? ?? false,
      todayOpensAt: json['todayOpensAt'] as String?,
      todayClosesAt: json['todayClosesAt'] as String?,
      days: (json['days'] as List<dynamic>? ?? const [])
          .map((e) => OpeningDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OpeningDay {
  /// English weekday name as the API sends it ("Monday"). Localised on
  /// the device rather than on the server, so one response serves every
  /// language the app ships in.
  final String day;

  final bool closed;
  final String? opensAt;
  final String? closesAt;

  /// How many staff cover this day. Useful context on a thin day —
  /// "open, but only one person in".
  final int staffCount;

  const OpeningDay({
    required this.day,
    this.closed = true,
    this.opensAt,
    this.closesAt,
    this.staffCount = 0,
  });

  String? get range {
    if (closed || opensAt == null || closesAt == null) return null;
    return '$opensAt – $closesAt';
  }

  factory OpeningDay.fromJson(Map<String, dynamic> json) {
    return OpeningDay(
      day: json['day'] as String? ?? '',
      closed: json['closed'] as bool? ?? true,
      opensAt: json['opensAt'] as String?,
      closesAt: json['closesAt'] as String?,
      staffCount: json['staffCount'] as int? ?? 0,
    );
  }
}
