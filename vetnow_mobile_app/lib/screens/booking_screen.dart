import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/service_catalog.dart';
import '../models/staff_member.dart';
import '../models/vet_service.dart';
import '../models/vet_station.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/gradient_app_bar.dart';
import 'login_screen.dart';

/// Service → staff (optional) → time slot → confirm.
/// Login is only requested at the very last step (guest checkout
/// pattern) — mirrors how rezervacija.app / Booksy handle first-time
/// visitors: browse and pick freely, authenticate only to confirm.
class BookingScreen extends StatefulWidget {
  final VetStation station;
  final List<VetService> services;
  final VetService? preselected;
  final StaffMember? preselectedStaff;

  const BookingScreen({
    super.key,
    required this.station,
    required this.services,
    this.preselected,
    this.preselectedStaff,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  VetService? _selectedService;
  int? _selectedStaffId;
  String? _selectedSlot;
  bool _isConfirming = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselected;
    _selectedStaffId = widget.preselectedStaff?.id ?? 0;
  }

  List<StaffMember> _staffOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      StaffMember(id: 0, name: l10n.anyAvailable, role: ServiceCatalog.roleNoPreference(context)),
      if (widget.preselectedStaff != null) widget.preselectedStaff!,
      if (widget.preselectedStaff == null) ..._defaultStaff(context),
    ];
  }

  List<StaffMember> _defaultStaff(BuildContext context) => [
        StaffMember(id: 1, name: 'Dr. Amina Hodžić', role: ServiceCatalog.roleVeterinarian(context), rating: 4.9),
        StaffMember(id: 2, name: 'Dr. Emir Kovač', role: ServiceCatalog.roleVeterinarian(context), rating: 4.8),
      ];

  static const _slots = [
    '09:00', '09:30', '10:00', '11:00', '13:00', '14:30', '15:00', '16:30',
  ];

  bool get _canConfirm => _selectedService != null && _selectedSlot != null;

  Future<void> _handleConfirm() async {
    final auth = AuthScope.of(context);

    if (!auth.isLoggedIn) {
      // Guest checkout gate: ask for login/register only now, right
      // before the booking is actually placed.
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen(isBookingGate: true)),
      );
      if (result != true || !mounted) return;
    }

    setState(() => _isConfirming = true);
    // TODO: replace with a real POST to /api/Appointment via ApiService.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isConfirming = false;
      _confirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final staffOptions = _staffOptions(context);

    if (_confirmed) return _ConfirmationView(station: widget.station);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.bookAppointment),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.s4,
            AppSpacing.pagePadding,
            AppSpacing.s10,
          ),
          children: [
            Text(widget.station.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.s6),
            _StepLabel(number: 1, label: l10n.chooseService),
            const SizedBox(height: AppSpacing.s3),
            ...widget.services.map(
              (s) => _SelectableCard(
                title: s.name,
                subtitle: '${s.description} · ${s.durationMinutes} min',
                trailing: '${s.priceKm.toStringAsFixed(0)} KM',
                icon: ServiceCatalog.icon(s.kind),
                accentColor: ServiceCatalog.color(s.kind),
                selected: _selectedService == s,
                onTap: () => setState(() => _selectedService = s),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            _StepLabel(number: 2, label: l10n.chooseStaffOptional),
            const SizedBox(height: AppSpacing.s3),
            ...staffOptions.map(
              (s) => _SelectableCard(
                title: s.name,
                subtitle: s.role,
                trailing: s.rating > 0 ? '★ ${s.rating}' : null,
                icon: s.id == 0 ? Icons.groups_outlined : Icons.person,
                accentColor: AppColors.accent,
                selected: _selectedStaffId == s.id,
                onTap: () => setState(() => _selectedStaffId = s.id),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            _StepLabel(number: 3, label: l10n.pickTimeToday),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _slots.map((slot) {
                final selected = _selectedSlot == slot;
                return InkWell(
                  onTap: () => setState(() => _selectedSlot = slot),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.ink : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: selected ? AppColors.ink : AppColors.border),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected ? Colors.white : AppColors.text,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.s8),
            if (_selectedService != null) _SummaryCard(service: _selectedService!, slot: _selectedSlot),
            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: _canConfirm ? l10n.confirmBooking : l10n.selectServiceAndTime,
              onPressed: _canConfirm ? _handleConfirm : null,
              isLoading: _isConfirming,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 22,
          width: 22,
          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          child: Center(
            child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text)),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: AppSpacing.s2),
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? accentColor : AppColors.borderLight, width: selected ? 1.5 : 1),
          boxShadow: selected ? AppShadows.card : null,
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.7)]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 13.5)),
            const SizedBox(width: 4),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_off,
              size: 20,
              color: selected ? accentColor : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final VetService service;
  final String? slot;
  const _SummaryCard({required this.service, required this.slot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bookingSummary, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(service.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            slot != null ? l10n.todayAtDuration(slot!, service.durationMinutes) : l10n.pickTimeAbove,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${service.priceKm.toStringAsFixed(0)} KM', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  final VetStation station;
  const _ConfirmationView({required this.station});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 84,
                  width: 84,
                  decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(l10n.youAreBooked, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  l10n.bookingConfirmedMessage(station.name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s8),
                AppButton(
                  label: l10n.backToExplore,
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
