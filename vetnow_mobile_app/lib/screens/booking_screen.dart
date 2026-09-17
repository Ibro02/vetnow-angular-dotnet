import 'dart:async';

import 'package:clock/clock.dart';
import 'package:intl/intl.dart';

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
import '../services/service_staffing.dart';
import '../services/slot_grouping.dart';
import '../services/timeslot_api_service.dart';
import '../services/vet_station_api_service.dart';
import '../widgets/date_strip.dart';
import '../widgets/slot_groups.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/pet_strip.dart';
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

  /// Which day the slots below belong to.
  ///
  /// Defaults to today, which is what the screen used to be hard-wired
  /// to — the endpoint always took a date, it was simply never given
  /// one, so "tomorrow" was not something the app could express.
  DateTime _selectedDay = dayOf(clock.now());

  /// Weekdays this clinic is shut. From the opening-hours endpoint the
  /// clinic page already calls, so a closed day is free to know about.
  Set<int> _closedWeekdays = {};

  /// Days opened so far that turned out to have something free.
  ///
  /// Only what has actually been looked at. Filling the whole strip in
  /// would be fourteen requests per employee every time this screen
  /// appears, which is not a price worth paying for fourteen dots.
  final Set<DateTime> _daysWithSlots = {};

  /// The soonest opening this clinic has, and the day it falls on.
  ///
  /// Found by asking day after day until one answers, capped, and
  /// stopping at the first hit — so on a clinic with anything free
  /// today it is one request, and on a clinic booked solid for a week
  /// it is a handful. That is worth paying for: it is the question
  /// most people came with, and it is the one thing on this screen
  /// they cannot answer by looking.
  DateTime? _firstFreeDay;
  RemoteTimeSlot? _firstFreeSlot;
  bool _searchingFirstFree = false;
  int? _selectedRealSlotId;
  List<Pet> _myPets = [];
  int? _selectedPetId;

  /// Below this the row fits without moving, and a search box and a
  /// filter are two controls asking to be used on a problem nobody
  /// has.
  static const int _petSearchThreshold = 6;

  /// Favourites first, then alphabetical.
  ///
  /// The list arrived in whatever order the database felt like, which
  /// for anything past a handful is no order at all. Favourites lead
  /// because a pet marked favourite is the one being booked for.
  List<Pet> get _visiblePets {
    final matching = [..._myPets];

    matching.sort((a, b) {
      if (a.isFavourite != b.isFavourite) return a.isFavourite ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return matching;
  }

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
  void dispose() {
    super.dispose();
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
        EmployeeApiService.getByStationFiltered(
          stationId: widget.station.id,
          token: auth.token!,
          context: context,
          // Narrowed to the trade that performs the chosen service.
          // Before this the whole team was offered for everything, so
          // a groomer could be booked for a dental procedure.
          filter: ServiceStaffing.filterFor(_selectedService?.kind),
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
      if (_selectedRealStaffId != null) {
        unawaited(_loadSlotsFor(_selectedRealStaffId!));
        unawaited(_findFirstOpening(_selectedRealStaffId!));
      }
      unawaited(_loadOpeningHours());
    } catch (_) {
      if (!mounted) return;
      // Couldn't load real data (network hiccup) — stay in mock mode
      // rather than showing a broken screen; the person can still try
      // confirming again, which retries this.
      setState(() => _loadingReal = false);
    }
  }

  Future<void> _loadSlotsFor(int employeeId, {DateTime? day}) async {
    final auth = AuthScope.of(context);
    if (auth.token == null) return;

    final target = day ?? _selectedDay;
    setState(() {
      _loadingSlots = true;
      _realSlots = [];
      _selectedRealSlotId = null;
    });
    try {
      final slots = await TimeSlotApiService.getForEmployee(
        employeeId: employeeId,
        date: target,
        token: auth.token!,
      );
      if (!mounted) return;

      // Filtered here, not just at paint time. The backend answers
      // with the whole day, so at five in the afternoon it still
      // offers four o'clock — which is how a booking for 16:00 got
      // made at 17:00 and landed straight in past visits.
      final bookable = upcomingOnly(slots);

      setState(() {
        _realSlots = bookable;
        _loadingSlots = false;
        if (bookable.isNotEmpty) {
          _daysWithSlots.add(dayOf(target));
        } else {
          _daysWithSlots.remove(dayOf(target));
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSlots = false);
    }
  }

  /// "danas", "sutra", or a written-out date.
  ///
  /// Every sentence on this screen used to say "danas" because the
  /// screen could only mean today. Now that it can mean any day, the
  /// word has to come from the date — and for the two days people book
  /// most, the word is friendlier than the number.
  static String _dayLabel(BuildContext context, DateTime day) {
    final l10n = AppLocalizations.of(context)!;
    final today = dayOf(clock.now());

    if (isSameDay(day, today)) return l10n.todayWord;
    if (isSameDay(day, DateTime(today.year, today.month, today.day + 1))) {
      return l10n.tomorrowWord;
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMMEEEEd(locale).format(day);
  }

  /// Picks a service, and re-asks who can actually perform it.
  ///
  /// The staff list is a function of the service, not of the station:
  /// a nail trim is the groomer's, a tooth is the vet's. Changing the
  /// service therefore has to change who is on offer, and it drops the
  /// chosen person and time — keeping a groomer selected while
  /// switching to dentistry is exactly the pairing this prevents.
  void _selectService(VetService service) {
    if (service.kind == _selectedService?.kind) {
      setState(() => _selectedService = service);
      return;
    }

    setState(() {
      _selectedService = service;
      _selectedRealStaffId = null;
      _selectedRealSlotId = null;
      _selectedSlot = null;
      _realSlots = [];
      _daysWithSlots.clear();
      _firstFreeDay = null;
      _firstFreeSlot = null;
    });

    if (_usingReal) unawaited(_reloadStaffForService());
  }

  Future<void> _reloadStaffForService() async {
    final auth = AuthScope.of(context);
    if (auth.token == null) return;

    setState(() => _loadingReal = true);
    try {
      final staff = await EmployeeApiService.getByStationFiltered(
        stationId: widget.station.id,
        token: auth.token!,
        context: context,
        filter: ServiceStaffing.filterFor(_selectedService?.kind),
      );
      if (!mounted) return;
      setState(() {
        _realStaff = staff;
        _selectedRealStaffId = staff.isNotEmpty ? staff.first.id : null;
        _loadingReal = false;
      });
      if (_selectedRealStaffId != null) {
        unawaited(_loadSlotsFor(_selectedRealStaffId!));
        // A different trade keeps a different diary, so the soonest
        // opening has to be found again rather than carried over.
        unawaited(_findFirstOpening(_selectedRealStaffId!));
      }
    } catch (_) {
      if (!mounted) return;
      // Keep whoever was listed rather than emptying the screen on a
      // network hiccup; the person can change the service again.
      setState(() => _loadingReal = false);
    }
  }

  /// How far ahead to look for the first opening before giving up.
  ///
  /// Two weeks. Past that the answer stops being useful — nobody
  /// books a check-up around a clinic's availability a month out —
  /// and the cost of asking stops being worth it.
  static const int _firstFreeHorizon = 14;

  /// Walks forward from today until a day has something free.
  ///
  /// Closed days are skipped without asking, since the opening hours
  /// already say so. Everything it learns on the way is kept, so the
  /// dots on the strip fill in as a side effect rather than costing a
  /// second pass.
  Future<void> _findFirstOpening(int employeeId) async {
    final auth = AuthScope.of(context);
    if (auth.token == null || _searchingFirstFree) return;

    setState(() {
      _searchingFirstFree = true;
      _firstFreeDay = null;
      _firstFreeSlot = null;
    });

    final today = dayOf(clock.now());
    try {
      for (var i = 0; i < _firstFreeHorizon; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        if (_closedWeekdays.contains(day.weekday)) continue;

        final slots = upcomingOnly(await TimeSlotApiService.getForEmployee(
          employeeId: employeeId,
          date: day,
          token: auth.token!,
        ));
        if (!mounted) return;

        if (slots.isEmpty) {
          _daysWithSlots.remove(day);
          continue;
        }

        setState(() {
          _daysWithSlots.add(day);
          _firstFreeDay = day;
          _firstFreeSlot = earliestOf(slots);
          _searchingFirstFree = false;
        });
        return;
      }
    } catch (_) {
      // Nothing to say. The screen works without this; it is an
      // shortcut, not a dependency.
    }

    if (mounted) setState(() => _searchingFirstFree = false);
  }

  /// Takes the offer in the banner: moves to that day and selects the
  /// slot, so one tap gets somebody from "when is the soonest" to a
  /// chosen time.
  Future<void> _takeFirstOpening() async {
    final day = _firstFreeDay;
    final slot = _firstFreeSlot;
    if (day == null || slot == null || _selectedRealStaffId == null) return;

    setState(() => _selectedDay = day);
    await _loadSlotsFor(_selectedRealStaffId!, day: day);
    if (!mounted) return;

    // Only if it is still there. Between the search and the tap
    // somebody else may have taken it, and silently selecting nothing
    // is better than selecting a slot that no longer exists.
    if (_realSlots.any((s) => s.id == slot.id)) {
      setState(() => _selectedRealSlotId = slot.id);
    }
  }

  /// Moves the whole picker to another day.
  void _selectDay(DateTime day) {
    if (isSameDay(day, _selectedDay)) return;
    setState(() {
      _selectedDay = dayOf(day);
      _selectedRealSlotId = null;
    });
    if (_selectedRealStaffId != null) {
      unawaited(_loadSlotsFor(_selectedRealStaffId!));
    }
  }

  /// Which weekdays the clinic is shut, so those days can be greyed
  /// out rather than offered and then found empty.
  ///
  /// One request for the whole clinic, and the clinic page already
  /// makes it. A failure here is not worth surfacing: the strip simply
  /// shows every day as open, which is what it did before.
  Future<void> _loadOpeningHours() async {
    try {
      final hours = await VetStationApiService.openingHours(widget.station.id);
      if (!mounted) return;
      setState(() => _closedWeekdays = hours.closedWeekdays);
    } catch (_) {
      // Left open. See above.
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
      if (_selectedRealStaffId != null) unawaited(_loadSlotsFor(_selectedRealStaffId!));
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
            Text(widget.station.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.s6),
            _StepLabel(
              number: 1,
              label: l10n.chooseService,
              done: _selectedService != null,
            ),
            const SizedBox(height: AppSpacing.s3),
            ...widget.services.map(
              (s) => _SelectableCard(
                title: s.name,
                subtitle: '${s.description} · ${s.durationMinutes} min',
                trailing: '${s.priceKm.toStringAsFixed(0)} KM',
                icon: ServiceCatalog.icon(s.kind),
                accentColor: ServiceCatalog.color(s.kind),
                selected: _selectedService == s,
                onTap: () => _selectService(s),
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
                selectedDay: _selectedDay,
                onSelectDay: _selectDay,
                closedWeekdays: _closedWeekdays,
                daysWithSlots: _daysWithSlots,
                dayLabel: _dayLabel(context, _selectedDay),
                firstFreeDay: _firstFreeDay,
                firstFreeLabel: _firstFreeDay == null
                    ? ''
                    : _dayLabel(context, _firstFreeDay!),
                firstFreeTime: _firstFreeSlot?.appointmentTime ?? '',
                onTakeFirstFree: () => unawaited(_takeFirstOpening()),
              ),
              const SizedBox(height: AppSpacing.s6),
              _StepLabel(
                number: 4,
                label: l10n.choosePet,
                done: _selectedPetId != null,
              ),
              const SizedBox(height: AppSpacing.s3),
              if (_myPets.isEmpty)
                _NoPetsCard(onAddPet: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AddPetScreen()),
                  );
                  if (added == true) unawaited(_switchToRealMode());
                })
              else
                PetStrip(
                  pets: _visiblePets,
                  selectedPetId: _selectedPetId,
                  onSelect: (id) => setState(() => _selectedPetId = id),
                  emptyMessage: l10n.noPetsMatchFilter,
                  // The tile at the end of the row, and the sheet
                  // behind it, only once the row is long enough to
                  // need flicking.
                  searchable: _myPets.length >= _petSearchThreshold
                      ? _myPets
                      : null,
                ),
              const SizedBox(height: AppSpacing.s6),
            ] else ...[
              _StepLabel(
                number: 2,
                label: l10n.chooseStaffOptional,
                done: _selectedStaffId != null,
              ),
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
              _StepLabel(
                number: 3,
                label: l10n.pickTimeToday,
                done: _selectedSlot != null,
              ),
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
                dayLabel: _dayLabel(context, _selectedDay),
                slotLabel: _usingReal
                    ? _realSlots
                        .where((s) => s.id == _selectedRealSlotId)
                        .map((s) => s.appointmentTime)
                        .firstOrNull
                    : _selectedSlot,
              ),
            if (_bookingError != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_bookingError!,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.dangerHover))),
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
        StaffMember(
            id: 1,
            name: 'Dr. Amina Hodžić',
            role: ServiceCatalog.roleVeterinarian(context),
            rating: 4.9),
        StaffMember(
            id: 2,
            name: 'Dr. Emir Kovač',
            role: ServiceCatalog.roleVeterinarian(context),
            rating: 4.8),
      ];

  static const _mockSlots = [
    '09:00',
    '09:30',
    '10:00',
    '11:00',
    '13:00',
    '14:30',
    '15:00',
    '16:30',
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
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final Set<int> closedWeekdays;
  final Set<DateTime> daysWithSlots;
  final String dayLabel;
  final DateTime? firstFreeDay;
  final String firstFreeLabel;
  final String firstFreeTime;
  final VoidCallback onTakeFirstFree;

  const _RealStaffAndTimeSection({
    required this.staff,
    required this.selectedStaffId,
    required this.onStaffTap,
    required this.slots,
    required this.loadingSlots,
    required this.selectedSlotId,
    required this.onSlotTap,
    required this.selectedDay,
    required this.onSelectDay,
    required this.closedWeekdays,
    required this.daysWithSlots,
    required this.dayLabel,
    required this.firstFreeDay,
    required this.firstFreeLabel,
    required this.firstFreeTime,
    required this.onTakeFirstFree,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepLabel(
          number: 2,
          label: l10n.chooseStaffOptional,
          done: selectedStaffId != null,
        ),
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
        _StepLabel(
          number: 3,
          label: l10n.pickTimeOnDay(dayLabel),
          done: selectedSlotId != null,
        ),
        const SizedBox(height: AppSpacing.s3),
        _DayAndSlotPanel(
          selectedDay: selectedDay,
          onSelectDay: onSelectDay,
          closedWeekdays: closedWeekdays,
          daysWithSlots: daysWithSlots,
          slots: slots,
          loadingSlots: loadingSlots,
          selectedSlotId: selectedSlotId,
          onSlotTap: onSlotTap,
          dayLabel: dayLabel,
          firstFreeDay: firstFreeDay,
          firstFreeLabel: firstFreeLabel,
          firstFreeTime: firstFreeTime,
          onTakeFirstFree: onTakeFirstFree,
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
          AppButton(
              label: l10n.addPetFirst, fullWidth: false, icon: Icons.add, onPressed: onAddPet),
        ],
      ),
    );
  }
}

/// One of the four questions this screen asks, with its number.
///
/// [done] is what turns four stacked lists into something that reads
/// as a sequence. Every disc was mint before, answered or not, so the
/// screen looked the same whether you had filled in nothing or
/// everything and there was no way to see how far along you were
/// without reading all of it.
class _StepLabel extends StatelessWidget {
  final int number;
  final String label;
  final bool done;

  const _StepLabel({
    required this.number,
    required this.label,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: done ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? AppColors.accent : AppColors.border,
                width: 1.5,
              ),
              boxShadow: done ? AppShadows.glow(AppColors.accent) : null,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.1,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Under the row, not beside the label.
          //
          // It used to share the row with the text, and an Expanded rule
          // next to a Flexible label splits the space evenly — so
          // "Odaberi osoblje (opcionalno)" was cut to "Odaberi osoblje
          // (opciona..." to make room for a decorative line. The line is
          // decoration; the label is the point.
          Container(height: 1, color: AppColors.borderLight),
        ],
      ),
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
          border: Border.all(
              color: selected ? accentColor : AppColors.borderLight, width: selected ? 1.5 : 1),
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
              Text(trailing!,
                  style:
                      TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 13.5)),
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

  /// Which day the slot is on. This card used to say "Danas u 16:00"
  /// unconditionally, because the screen could only book today — with
  /// a calendar on it, that sentence would be a lie half the time.
  final String dayLabel;

  const _SummaryCard({
    required this.service,
    required this.slotLabel,
    required this.dayLabel,
  });

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
          Text(l10n.bookingSummary,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(service.name,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            slotLabel != null
                ? l10n.slotAtDuration(dayLabel, slotLabel!, service.durationMinutes)
                : l10n.pickTimeAbove,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('${service.priceKm.toStringAsFixed(0)} KM',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
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

/// The dark panel that holds the day strip and the times.
///
/// Ink rather than the page's own surface, and on purpose: this is the
/// one decision the whole screen exists to collect, and the panel says
/// so by being the only dark thing on a light page. It also lets the
/// strip and the slot pills share the glass language the hero and the
/// nav pill already use, instead of inventing a third look.
class _DayAndSlotPanel extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final Set<int> closedWeekdays;
  final Set<DateTime> daysWithSlots;
  final List<RemoteTimeSlot> slots;
  final bool loadingSlots;
  final int? selectedSlotId;
  final ValueChanged<int> onSlotTap;
  final String dayLabel;
  final DateTime? firstFreeDay;
  final String firstFreeLabel;
  final String firstFreeTime;
  final VoidCallback onTakeFirstFree;

  const _DayAndSlotPanel({
    required this.selectedDay,
    required this.onSelectDay,
    required this.closedWeekdays,
    required this.daysWithSlots,
    required this.slots,
    required this.loadingSlots,
    required this.selectedSlotId,
    required this.onSlotTap,
    required this.dayLabel,
    required this.firstFreeDay,
    required this.firstFreeLabel,
    required this.firstFreeTime,
    required this.onTakeFirstFree,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: AppGradients.ink,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only when it points at a day you are not looking at.
          //
          // It used to announce the first slot of whichever day was on
          // screen, which is the pill immediately below it — a line
          // telling you something you can already see. What is worth
          // saying is where the soonest opening *is*, when it is
          // somewhere else, and one tap takes you there.
          if (firstFreeDay != null && !isSameDay(firstFreeDay!, selectedDay)) ...[
            EarliestSlotBanner(
              dayLabel: firstFreeLabel,
              time: firstFreeTime,
              isToday: isSameDay(firstFreeDay!, clock.now()),
              onTap: onTakeFirstFree,
            ),
            const SizedBox(height: AppSpacing.s5),
          ],
          DateStrip(
            selected: selectedDay,
            onSelect: onSelectDay,
            closedWeekdays: closedWeekdays,
            daysWithSlots: daysWithSlots,
          ),
          const SizedBox(height: AppSpacing.s5),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
          const SizedBox(height: AppSpacing.s5),
          if (loadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: PawLoader(size: 24, color: Colors.white),
              ),
            )
          else if (slots.isEmpty)
            Row(
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 17, color: Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    l10n.noSlotsOnDay(dayLabel),
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.72)),
                  ),
                ),
              ],
            )
          else
            SlotGroups(
              slots: slots,
              selectedSlotId: selectedSlotId,
              onSlotTap: onSlotTap,
            ),
        ],
      ),
    );
  }
}

