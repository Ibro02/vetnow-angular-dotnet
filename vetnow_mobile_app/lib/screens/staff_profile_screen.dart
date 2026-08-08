import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/service_catalog.dart';
import '../models/review.dart';
import '../models/staff_member.dart';
import '../models/vet_station.dart';
import '../widgets/rating_badge.dart';
import 'booking_screen.dart';

/// Tapped from the staff list on VetStationDetailScreen. Shows this
/// person's own services (each with its own price + duration — the
/// per-employee granularity the current backend model doesn't have
/// yet) and their individual reviews. Booking a service here jumps
/// straight into BookingScreen with both service and staff preselected,
/// skipping straight to the time-slot step.
class StaffProfileScreen extends StatelessWidget {
  final StaffMember staff;
  final VetStation station;

  const StaffProfileScreen({super.key, required this.staff, required this.station});

  static const _reviews = [
    Review(authorName: 'Selma K.', rating: 5, comment: 'Very patient with a nervous dog, highly recommend.', timeAgo: '4 days ago'),
    Review(authorName: 'Ivan T.', rating: 5, comment: 'Clear explanations, no rushing.', timeAgo: '2 weeks ago'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, AppSpacing.s10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          height: 88,
                          width: 88,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.accent, AppColors.primary]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 19)),
                        const SizedBox(height: 2),
                        Text(staff.role, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: AppSpacing.s2),
                        RatingBadge(rating: staff.rating, reviewCount: staff.reviewCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  if (staff.bio.isNotEmpty) ...[
                    Text(staff.bio, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                    const SizedBox(height: AppSpacing.s6),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.home_work_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(station.name, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(l10n.servicesWithSpecialist, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: AppSpacing.s3),
                  if (staff.services.isEmpty)
                    Text(l10n.noServicesListed, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5))
                  else
                    ...staff.services.map(
                      (s) => InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              station: station,
                              services: staff.services,
                              preselected: s,
                              preselectedStaff: staff,
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.s2),
                          padding: const EdgeInsets.all(AppSpacing.s3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 38,
                                width: 38,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    ServiceCatalog.color(s.kind),
                                    ServiceCatalog.color(s.kind).withValues(alpha: 0.7),
                                  ]),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(ServiceCatalog.icon(s.kind), color: Colors.white, size: 17),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 11, color: AppColors.textMuted),
                                        const SizedBox(width: 3),
                                        Text('${s.durationMinutes} min', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('${s.priceKm.toStringAsFixed(0)} KM', style: TextStyle(color: ServiceCatalog.color(s.kind), fontWeight: FontWeight.w800, fontSize: 14.5)),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(l10n.reviewsForSpecialist, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: AppSpacing.s3),
                  ..._reviews.map(
                    (r) => Container(
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
                              Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                              Text(r.timeAgo, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < r.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 12,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(r.comment, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                        ],
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
}
