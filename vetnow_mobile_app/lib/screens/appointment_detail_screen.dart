import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/staff_member.dart';
import '../models/vet_station.dart';
import '../services/api_client.dart';
import '../services/appointment_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/paw_loader.dart';
import '../widgets/premium_dialog.dart';
import 'staff_profile_screen.dart';

/// Full detail view for a single appointment — past or future. Reached
/// by tapping a card in MyAppointmentsScreen.
class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = _formatDate(a.dateTime);
    final timeLabel = _formatTime(a.dateTime);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.ink,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(l10n.appointmentDetails, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            centerTitle: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.ink, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s5, AppSpacing.pagePadding, AppSpacing.s10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusHero(status: a.status, dateLabel: dateLabel, timeLabel: timeLabel),
                  const SizedBox(height: AppSpacing.s8),
                  _SectionCard(
                    title: l10n.sectionAppointment,
                    icon: Icons.event_note_outlined,
                    children: [
                      _DetailRow(icon: Icons.medical_services_outlined, label: l10n.labelService, value: a.serviceName),
                      _DetailRow(icon: Icons.notes_outlined, label: l10n.labelDetails, value: a.serviceDescription),
                      _DetailRow(icon: Icons.schedule, label: l10n.labelDuration, value: '${a.durationMinutes} min'),
                      _DetailRow(icon: Icons.pets, label: l10n.labelPet, value: a.petName),
                      _DetailRow(icon: Icons.payments_outlined, label: l10n.labelPrice, value: '${a.priceKm.toStringAsFixed(0)} KM', isLast: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  _SectionCard(
                    title: l10n.sectionSpecialist,
                    icon: Icons.badge_outlined,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StaffProfileScreen(
                              staff: StaffMember(
                                id: a.employeeId,
                                name: a.staffName,
                                role: a.staffRole,
                              ),
                              station: VetStation(
                                id: a.vetStationId,
                                name: a.clinicName,
                                stationImage: '',
                                contactNumber: a.clinicPhone,
                                inOffice: false,
                                onField: false,
                                parking: false,
                                wheelchair: false,
                                wifi: false,
                              ),
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Row(
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.staffName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  Text(a.staffRole, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right, color: AppColors.primaryDark, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  _SectionCard(
                    title: l10n.sectionClinic,
                    icon: Icons.storefront_outlined,
                    children: [
                      _DetailRow(icon: Icons.storefront_outlined, label: l10n.labelName, value: a.clinicName),
                      _DetailRow(icon: Icons.location_on_outlined, label: l10n.labelAddress, value: a.clinicAddress),
                      _DetailRow(icon: Icons.call_outlined, label: l10n.labelPhone, value: a.clinicPhone, isLast: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  if (a.status == AppointmentStatus.upcoming) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _PillActionButton(
                            label: l10n.reschedule,
                            icon: Icons.edit_calendar_outlined,
                            onTap: () {}, // TODO: reschedule flow
                            filled: false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: _PillActionButton(
                            label: l10n.cancelAppointmentAction,
                            icon: Icons.close_rounded,
                            onTap: () => _confirmCancel(context),
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ] else if (a.status == AppointmentStatus.completed) ...[
                    AppButton(
                      label: l10n.bookAgain,
                      icon: Icons.replay_outlined,
                      onPressed: () {}, // TODO: relaunch booking with same service/staff
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);
    final confirmed = await showPremiumConfirmDialog(
      context,
      icon: Icons.event_busy_rounded,
      accentColor: AppColors.danger,
      title: l10n.cancelAppointmentTitle,
      message: l10n.cancelAppointmentMessage,
      confirmLabel: l10n.cancelAppointmentAction,
      cancelLabel: l10n.keepIt,
      isDangerous: true,
    );
    if (!confirmed || !context.mounted) return;

    if (auth.token == null) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: PawLoader(size: 36, color: Colors.white)),
    );
    try {
      await AppointmentApiService.cancel(appointmentId: appointment.id, token: auth.token!);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading
      Navigator.of(context).pop(true); // close screen, signal refresh
    } on ApiException catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.networkError)),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.networkError)),
      );
    }
  }

  static String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusHero extends StatelessWidget {
  final AppointmentStatus status;
  final String dateLabel;
  final String timeLabel;

  const _StatusHero({required this.status, required this.dateLabel, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (gradient, icon, label) = switch (status) {
      AppointmentStatus.upcoming => (<Color>[AppColors.ink, AppColors.primaryDark], Icons.event_available, l10n.upcoming),
      AppointmentStatus.completed => (<Color>[AppColors.success, AppColors.primaryDark], Icons.check_circle, l10n.statusCompleted),
      AppointmentStatus.cancelled => (<Color>[AppColors.danger, AppColors.dangerHover], Icons.cancel_outlined, l10n.statusCancelled),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: AppShadows.glow(gradient.first),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(dateLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(timeLabel, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  const _SectionCard({required this.title, this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.card,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: filled ? const LinearGradient(colors: [AppColors.danger, AppColors.dangerHover]) : null,
          color: filled ? null : AppColors.primary50,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: filled ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
          boxShadow: filled
              ? [BoxShadow(color: AppColors.danger.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}
