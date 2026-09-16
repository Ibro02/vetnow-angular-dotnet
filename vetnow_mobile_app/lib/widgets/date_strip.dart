import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/slot_grouping.dart';

/// Picking which day to book.
///
/// The screen used to ask the backend for today and nothing else — the
/// endpoint always took a date, it was simply never given one — so
/// "tomorrow" was not a thing the app could express. This is that
/// missing control.
///
/// Two weeks live in the strip and the rest behind a month sheet,
/// because the shape of the question changes with distance: "tomorrow
/// or Thursday" is a glance and a tap, "the 28th" is a calendar. One
/// control doing both jobs does neither well.
class DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  /// Weekdays the clinic is shut, 1 = Monday through 7 = Sunday.
  ///
  /// Comes from the opening-hours endpoint the clinic page already
  /// calls, so a closed day costs nothing extra to know about.
  final Set<int> closedWeekdays;

  /// Days already looked at that turned out to have free slots.
  ///
  /// Only days that have actually been opened — asking about all
  /// fourteen up front would be fourteen requests per employee every
  /// time this screen appears. What is known gets shown; nothing is
  /// fetched to fill the strip in.
  final Set<DateTime> daysWithSlots;

  const DateStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    this.closedWeekdays = const {},
    this.daysWithSlots = const {},
  });

  bool _isClosed(DateTime day) => closedWeekdays.contains(day.weekday);

  static const double _maxCapsuleScale = 1.3;

  static double _capsuleScale(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1).clamp(1.0, _maxCapsuleScale);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final days = stripDays();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Flexible, and the pill is not: on a 320pt phone with
            // a long month name the heading and the calendar button
            // together ran 90 pixels past the edge. The heading is the
            // half that can give way — the button cannot shrink and
            // still be a target.
            Flexible(
              child: Text(
                l10n.pickDay,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _GlassPill(
              icon: Icons.calendar_month_rounded,
              // The pill shows the month; a screen reader needs to be
              // told it is the way into a calendar, not a label.
              semanticLabel: l10n.calendarOpen,
              label: toBeginningOfSentenceCase(
                    DateFormat.MMMM(locale).format(selected),
                  ) ??
                  '',
              onTap: () async {
                Haptics.select();
                final picked = await showMonthSheet(
                  context,
                  selected: selected,
                  closedWeekdays: closedWeekdays,
                );
                if (picked != null) onSelect(picked);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        // The strip's height has to follow the text, and only so far.
        //
        // Fixed at 74 it overflowed by 63 pixels once the system text
        // size reached 1.5. Scaling it without limit is no better: the
        // capsules would grow past half the screen and push the times
        // themselves out of sight. Clamped at 1.3 the numbers are still
        // comfortably larger than default, and the row still fits.
        SizedBox(
          height: 74 * _capsuleScale(context),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: _maxCapsuleScale,
            child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Clip.none so the selected capsule's rim is not shaved off
            // at either end of the strip.
            clipBehavior: Clip.none,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, i) {
              final day = days[i];
              return _DayCapsule(
                day: day,
                locale: locale,
                selected: isSameDay(day, selected),
                closed: _isClosed(day),
                hasSlots: daysWithSlots.contains(dayOf(day)),
                closedLabel: l10n.closedShort,
                onTap: () {
                  Haptics.select();
                  onSelect(day);
                },
              );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCapsule extends StatelessWidget {
  final DateTime day;
  final String locale;
  final bool selected;
  final bool closed;
  final bool hasSlots;
  final String closedLabel;
  final VoidCallback onTap;

  const _DayCapsule({
    required this.day,
    required this.locale,
    required this.selected,
    required this.closed,
    required this.hasSlots,
    required this.closedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat.E(locale).format(day).toLowerCase();

    // The selected capsule is mint, and its text has to be dark to be
    // read on it; everything else sits on the ink panel and is light.
    final Color labelColor = selected
        ? AppColors.ink
        : closed
            ? Colors.white.withValues(alpha: 0.42)
            : Colors.white.withValues(alpha: 0.72);
    final Color numberColor =
        selected ? AppColors.ink : Colors.white.withValues(alpha: closed ? 0.5 : 1);

    return Semantics(
      button: !closed,
      selected: selected,
      label: DateFormat.yMMMMEEEEd(locale).format(day),
      excludeSemantics: true,
      child: Opacity(
        opacity: closed ? 0.45 : 1,
        child: InkWell(
          onTap: closed ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: closed ? 0.04 : 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.3 : 0.16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weekday,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 10.5, color: labelColor),
                ),
                const SizedBox(height: 3),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: numberColor,
                  ),
                ),
                const SizedBox(height: 4),
                // A fixed-height slot for the marker, so capsules with a
                // dot and capsules without still line up.
                SizedBox(
                  height: 5,
                  child: closed
                      ? Text(
                          closedLabel,
                          style: TextStyle(fontSize: 8.5, height: 0.6, color: labelColor),
                        )
                      : selected
                          // A dash rather than a dot on the selected day:
                          // a dot there competes with the capsule itself
                          // for the same "this one" meaning.
                          ? Container(
                              width: 14,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : hasSlots
                              ? Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  const _GlassPill({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// The month grid, for anything further out than the strip reaches.
///
/// Returns the chosen day, or null if it was dismissed.
Future<DateTime?> showMonthSheet(
  BuildContext context, {
  required DateTime selected,
  Set<int> closedWeekdays = const {},
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MonthSheet(selected: selected, closedWeekdays: closedWeekdays),
  );
}

class _MonthSheet extends StatefulWidget {
  final DateTime selected;
  final Set<int> closedWeekdays;

  const _MonthSheet({required this.selected, required this.closedWeekdays});

  @override
  State<_MonthSheet> createState() => _MonthSheetState();
}

class _MonthSheetState extends State<_MonthSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selected.year, widget.selected.month);
  }

  /// Never before the month today falls in — there is nothing to book
  /// back there, and a calendar that lets you walk into last year is
  /// offering a journey with no destination.
  bool get _canGoBack {
    final today = dayOf(clock.now());
    return _month.isAfter(DateTime(today.year, today.month));
  }

  void _step(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = dayOf(clock.now());

    // Leading blanks so the first of the month lands under the right
    // weekday. DateTime.weekday is 1 = Monday, and the grid starts on
    // Monday, so the offset is simply weekday - 1.
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - 1;

    return SafeArea(
      top: false,
      child: Semantics(
        container: true,
        label: l10n.monthSheetTitle,
        child: Container(
        margin: const EdgeInsets.all(AppSpacing.s3),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _canGoBack ? () => _step(-1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: AppColors.textSecondary,
                  tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                ),
                Text(
                  toBeginningOfSentenceCase(
                        DateFormat.yMMMM(locale).format(_month),
                      ) ??
                      '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                IconButton(
                  onPressed: () => _step(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: AppColors.primary,
                  tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        // 2024-01-01 was a Monday, so this walks Mon..Sun
                        // in whatever language is on.
                        DateFormat.E(locale).format(DateTime(2024, 1, 1 + i)).toLowerCase(),
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: leading + daysInMonth,
              itemBuilder: (context, i) {
                if (i < leading) return const SizedBox.shrink();

                final day = DateTime(_month.year, _month.month, i - leading + 1);
                final past = day.isBefore(today);
                final closed = widget.closedWeekdays.contains(day.weekday);
                final disabled = past || closed;
                final isSelected = isSameDay(day, widget.selected);

                return InkWell(
                  onTap: disabled ? null : () => Navigator.of(context).pop(day),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : null,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.ink
                            : disabled
                                ? AppColors.textMuted.withValues(alpha: 0.45)
                                : AppColors.text,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
