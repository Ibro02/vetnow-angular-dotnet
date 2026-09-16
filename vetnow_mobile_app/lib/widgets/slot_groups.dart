import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/slot_grouping.dart';
import '../services/timeslot_api_service.dart';

/// The free times for one day, split into morning, afternoon and evening.
///
/// A clinic with a full day free returns twenty-odd slots, and as one
/// undifferentiated wrap of pills that is a wall rather than a choice.
/// The split is the same list rearranged — nothing extra is asked of the
/// backend — and it is what every booking app people already use does.
///
/// A stretch with nothing left still appears, marked full. Hiding it
/// reads as a bug; saying it is full reads as information.
class SlotGroups extends StatelessWidget {
  final List<RemoteTimeSlot> slots;
  final int? selectedSlotId;
  final ValueChanged<int> onSlotTap;

  const SlotGroups({
    super.key,
    required this.slots,
    required this.selectedSlotId,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grouped = groupByDayPart(upcomingOnly(slots));

    // A stretch that is entirely in the past is not "full", it is simply
    // over — at six in the evening nobody needs to be told the morning
    // is booked up. Only stretches still ahead are worth a row.
    final live = DayPart.values.where((part) {
      if (grouped[part]!.isNotEmpty) return true;
      return DayPart.values.indexOf(part) >=
          DayPart.values.indexOf(dayPartOf(clock.now()));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final part in live) ...[
          _PartHeader(
            part: part,
            label: switch (part) {
              DayPart.morning => l10n.dayPartMorning,
              DayPart.afternoon => l10n.dayPartAfternoon,
              DayPart.evening => l10n.dayPartEvening,
            },
            trailing: grouped[part]!.isEmpty ? l10n.dayPartFull : null,
          ),
          if (grouped[part]!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final slot in grouped[part]!)
                  _SlotPill(
                    label: slot.appointmentTime,
                    selected: selectedSlotId == slot.id,
                    onTap: () {
                      Haptics.select();
                      onSlotTap(slot.id);
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
        ],
      ],
    );
  }
}

class _PartHeader extends StatelessWidget {
  final DayPart part;
  final String label;
  final String? trailing;

  const _PartHeader({required this.part, required this.label, this.trailing});

  IconData get _icon => switch (part) {
        DayPart.morning => Icons.wb_twilight_rounded,
        DayPart.afternoon => Icons.wb_sunny_outlined,
        DayPart.evening => Icons.nightlight_round,
      };

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.55);

    return Row(
      children: [
        Icon(_icon, size: 15, color: muted),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: muted),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 9),
          Text(
            trailing!,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38)),
          ),
        ],
      ],
    );
  }
}

class _SlotPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          // 40 tall plus the Wrap spacing clears the 48dp tap target the
          // platform guidelines ask for, without the pills looking like
          // buttons on a remote control.
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.3 : 0.16),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// One line saying when the soonest free appointment is.
///
/// Most people do not arrive wanting a particular date, they arrive
/// wanting the first opening — so that is the first thing on the screen.
/// It costs nothing: the day is already loaded, and this is its earliest
/// slot.
class EarliestSlotBanner extends StatelessWidget {
  final String dayLabel;
  final String time;
  final VoidCallback onTap;

  const EarliestSlotBanner({
    super.key,
    required this.dayLabel,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.34)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 17, color: AppColors.gold),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${l10n.earliestLabel} — '),
                    TextSpan(
                      text: '$dayLabel $time',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
