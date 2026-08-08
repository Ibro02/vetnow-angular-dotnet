import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../services/api_client.dart';
import '../services/appointment_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/auth_prompt.dart';
import '../widgets/hover_card.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/paw_loader.dart';
import '../widgets/section_hero.dart';
import 'appointment_detail_screen.dart';

/// Premium tabbed appointments view: Upcoming / Past, each rendered as
/// a rich card. Tapping a card opens AppointmentDetailScreen.
///
/// Backed by GET /api/Appointment/GetByCustomerId (real, [Authorize] —
/// fine since this screen already sits behind our login gate). That
/// endpoint only returns appointments with SlotDateTime >= today, so
/// everything it returns lands in Upcoming; the backend has no "past
/// appointments" endpoint yet, so Past stays empty until one exists.
///
/// Note: the backend has no service price/duration/description data
/// at all yet, so those fields show as blank/zero on real appointments
/// — see chat notes on the missing Services table.
class MyAppointmentsScreen extends StatefulWidget {
  final bool embedded;

  const MyAppointmentsScreen({super.key, this.embedded = false});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loaded = false;
  bool _isLoading = true;
  String? _error;
  List<Appointment> _upcoming = [];

  final List<Appointment> _past = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (!_loaded && auth.isLoggedIn) {
      _loaded = true;
      _load();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    if (auth.token == null || auth.userId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final remote = await AppointmentApiService.getByCustomer(customerId: auth.userId!, token: auth.token!);
      if (!mounted) return;
      setState(() {
        _upcoming = remote.map(_toAppointment).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'network';
      });
    }
  }

  Appointment _toAppointment(RemoteAppointment r) {
    final staffName = [r.employeeFirstName, r.employeeLastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return Appointment(
      id: r.id,
      clinicName: r.vetStationName ?? '',
      clinicAddress: '',
      clinicPhone: '',
      staffName: staffName.isNotEmpty ? staffName : '—',
      staffRole: '',
      petName: r.animalName ?? '',
      serviceName: r.speciesName ?? '',
      serviceDescription: '',
      priceKm: 0,
      durationMinutes: 0,
      dateTime: r.slotDateTime,
      status: AppointmentStatus.upcoming,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    final Widget content = !auth.isLoggedIn
        ? AuthPrompt(
            icon: Icons.event_outlined,
            title: l10n.noAppointmentsYet,
            message: l10n.guestMessage,
            benefits: [
              l10n.guestBenefit1,
              l10n.guestBenefit2,
              l10n.guestBenefit3,
            ],
          )
        : Column(
            children: [
              SectionHero(
                title: l10n.myAppointments,
                subtitle: l10n.appointmentsSubtitle,
                leading: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.accent, AppColors.gold]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 24),
                  ),
                ),
                chips: [
                  HeroChip(icon: Icons.event_available, value: '${_upcoming.length}', label: l10n.upcoming),
                  HeroChip(icon: Icons.check_circle_outline, value: '${_past.length}', label: l10n.pastVisits),
                ],
              ),
              const SizedBox(height: AppSpacing.s5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.bgMuted, borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadius.full)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    tabs: [
                      Tab(text: '${l10n.upcoming} (${_upcoming.length})'),
                      Tab(text: '${l10n.pastVisits} (${_past.length})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Expanded(
                child: _isLoading
                    ? const Center(child: PawLoader(size: 28, color: AppColors.primary))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _AppointmentList(appointments: _upcoming, emptyText: _error ?? l10n.noUpcoming),
                          _AppointmentList(appointments: _past, emptyText: l10n.noPast),
                        ],
                      ),
              ),
            ],
          );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.myAppointments),
      body: SafeArea(child: content),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<Appointment> appointments;
  final String emptyText;
  const _AppointmentList({required this.appointments, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Text(emptyText, style: const TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, AppSpacing.s8),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, i) => _AppointmentCard(appointment: appointments[i]),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final l10n = AppLocalizations.of(context)!;
    final (accentColor, statusLabel, statusIcon) = switch (a.status) {
      AppointmentStatus.upcoming => (AppColors.primary, l10n.upcoming, Icons.event_available),
      AppointmentStatus.completed => (AppColors.success, l10n.statusCompleted, Icons.check_circle),
      AppointmentStatus.cancelled => (AppColors.danger, l10n.statusCancelled, Icons.cancel_outlined),
    };

    return HoverCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl),
                    bottomLeft: Radius.circular(AppRadius.xl),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.clinicName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 10, color: accentColor),
                                const SizedBox(width: 3),
                                Text(statusLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: accentColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.pets, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Text('${a.petName} · ${a.serviceName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Text(a.staffName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(_relativeDate(a.dateTime), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                            ],
                          ),
                          if (a.priceKm > 0)
                            Text('${a.priceKm.toStringAsFixed(0)} KM', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relativeDate(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Tomorrow · $time';
    if (diff == -1) return 'Yesterday · $time';
    return '${days[d.weekday - 1]}, ${d.day}/${d.month} · $time';
  }
}
