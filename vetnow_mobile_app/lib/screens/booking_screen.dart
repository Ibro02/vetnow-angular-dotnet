import 'package:flutter/material.dart';
import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/service_catalog.dart';
import '../models/pet.dart';
import '../models/staff_member.dart';
import '../models/vet_service.dart';
import '../models/vet_station.dart';
import '../services/api_client.dart';
import '../services/appointment_api_service.dart';
import '../services/employee_api_service.dart';
import '../services/pets_api_service.dart';
import '../services/timeslot_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/paw_loader.dart';
import 'add_pet_screen.dart';
import 'login_screen.dart';

/// Service → staff → time slot → confirm, with a guest checkout gate
/// (login only requested right before confirming).
///
/// Staff/time/pet are MOCK for guests (illustrative only — Employee,
/// TimeSlot and Animal are all [Authorize] on the backend, so there's
/// no way to show real ones before login without changing the
/// backend). The moment the person is authenticated — already logged
/// in when they open this screen, or just logged in via the gate —
/// the screen switches into "real mode": it fetches the actual staff
/// for this station, the actual free slots for whichever staff member
/// is selected, and the person's actual pets, and POSTs a real
/// appointment on confirm. Because the mock selections don't map to
/// real IDs, switching into real mode resets staff/time selection and
/// asks the person to pick again from the real list — that's a small
/// UX hiccup but the honest alternative to faking a booking.
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

  // Mock-mode selection (guest, pre-login).
  int? _selectedStaffId;
  String? _selectedSlot;

  // Real-mode state (post-login).
  bool _usingReal = false;
  bool _loadingReal = false;
  List<StaffMember> _realStaff = [];
  int? _selectedRealStaffId;
  List<RemoteTimeSlot> _realSlots = [];
  bool _loadingSlots = false;
  int? _selectedRealSlotId;
  List<Pet> _myPets = [];
  int? _selectedPetId;

  bool _isConfirming = false;
  bool _confirmed = false;
  String? _bookingError;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.preselected;
    _selectedStaffId = widget.preselectedStaff?.id ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (auth.isLoggedIn && !_usingReal && !_loadingReal) {
      _switchToRealMode();
    }
  }

  Future<void> _switchToRealMode() async {
    final auth = AuthScope.of(context);
    if (auth.token == null || auth.userId == null) return;

    setState(() => _loadingReal = true);
    try {
      // Staff and pets are unrelated lookups — requested together so the
      // switch into "real mode" costs one round-trip, not two.
      final results = await Future.wait([
        EmployeeApiService.getByStation(
          stationId: widget.station.id,
          token: auth.token!,
          context: context,
        ),
        PetsApiService.getByOwner(ownerId: auth.userId!, token: auth.token!),
      ]);

      final staff = results[0] as List<StaffMember>;
      final pets = results[1] as List<Pet>;
      if (!mounted) return;
      setState(() {
        _realStaff = staff;
        _myPets = pets;
        _selectedRealStaffId = staff.isNotEmpty ? staff.first.id : null;
        _selectedPetId = pets.isNotEmpty ? pets.first.id : null;
        _usingReal = true;
        _loadingReal = false;
        // Mock time selection no longer applies once we're in real mode.
        _selectedSlot = null;
        _selectedRealSlotId = null;
      });
      if (_selectedRealStaffId != null) _loadSlotsFor(_selectedRealStaffId!);
    } catch (_) {
      if (!mounted) return;
      // Couldn't load real data (network hiccup) — stay in mock mode
      // rather than showing a broken screen; the person can still try
      // confirming again, which retries this.
      setState(() => _loadingReal = false);
    }
  }

  Future<void> _loadSlotsFor(int employeeId) async {
    final auth = AuthScope.of(context);
    if (auth.token == null) return;
    setState(() {
      _loadingSlots = true;
      _realSlots = [];
      _selectedRealSlotId = null;
    });
    try {
      final slots = await TimeSlotApiService.getForEmployee(
        employeeId: employeeId,
        date: DateTime.now(),
        token: auth.token!,
      );
      if (!mounted) return;
      setState(() {
        _realSlots = slots;
        _loadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSlots = false);
    }
  }

  bool get _canConfirm {
    if (_selectedService == null) return false;
    if (_usingReal) {
      return _selectedRealStaffId != null && _selectedRealSlotId != null && _selectedPetId != null;
    }
    return _selectedSlot != null;
  }

  Future<void> _handleConfirm() async {
    final auth = AuthScope.of(context);

    if (!auth.isLoggedIn) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen(isBookingGate: true)),
      );
      if (result != true || !mounted) return;
      // Login succeeded — didChangeDependencies will kick off
      // _switchToRealMode(). Let the person review the real
      // staff/time/pet options and press Confirm again.
      return;
    }

    if (!_usingReal) {
      // Still mid-load of real data (rare timing edge case) — bail out
      // quietly rather than submitting a fake booking.
      return;
    }

    setState(() {
      _isConfirming = true;
      _bookingError = null;
    });
    try {
      await AppointmentApiService.add(
        animalId: _selectedPetId!,
        timeSlotId: _selectedRealSlotId!,
        employeeId: _selectedRealStaffId!,
        vetStationId: widget.station.id,
        token: auth.token!,
      );
      if (!mounted) return;
      Haptics.success();
      setState(() {
        _isConfirming = false;
        _confirmed = true;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      Haptics.warn();
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isConfirming = false;
        _bookingError = l10n.bookingFailed;
      });
      // The slot we tried is probably gone now — refresh the list.
      if (_selectedRealStaffId != null) _loadSlotsFor(_selectedRealStaffId!);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isConfirming = false;
        _bookingError = l10n.bookingFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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

            if (_loadingReal) ...[
              const Center(child: PawLoader(size: 28, color: AppColors.primary)),
              const SizedBox(height: AppSpacing.s6),
            ] else if (_usingReal) ...[
              _RealStaffAndTimeSection(
                staff: _realStaff,
                selectedStaffId: _selectedRealStaffId,
                onStaffTap: (id) {
                  setState(() => _selectedRealStaffId = id);
                  _loadSlotsFor(id);
                },
                slots: _realSlots,
                loadingSlots: _loadingSlots,
                selectedSlotId: _selectedRealSlotId,
                onSlotTap: (id) => setState(() => _selectedRealSlotId = id),
              ),
              const SizedBox(height: AppSpacing.s6),
              _StepLabel(number: 4, label: l10n.choosePet),
              const SizedBox(height: AppSpacing.s3),
              if (_myPets.isEmpty)
                _NoPetsCard(onAddPet: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AddPetScreen()),
                  );
                  if (added == true) _switchToRealMode();
                })
              else
                ..._myPets.map(
                  (p) => _SelectableCard(
                    title: p.name,
                    subtitle: p.species.isNotEmpty ? p.species : l10n.petName,
                    icon: Icons.pets,
                    accentColor: AppColors.accent,
                    selected: _selectedPetId == p.id,
                    onTap: () => setState(() => _selectedPetId = p.id),
                  ),
                ),
              const SizedBox(height: AppSpacing.s6),
            ] else ...[
              _StepLabel(number: 2, label: l10n.chooseStaffOptional),
              const SizedBox(height: AppSpacing.s3),
              ..._mockStaffOptions(context).map(
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
                children: _mockSlots.map((slot) {
                  final selected = _selectedSlot == slot;
                  return InkWell(
                    onTap: () {
                      Haptics.select();
                      setState(() => _selectedSlot = slot);
                    },
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
              const SizedBox(height: AppSpacing.s6),
            ],

            if (_selectedService != null)
              _SummaryCard(
                service: _selectedService!,
                slotLabel: _usingReal
                    ? _realSlots.where((s) => s.id == _selectedRealSlotId).map((s) => s.appointmentTime).firstOrNull
                    : _selectedSlot,
              ),
            if (_bookingError != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_bookingError!, style: const TextStyle(fontSize: 12.5, color: AppColors.dangerHover))),
                  ],
                ),
              ),
            ],
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

  List<StaffMember> _mockStaffOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      StaffMember(id: 0, name: l10n.anyAvailable, role: ServiceCatalog.roleNoPreference(context)),
      if (widget.preselectedStaff != null) widget.preselectedStaff!,
      if (widget.preselectedStaff == null) ..._defaultMockStaff(context),
    ];
  }

  List<StaffMember> _defaultMockStaff(BuildContext context) => [
        StaffMember(id: 1, name: 'Dr. Amina Hodžić', role: ServiceCatalog.roleVeterinarian(context), rating: 4.9),
        StaffMember(id: 2, name: 'Dr. Emir Kovač', role: ServiceCatalog.roleVeterinarian(context), rating: 4.8),
      ];

  static const _mockSlots = [
    '09:00', '09:30', '10:00', '11:00', '13:00', '14:30', '15:00', '16:30',
  ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _RealStaffAndTimeSection extends StatelessWidget {
  final List<StaffMember> staff;
  final int? selectedStaffId;
  final ValueChanged<int> onStaffTap;
  final List<RemoteTimeSlot> slots;
  final bool loadingSlots;
  final int? selectedSlotId;
  final ValueChanged<int> onSlotTap;

  const _RealStaffAndTimeSection({
    required this.staff,
    required this.selectedStaffId,
    required this.onStaffTap,
    required this.slots,
    required this.loadingSlots,
    required this.selectedSlotId,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepLabel(number: 2, label: l10n.chooseStaffOptional),
        const SizedBox(height: AppSpacing.s3),
        if (staff.isEmpty)
          _InlineHint(icon: Icons.person_off_outlined, text: l10n.noServicesListed)
        else
          ...staff.map(
            (s) => _SelectableCard(
              title: s.name,
              subtitle: s.role,
              icon: Icons.person,
              accentColor: AppColors.accent,
              selected: selectedStaffId == s.id,
              onTap: () => onStaffTap(s.id),
            ),
          ),
        const SizedBox(height: AppSpacing.s6),
        _StepLabel(number: 3, label: l10n.pickTimeToday),
        const SizedBox(height: AppSpacing.s3),
        if (loadingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: PawLoader(size: 24, color: AppColors.primary),
          )
        else if (slots.isEmpty)
          _InlineHint(icon: Icons.event_busy_outlined, text: l10n.noSlotsToday)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: slots.map((slot) {
              final selected = selectedSlotId == slot.id;
              return InkWell(
                onTap: () => onSlotTap(slot.id),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: selected ? AppColors.ink : AppColors.border),
                  ),
                  child: Text(
                    slot.appointmentTime,
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
      ],
    );
  }
}

class _InlineHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InlineHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.bgMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _NoPetsCard extends StatelessWidget {
  final VoidCallback onAddPet;
  const _NoPetsCard({required this.onAddPet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.noPetsYet, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: AppSpacing.s3),
          AppButton(label: l10n.addPetFirst, fullWidth: false, icon: Icons.add, onPressed: onAddPet),
        ],
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
        // The step labels are full phrases ("Choose a service"), and the
        // numbered disc beside them is fixed width, so the label is what
        // has to give on a narrow screen.
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
          ),
        ),
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
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
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
  final String? slotLabel;
  const _SummaryCard({required this.service, required this.slotLabel});

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
            slotLabel != null ? l10n.todayAtDuration(slotLabel!, service.durationMinutes) : l10n.pickTimeAbove,
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
                  decoration: BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
                ),
                const SizedBox(height: AppSpacing.s6),
                Text(l10n.youAreBooked, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  l10n.bookingConfirmedMessage(station.name),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
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
