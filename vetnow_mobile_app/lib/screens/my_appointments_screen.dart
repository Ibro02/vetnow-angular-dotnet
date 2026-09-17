import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../services/api_client.dart';
import '../services/appointment_api_service.dart';
import '../state/resume_refresh.dart';
import '../state/auth_state.dart';
import '../widgets/auth_prompt.dart';
import '../widgets/hover_card.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/section_hero.dart';
import '../widgets/skeleton.dart';
import '../widgets/list_end.dart';
import '../widgets/offline_notice.dart';
import '../widgets/state_views.dart';
import 'appointment_detail_screen.dart';

/// Premium tabbed appointments view: Upcoming / Past, each rendered as
/// a rich card. Tapping a card opens AppointmentDetailScreen.
///
/// Backed by GET /api/Appointment/GetByCustomerId with `includePast`, so one
/// request fills both tabs. The split is done here, by comparing each slot to
/// the current time.
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

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, ResumeRefresh<MyAppointmentsScreen>
    implements Revisitable {
  // A visit cancelled or moved from the web should not still read as
  // booked because this screen was left open since yesterday.
  @override
  Future<void> onResumeRefresh() => _load();

  @override
  Future<void> onRevisit() => _load();

  late final TabController _tabController;
  bool _loaded = false;
  bool _isLoading = true;

  /// True while the list on screen came off the disk rather than the
  /// network, so the screen can say so instead of quietly presenting
  /// three-day-old appointments as current.
  bool _showingCached = false;
  String? _error;
  List<Appointment> _upcoming = [];
  List<Appointment> _past = [];

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
      // Skeletons only when there is nothing to show yet. A refresh
      // over a list that is already on screen used to wipe it back to
      // placeholders for as long as the request took, which made a
      // pull-to-refresh look like the appointments had been lost.
      _isLoading = _upcoming.isEmpty && _past.isEmpty;
      _error = null;
    });
    try {
      final remote = await AppointmentApiService.getByCustomer(
        customerId: auth.userId!,
        token: auth.token!,
        includePast: true,
      );
      if (!mounted) return;

      // Split by the actual appointment time, not by date: a visit at 08:30
      // this morning belongs under "past visits" by the afternoon, and used
      // to sit in "upcoming" all day.
      final now = DateTime.now();
      final upcoming = <Appointment>[];
      final past = <Appointment>[];
      for (final r in remote) {
        final appointment = _toAppointment(r, now);
        (appointment.dateTime.isBefore(now) ? past : upcoming).add(appointment);
      }

      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      // Most recent visit first — the one someone is most likely to look up.
      past.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      setState(() {
        _upcoming = upcoming;
        _past = past;
        _isLoading = false;
        _showingCached = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (await _showCached(auth.userId!)) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      if (await _showCached(auth.userId!)) return;
      setState(() {
        _isLoading = false;
        _error = 'network';
      });
    }
  }

  /// Falls back to the last list this account saw.
  ///
  /// Returns true when it found something, so the caller knows not to
  /// show an error over the top of it. A phone in a lift, in a
  /// basement or out of credit used to get an error page built on data
  /// the app had already downloaded and then thrown away — and
  /// somebody at a clinic counter checking when their appointment is
  /// has precisely the wrong problem for that.
  ///
  /// Only when there is nothing on screen already. A refresh that
  /// fails over a good list should leave the good list alone rather
  /// than replace it with an older one.
  Future<bool> _showCached(int userId) async {
    if (_upcoming.isNotEmpty || _past.isNotEmpty) {
      setState(() => _isLoading = false);
      return true;
    }

    final cached = await AppointmentApiService.cachedFor(userId);
    if (!mounted || cached == null || cached.isEmpty) return false;

    final now = DateTime.now();
    final upcoming = <Appointment>[];
    final past = <Appointment>[];
    for (final r in cached) {
      final appointment = _toAppointment(r, now);
      (appointment.dateTime.isBefore(now) ? past : upcoming).add(appointment);
    }
    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    past.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    setState(() {
      _upcoming = upcoming;
      _past = past;
      _isLoading = false;
      _error = null;
      _showingCached = true;
    });
    return true;
  }

  Appointment _toAppointment(RemoteAppointment r, DateTime now) {
    final staffName = [r.employeeFirstName, r.employeeLastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return Appointment(
      id: r.id,
      employeeId: r.employeeId,
      vetStationId: r.vetStationId,
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
      status: r.slotDateTime.isBefore(now)
          ? AppointmentStatus.completed
          : AppointmentStatus.upcoming,
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
                    indicator: BoxDecoration(
                        color: AppGradients.selectedSolid,
                        borderRadius: BorderRadius.circular(AppRadius.full)),
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
              // Only once there is a list to qualify. A cached list
              // with nothing marking it as cached is worse than an
              // error page: an error tells you to try again, while
              // three-day-old appointments shown as current will send
              // somebody to a clinic on the wrong day.
              if (_showingCached) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding),
                  child: OfflineNotice(onRetry: _load),
                ),
                const SizedBox(height: AppSpacing.s3),
              ],
              Expanded(
                child: _isLoading
                    // Scrollable, like the list it stands in for. Three
                    // appointment-shaped placeholders are taller than a
                    // 320x568 screen, and in a plain Column that is a
                    // flash of overflow stripes on every load — on the
                    // smallest phones, the first thing anyone sees.
                    ? ListView(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                        children: [
                          SkeletonList(count: 3, itemBuilder: () => const AppointmentCardSkeleton()),
                        ],
                      )
                    : _error != null
                        // A failed request is not an empty calendar. It used
                        // to be passed through as the empty-state text, so
                        // "you have nothing booked" and "we couldn't ask"
                        // read identically — and neither offered a way out.
                        ? ErrorStateView(message: _error, onRetry: _load)
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _AppointmentList(
                                appointments: _upcoming,
                                emptyText: l10n.noUpcoming,
                                emptyIcon: Icons.event_busy_outlined,
                                onChanged: _load,
                              ),
                              _AppointmentList(
                                appointments: _past,
                                emptyText: l10n.noPast,
                                emptyIcon: Icons.history_rounded,
                                onChanged: _load,
                              ),
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
  final IconData emptyIcon;
  final VoidCallback onChanged;

  const _AppointmentList({
    required this.appointments,
    required this.emptyText,
    required this.emptyIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Wrapped either way — an empty tab is exactly where someone is most
    // likely to pull down expecting a refresh.
    return RefreshIndicator(
      onRefresh: () async => onChanged(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: appointments.isEmpty
          ? EmptyStateView(icon: emptyIcon, text: emptyText)
          : _list(),
    );
  }

  Widget _list() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 110),
      // One past the end, for the mark that closes the list. Built
      // this way rather than by wrapping the list in a Column so the
      // rows stay lazy.
      itemCount: appointments.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, i) => i == appointments.length
          ? const ListEnd()
          : _AppointmentCard(appointment: appointments[i], onChanged: onChanged),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onChanged;
  const _AppointmentCard({required this.appointment, required this.onChanged});

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
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a)),
        );
        if (changed == true) onChanged();
      },
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
                          Icon(Icons.pets, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${a.petName} · ${a.serviceName}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              a.staffName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primary),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    _relativeDate(a.dateTime),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text),
                                  ),
                                ),
                              ],
                            ),
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
