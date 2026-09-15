import 'package:flutter/material.dart';
import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../services/api_client.dart';
import '../services/appointment_api_service.dart';
import '../services/timeslot_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/paw_loader.dart';

/// Moves an existing appointment to another free slot.
///
/// The backend (AppointmentRescheduleEndpoint) only accepts a slot that
/// belongs to the SAME employee as the original appointment, so this
/// screen never asks the person to pick staff — it just shows that one
/// person's free slots, day by day. It also frees the old slot and books
/// the new one in a single transaction, which is why there is no
/// "cancel then rebook" dance here.
///
/// Pops `true` when the appointment actually moved, so the caller can
/// refresh its list.
class RescheduleScreen extends StatefulWidget {
  final Appointment appointment;

  const RescheduleScreen({super.key, required this.appointment});

  @override
  State<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends State<RescheduleScreen> {
  /// How many days ahead the person can browse. The backend serves one
  /// day per request, so this is just the horizon of the date strip.
  static const _daysAhead = 14;

  late DateTime _selectedDay;
  List<RemoteTimeSlot> _slots = [];
  int? _selectedSlotId;

  bool _loadingSlots = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = DateTime(today.year, today.month, today.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots());
  }

  List<DateTime> get _days {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return List.generate(_daysAhead, (i) => base.add(Duration(days: i)));
  }

  Future<void> _loadSlots() async {
    final auth = AuthScope.of(context);
    if (auth.token == null) return;

    setState(() {
      _loadingSlots = true;
      _slots = [];
      _selectedSlotId = null;
      _error = null;
    });

    try {
      final slots = await TimeSlotApiService.getForEmployee(
        employeeId: widget.appointment.employeeId,
        date: _selectedDay,
        token: auth.token!,
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.networkError;
        _loadingSlots = false;
      });
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);
    if (_selectedSlotId == null || auth.token == null) return;

    setState(() => _saving = true);
    try {
      await AppointmentApiService.reschedule(
        appointmentId: widget.appointment.id,
        newTimeSlotId: _selectedSlotId!,
        token: auth.token!,
      );
      if (!mounted) return;
      Haptics.success();
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // 409 = someone took that slot first. That is a real, explainable
      // conflict, so show the backend's own wording and reload the day.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      if (e.statusCode == 409) _loadSlots();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.networkError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.appointment;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.reschedule),
      body: Column(
        children: [
          _CurrentSlotBanner(appointment: a),
          _DayStrip(
            days: _days,
            selected: _selectedDay,
            onSelect: (d) {
              setState(() => _selectedDay = d);
              _loadSlots();
            },
          ),
          Expanded(child: _buildSlotArea(l10n)),
          _buildFooter(l10n),
        ],
      ),
    );
  }

  Widget _buildSlotArea(AppLocalizations l10n) {
    if (_loadingSlots) {
      return const Center(child: PawLoader(size: 34));
    }

    if (_error != null) {
      return _EmptyNote(icon: Icons.cloud_off_rounded, text: _error!);
    }

    if (_slots.isEmpty) {
      return _EmptyNote(icon: Icons.event_busy_outlined, text: l10n.noFreeSlotsThatDay);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.s5,
        AppSpacing.pagePadding,
        AppSpacing.s6,
      ),
      child: Wrap(
        spacing: AppSpacing.s3,
        runSpacing: AppSpacing.s3,
        children: _slots.map((slot) {
          final selected = slot.id == _selectedSlotId;
          return _SlotChip(
            label: _shortTime(slot),
            selected: selected,
            onTap: () {
              Haptics.select();
              setState(() => _selectedSlotId = slot.id);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.s4,
        AppSpacing.pagePadding,
        AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: l10n.confirmReschedule,
          icon: Icons.event_available_rounded,
          isLoading: _saving,
          onPressed: _selectedSlotId == null ? null : _confirm,
        ),
      ),
    );
  }

  /// The backend sends `appointmentTime` as "hh:mm:ss"; the strip only
  /// needs hours and minutes.
  static String _shortTime(RemoteTimeSlot slot) {
    final raw = slot.appointmentTime;
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    final d = slot.slotDateTime;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

/// Reminder of where the appointment stands now, so the person can see
/// what they are moving away from while picking the new time.
class _CurrentSlotBanner extends StatelessWidget {
  final Appointment appointment;
  const _CurrentSlotBanner({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = appointment.dateTime;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.s4,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.schedule_rounded, size: 19, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentAppointment,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.day}.${d.month}.${d.year}. · '
                  '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} · '
                  '${appointment.staffName}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal day picker. Keeps the whole flow on one screen instead of
/// opening a modal calendar for a two-week horizon.
class _DayStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const _DayStrip({required this.days, required this.selected, required this.onSelect});

  static const _dayNames = ['PON', 'UTO', 'SRI', 'ČET', 'PET', 'SUB', 'NED'];

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    return SizedBox(
      height: scaler.scale(84).clamp(84.0, 130.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.s4,
          AppSpacing.pagePadding,
          AppSpacing.s2,
        ),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s2),
        itemBuilder: (context, i) {
          final d = days[i];
          final isSelected = d.year == selected.year && d.month == selected.month && d.day == selected.day;

          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: scaler.scale(58).clamp(58.0, 92.0),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.accent],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border,
                ),
                boxShadow: isSelected ? AppShadows.glow(AppColors.primary) : AppShadows.card,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayNames[d.weekday - 1],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accent],
                )
              : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? Colors.transparent : AppColors.border),
          boxShadow: selected ? AppShadows.glow(AppColors.primary) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    // Centred when it fits, scrollable when it does not.
    //
    // Plain Center overflowed at a larger text size, because this sits in
    // whatever vertical room is left under the day strip. A plain scroll
    // view fixed that and pinned the note to the top of an otherwise
    // empty half-screen, which looked worse than the bug. The minHeight
    // is what gets both.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(icon, size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
