import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/service_catalog.dart';
import '../models/review.dart';
import '../models/staff_member.dart';
import '../models/vet_service.dart';
import '../models/vet_station.dart';
import '../widgets/app_button.dart';
import '../widgets/rating_badge.dart';
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

enum _StaffSort { featured, topRated }

class _VetStationDetailScreenState extends State<VetStationDetailScreen> {
  _StaffSort _staffSort = _StaffSort.featured;

  // TODO: replace with real data from Employee/Services/Reviews endpoints.
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

  static const _reviews = [
    Review(authorName: 'Faruk M.', rating: 5, comment: 'Very gentle with my cat, explained everything clearly.', timeAgo: '2 days ago'),
    Review(authorName: 'Ana P.', rating: 5, comment: 'Booked same-day, no waiting. Great experience.', timeAgo: '1 week ago'),
    Review(authorName: 'Denis H.', rating: 4, comment: 'Good service, a bit pricier than average.', timeAgo: '3 weeks ago'),
  ];

  List<StaffMember> _sortedStaff(BuildContext context) {
    final list = _staff(context);
    if (_staffSort == _StaffSort.topRated) {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  /// All services across every staff member, deduplicated by name, for
  /// people who'd rather pick "what" before "who".
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
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.ink, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(child: Icon(Icons.pets, color: Colors.white, size: 52)),
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
                          RatingBadge(rating: station.rating, reviewCount: station.reviewCount),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text('${station.city} · ${station.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
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
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s3),
                        decoration: BoxDecoration(
                          color: station.openNow ? AppColors.successSoft : AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              station.openNow ? Icons.check_circle : Icons.schedule,
                              size: 16,
                              color: station.openNow ? AppColors.success : AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              station.openNow ? l10n.openHoursToday : l10n.closedOpensTomorrow,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: station.openNow ? AppColors.success : AppColors.dangerHover,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              () => _staffSort = _staffSort == _StaffSort.featured ? _StaffSort.topRated : _StaffSort.featured,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _staffSort == _StaffSort.topRated ? Icons.star_rounded : Icons.sort,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _staffSort == _StaffSort.topRated ? l10n.filterTopRated : l10n.sortByRating,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      ...staffList.map((s) => _StaffCard(
                            staff: s,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => StaffProfileScreen(staff: s, station: station)),
                            ),
                          )),
                      const SizedBox(height: AppSpacing.s8),
                      Text(l10n.allServices, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: AppSpacing.s3),
                      _ServicesList(services: allServices, station: station),
                      const SizedBox(height: AppSpacing.s8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.reviews, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                              const SizedBox(width: 4),
                              Text('${station.rating} · ${station.reviewCount} reviews', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      ..._reviews.map((r) => _ReviewCard(review: r)),
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
                    child: OutlinedButton.icon(
                      onPressed: () {}, // TODO: launch tel: url with station.contactNumber
                      icon: const Icon(Icons.call, size: 18, color: AppColors.ink),
                      label: Text(l10n.call),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.accent, AppColors.primary]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(staff.role, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  RatingBadge(rating: staff.rating, reviewCount: staff.reviewCount, dense: true),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
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

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 12, backgroundColor: AppColors.primary50, child: Icon(Icons.person, size: 13, color: AppColors.primary)),
                  const SizedBox(width: 6),
                  Text(review.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ],
              ),
              Text(review.timeAgo, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(i < review.rating.round() ? Icons.star_rounded : Icons.star_border_rounded, size: 13, color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 6),
          Text(review.comment, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
