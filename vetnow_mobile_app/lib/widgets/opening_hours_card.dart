import 'package:flutter/material.dart';
import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/opening_hours.dart';
import 'skeleton.dart';

/// A clinic's opening hours.
///
/// Collapsed it answers the only question most people have — "are they
/// open right now, and until when?" — and expands to the full week for
/// the ones planning ahead. The whole thing is real: the hours come from
/// the staff schedules in the database, and "open now" is decided by the
/// server, not by the phone's clock.
///
/// It replaced a fixed line of text that read "Pon–Sub, 08:00–18:00" on
/// every clinic, and was an hour and a half wrong.
class OpeningHoursCard extends StatefulWidget {
  final OpeningHours? hours;
  final bool isLoading;

  const OpeningHoursCard({super.key, required this.hours, required this.isLoading});

  @override
  State<OpeningHoursCard> createState() => _OpeningHoursCardState();
}

class _OpeningHoursCardState extends State<OpeningHoursCard> {
  bool _expanded = false;

  /// The API sends English weekday names so one response serves every
  /// language; the mapping lives here.
  String _dayLabel(AppLocalizations l10n, String day) => switch (day.toLowerCase()) {
        'monday' => l10n.dayMonday,
        'tuesday' => l10n.dayTuesday,
        'wednesday' => l10n.dayWednesday,
        'thursday' => l10n.dayThursday,
        'friday' => l10n.dayFriday,
        'saturday' => l10n.daySaturday,
        'sunday' => l10n.daySunday,
        _ => day,
      };

  bool _isToday(String day) {
    const names = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    ];
    // DateTime.weekday is 1..7 starting at Monday, matching the list above.
    return day.toLowerCase() == names[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) {
      return const Shimmer(child: SkeletonBox(height: 46, radius: AppRadius.lg));
    }

    final hours = widget.hours;
    if (hours == null || !hours.hasSchedule) {
      return _Shell(
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 15, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.noScheduleYet,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final open = hours.isOpenNow;
    final statusColor = open ? AppColors.success : AppColors.textSecondary;

    return _Shell(
      onTap: () {
        Haptics.select();
        setState(() => _expanded = !_expanded);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // A filled dot rather than a coloured word, so the status is
              // legible at a glance and doesn't depend on reading.
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                open ? l10n.openNowLabel : l10n.closedNowLabel,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: statusColor),
              ),
              // Expanded rather than Flexible + Spacer: the two of them were
              // competing for the same free space, and the hours — the part
              // people are actually reading — lost, ending up as "08:00 – 1…".
              Expanded(
                child: hours.todayRange == null
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '· ${hours.todayRange}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
              ),
            ],
          ),
          // AnimatedSize rather than AnimatedCrossFade: the latter builds both
          // states at all times, so a collapsed card still laid out seven day
          // rows — wasted on every clinic page, and enough to make the rows
          // findable while they were supposed to be hidden.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s3),
                    child: Column(
                      children: [
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: AppSpacing.s2),
                        ...hours.days.map((d) => _DayRow(
                              label: _dayLabel(l10n, d.day),
                              day: d,
                              isToday: _isToday(d.day),
                              closedLabel: l10n.closedDay,
                            )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Shell({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );

    if (onTap == null) return box;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: box,
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final OpeningDay day;
  final bool isToday;
  final String closedLabel;

  const _DayRow({
    required this.label,
    required this.day,
    required this.isToday,
    required this.closedLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Today is bolder, so the row someone is looking for is the row that
    // stands out.
    final weight = isToday ? FontWeight.w800 : FontWeight.w500;
    final color = day.closed ? AppColors.textMuted : AppColors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: weight, color: color),
            ),
          ),
          Text(
            day.range ?? closedLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: weight,
              color: day.closed ? AppColors.textMuted : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
