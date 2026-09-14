import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/service_catalog.dart';
import '../models/review.dart';
import '../models/opening_hours.dart';
import '../models/staff_member.dart';
import '../models/vet_service.dart';
import '../models/vet_station.dart';
import '../services/employee_api_service.dart';
import '../services/review_api_service.dart';
import '../services/vet_station_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/clinic_avatar.dart';
import '../widgets/opening_hours_card.dart';
import '../widgets/paw_loader.dart';
import '../widgets/rating_badge.dart';
import '../widgets/reviews.dart';
import '../widgets/verified_badge.dart';
import 'booking_screen.dart';
import 'staff_profile_screen.dart';

/// Mirrors frontend/src/app/pages/vet-station, restructured so staff
/// leads (each with their own priced services) since real bookable
/// time slots are generated per-employee on the backend — the person
/// you pick determines what's actually available.
class VetStationDetailScreen extends StatefulWidget {
  final VetStation station;

  const VetStationDetailScreen({super.key, required this.station});

  @override
  State<VetStationDetailScreen> createState() => _VetStationDetailScreenState();
}

/// Team ordering. "Featured" is the order the backend returned; the
/// alternative sorts by name, because employee ratings do not exist server-side
/// — the old "top rated" option sorted every real staff list by a constant 0.
enum _StaffSort { featured, byName }

class _VetStationDetailScreenState extends State<VetStationDetailScreen> {
  _StaffSort _staffSort = _StaffSort.featured;

  // Real staff for this station, fetched from the backend once the
  // person is logged in (Employee/GetByVetStationId is [Authorize] —
  // see chat notes on the guest-first conflict). Null means "not
  // loaded yet" — guests and the pre-load moment fall back to the
  // illustrative mock list below.
  List<StaffMember>? _realStaff;
  bool _loadingReal = false;
  bool _attemptedLoad = false;

  /// Guarded separately from the staff load: reviews are anonymous, so they
  /// start loading immediately, while staff waits for a session.
  bool _attemptedReviewLoad = false;

  /// Opening hours. Anonymous like the reviews, so both start loading the
  /// moment the page opens rather than waiting on a session.
  OpeningHours? _openingHours;
  bool _loadingHours = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadOpeningHours();
  }

  Future<void> _loadOpeningHours() async {
    try {
      final hours = await VetStationApiService.openingHours(widget.station.id);
      if (!mounted) return;
      setState(() {
        _openingHours = hours;
        _loadingHours = false;
      });
    } catch (_) {
      if (!mounted) return;
      // The card falls back to "hours not recorded yet", which is the
      // honest thing to show when they could not be read.
      setState(() => _loadingHours = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (auth.isLoggedIn && !_attemptedLoad && !_loadingReal) {
      _attemptedLoad = true;
      _loadRealStaff();
    }
    final token = auth.token;
    if (token != null && !_attemptedReviewLoad) {
      _attemptedReviewLoad = true;
      _loadPendingReview(token);
    }
  }

  /// Which staff role the person is currently looking at. Narrowing is
  /// done by the backend (separate endpoint per TPT subtype), so changing
  /// this refetches rather than filtering the list already on screen.
  StaffRoleFilter _roleFilter = StaffRoleFilter.all;

  String _roleFilterLabel(StaffRoleFilter f, AppLocalizations l10n) => switch (f) {
        StaffRoleFilter.all => l10n.filterAllStaff,
        StaffRoleFilter.vets => ServiceCatalog.roleVeterinarian(context),
        StaffRoleFilter.nurses => ServiceCatalog.roleNurse(context),
        StaffRoleFilter.groomers => ServiceCatalog.roleGroomer(context),
      };

  void _applyRoleFilter(StaffRoleFilter f) {
    if (f == _roleFilter) return;
    setState(() => _roleFilter = f);
    _loadRealStaff();
  }

  Future<void> _loadRealStaff() async {
    final auth = AuthScope.of(context);
    if (auth.token == null) return;
    setState(() => _loadingReal = true);
    try {
      final staff = await EmployeeApiService.getByStationFiltered(
        stationId: widget.station.id,
        token: auth.token!,
        context: context,
        filter: _roleFilter,
      );
      if (!mounted) return;
      setState(() {
        _realStaff = staff;
        _loadingReal = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Keep showing the mock list rather than an empty/broken screen.
      setState(() => _loadingReal = false);
    }
  }

  // TODO: replace with real data from Services/Reviews endpoints —
  // this mock list is also what powers "All services" below, since
  // the backend has no per-employee service/price data at all yet
  // (real staff, once loaded, simply won't have services attached).
  List<StaffMember> _staff(BuildContext context) => [
        StaffMember(
          id: 1,
          name: 'Dr. Amina Hodžić',
          role: ServiceCatalog.roleVeterinarian(context),
          bio: 'Focuses on internal medicine and preventive care, 9 years in practice.',
          rating: 4.9,
          reviewCount: 86,
          services: [
            ServiceCatalog.service(context, ServiceKind.checkup),
            ServiceCatalog.service(context, ServiceKind.vaccination),
          ],
        ),
        StaffMember(
          id: 2,
          name: 'Dr. Emir Kovač',
          role: ServiceCatalog.roleVeterinarian(context),
          bio: 'Surgical lead, dental and soft-tissue procedures.',
          rating: 4.8,
          reviewCount: 54,
          services: [
            ServiceCatalog.service(context, ServiceKind.dental),
            ServiceCatalog.service(context, ServiceKind.checkup),
          ],
        ),
        StaffMember(
          id: 3,
          name: 'Lejla Begić',
          role: ServiceCatalog.roleGroomer(context),
          bio: 'Grooming and nail care for dogs and cats of all sizes.',
          rating: 5.0,
          reviewCount: 41,
          services: [
            ServiceCatalog.service(context, ServiceKind.grooming),
          ],
        ),
      ];

  // ─── Reviews ──────────────────────────────────────────────
  //
  // Loaded anonymously, so a guest weighing up clinics sees the same scores
  // and comments a signed-in customer does. This replaced a hard-coded list
  // of three invented English reviews that every clinic displayed identically.

  ReviewSummary? _reviewSummary;
  bool _loadingReviews = true;

  /// The visit this person can rate at *this* clinic, if there is one.
  /// Only fetched when signed in — the endpoint is per-account.
  PendingReview? _pendingReview;

  Future<void> _loadReviews() async {
    try {
      final summary = await ReviewApiService.getByVetStation(widget.station.id);
      if (!mounted) return;
      setState(() {
        _reviewSummary = summary;
        _loadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      // An empty summary renders as "no reviews yet", which is a truthful
      // thing to show when the feed could not be read.
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _loadPendingReview(String token) async {
    try {
      final pending = await ReviewApiService.pending(token);
      if (!mounted) return;
      final here = pending.where((p) => p.vetStationId == widget.station.id).toList();
      setState(() => _pendingReview = here.isEmpty ? null : here.first);
    } catch (_) {
      // Not being able to offer the prompt is not worth interrupting the
      // page for; the reviews themselves are already on screen.
    }
  }

  Future<void> _openReviewSheet(PendingReview pending) async {
    final auth = AuthScope.of(context);
    final token = auth.token;
    if (token == null) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LeaveReviewSheet(pending: pending, token: token),
    );

    if (submitted == true && mounted) {
      // The score above the list has just changed, so refetch rather than
      // patching it locally and risking a number that disagrees with the API.
      setState(() {
        _pendingReview = null;
        _loadingReviews = true;
      });
      await _loadReviews();
    }
  }

  List<StaffMember> _sortedStaff(BuildContext context) {
    final list = List<StaffMember>.from(_realStaff ?? _staff(context));
    if (_staffSort == _StaffSort.byName) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  /// Opens the phone dialer with the clinic's number.
  ///
  /// The number is stripped of spaces, dashes and brackets — `tel:` will
  /// not resolve otherwise. A device with no dialer (an emulator, a
  /// tablet) simply cannot handle the scheme; that is a normal outcome
  /// here and gets a message, not a crash.
  Future<void> _callStation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final raw = widget.station.contactNumber.replaceAll(RegExp(r'[\s\-()]'), '');

    bool launched = false;
    if (raw.isNotEmpty) {
      try {
        launched = await launchUrl(Uri(scheme: 'tel', path: raw));
      } catch (_) {
        launched = false;
      }
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotPlaceCall)),
      );
    }
  }

  /// Opens the clinic's address in whatever maps app the phone has.
  ///
  /// `geo:0,0?q=<address>` is the Android intent every maps app registers,
  /// so this doesn't hard-code Google Maps. If nothing handles it — an
  /// emulator without maps, or the web build — it falls back to the
  /// Google Maps URL, which any browser can open.
  Future<void> _openInMaps(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final query = [widget.station.address, widget.station.city, widget.station.country]
        .where((p) => p.trim().isNotEmpty)
        .join(', ');
    if (query.isEmpty) return;

    final encoded = Uri.encodeComponent(query);
    final candidates = [
      Uri.parse('geo:0,0?q=$encoded'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'),
    ];

    for (final uri in candidates) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // Try the next one rather than giving up on the first refusal.
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenMaps)),
      );
    }
  }

  /// All services across every staff member, deduplicated by name, for
  /// people who'd rather pick "what" before "who". Always sourced from
  /// the mock catalog (see note above) regardless of whether real
  /// staff loaded, since the backend has no service data to source
  /// this from either way.
  List<VetService> _allServices(BuildContext context) {
    final seen = <String>{};
    final result = <VetService>[];
    for (final s in _staff(context)) {
      for (final service in s.services) {
        if (seen.add(service.name)) result.add(service);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final l10n = AppLocalizations.of(context)!;
    final staffList = _sortedStaff(context);
    final allServices = _allServices(context);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.ink,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  // The clinic's own gradient block, flown in from the card
                  // that was tapped. It used to be the same ink panel with the
                  // same paw for every clinic, so arriving here told you
                  // nothing about where you'd arrived.
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: clinicHeroTag(station.id),
                        child: ClinicAvatar(station: station, discSize: 86, fontSize: 30),
                      ),
                      // Each clinic's gradient is a different brightness, so
                      // the white back arrow can't rely on any one of them for
                      // contrast. A short scrim at the very top guarantees it.
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 96,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x4D0F2E2C), Color(0x000F2E2C)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.s5,
                    AppSpacing.pagePadding,
                    AppSpacing.s16 + AppSpacing.s10, // room for sticky CTA bar
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(station.name, style: Theme.of(context).textTheme.headlineMedium)),
                          if (station.verifiedPartner) const VerifiedBadge(compact: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBadge(
                            rating: _reviewSummary?.averageRating ?? station.rating,
                            reviewCount: _reviewSummary?.reviewCount ?? station.reviewCount,
                            emptyLabel: l10n.noRatingsYet,
                          ),
                          const SizedBox(width: 10),
                          // The clinic address, not the placeholder distance that
                          // used to read "0.0 km" on every single clinic — and
                          // tappable, since an address someone can't navigate to
                          // is just decoration.
                          if (station.locationLine.isNotEmpty)
                            Expanded(
                              child: InkWell(
                                onTap: () => _openInMaps(context),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          station.locationLine,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.north_east_rounded, size: 11, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (station.verifiedPartner) ...[
                        const SizedBox(height: AppSpacing.s3),
                        InkWell(
                          onTap: () => _showVerifiedInfo(context),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(l10n.whatIsVerifiedPartner, style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s5),
                      // Real hours, per day, from the staff schedules — this
                      // was a fixed line reading the same thing on every
                      // clinic, and claiming 18:00 where the data says 16:00.
                      OpeningHoursCard(hours: _openingHours, isLoading: _loadingHours),
                      const SizedBox(height: AppSpacing.s6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (station.inOffice)
                            _FeaturePill(icon: Icons.local_hospital_outlined, label: l10n.amenityInOffice, explanation: l10n.amenityInOfficeDesc),
                          if (station.onField)
                            _FeaturePill(icon: Icons.home_work_outlined, label: l10n.amenityOnField, explanation: l10n.amenityOnFieldDesc),
                          if (station.parking)
                            _FeaturePill(icon: Icons.local_parking_outlined, label: l10n.amenityParking, explanation: l10n.amenityParkingDesc),
                          if (station.wheelchair)
                            _FeaturePill(icon: Icons.accessible_outlined, label: l10n.amenityWheelchair, explanation: l10n.amenityWheelchairDesc),
                          if (station.wifi)
                            _FeaturePill(icon: Icons.wifi, label: l10n.amenityWifi, explanation: l10n.amenityWifiDesc),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.meetTheTeam, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          InkWell(
                            onTap: () => setState(
                              () => _staffSort = _staffSort == _StaffSort.featured ? _StaffSort.byName : _StaffSort.featured,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _staffSort == _StaffSort.byName ? Icons.sort_by_alpha_rounded : Icons.sort,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _staffSort == _StaffSort.byName ? l10n.sortByName : l10n.sortDefault,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Role filter. Only shown once real staff are loaded —
                      // the illustrative guest list isn't something the
                      // backend can narrow, so offering a filter over it
                      // would be a control that quietly does nothing.
                      if (_realStaff != null) ...[
                        const SizedBox(height: AppSpacing.s3),
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final f in StaffRoleFilter.values) ...[
                                _RoleChip(
                                  label: _roleFilterLabel(f, l10n),
                                  selected: _roleFilter == f,
                                  onTap: () => _applyRoleFilter(f),
                                ),
                                const SizedBox(width: AppSpacing.s2),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.s3),
                      if (_loadingReal)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.s6),
                          child: Center(child: PawLoader(size: 28, color: AppColors.primary)),
                        )
                      else
                        ...staffList.map((s) => _StaffCard(
                              staff: s,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => StaffProfileScreen(staff: s, station: station)),
                              ),
                            )),
                      const SizedBox(height: AppSpacing.s8),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.gold],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.allServices, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  const SizedBox(height: AppSpacing.s3),
                                  _ServicesList(services: allServices, station: station),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      ReviewsSection(
                        summary: _reviewSummary,
                        isLoading: _loadingReviews,
                        pending: _pendingReview,
                        onRate: _pendingReview == null ? null : () => _openReviewSheet(_pendingReview!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.s3,
                AppSpacing.pagePadding,
                AppSpacing.s3 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: l10n.call,
                      icon: Icons.call,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _callStation(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    flex: 3,
                    child: AppButton(
                      label: l10n.book,
                      icon: Icons.calendar_month_outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BookingScreen(station: station, services: allServices)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerifiedInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.s6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.xl2), topRight: Radius.circular(AppRadius.xl2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VerifiedBadge(),
            const SizedBox(height: AppSpacing.s4),
            Text(l10n.whatIsVerifiedPartner, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: AppSpacing.s2),
            Text(
              l10n.verifiedPartnerExplanation,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.s5),
            AppButton(label: l10n.gotIt, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String explanation;
  const _FeaturePill({required this.icon, required this.label, required this.explanation});

  void _showExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.s6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.xl2), topRight: Radius.circular(AppRadius.xl2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(explanation, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showExplanation(context),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 11, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember staff;
  final VoidCallback onTap;
  const _StaffCard({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s3),
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.text)),
                  Text(staff.role, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  // Only shown when there is a score behind it. Employee
                  // ratings are not recorded on the backend, so real staff
                  // would otherwise all wear an identical empty badge.
                  if (staff.reviewCount > 0)
                    RatingBadge(rating: staff.rating, reviewCount: staff.reviewCount, dense: true),
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
    );
  }
}

class _ServicesList extends StatelessWidget {
  final List<VetService> services;
  final VetStation station;
  const _ServicesList({required this.services, required this.station});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: services
          .map(
            (s) => InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookingScreen(station: station, services: services, preselected: s)),
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.s3),
                padding: const EdgeInsets.all(AppSpacing.s4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          ServiceCatalog.color(s.kind),
                          ServiceCatalog.color(s.kind).withValues(alpha: 0.7),
                        ]),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(ServiceCatalog.icon(s.kind), color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text('${s.durationMinutes} min', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.priceKm.toStringAsFixed(0)} KM',
                      style: TextStyle(color: ServiceCatalog.color(s.kind), fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Pill used for the staff role filter. Deliberately lighter than the
/// booking slot chips — this narrows a list, it doesn't commit to
/// anything, so it shouldn't shout as loudly as a selectable time.
class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? Colors.transparent : AppColors.border),
          boxShadow: selected ? AppShadows.glow(AppColors.primary) : AppShadows.card,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
