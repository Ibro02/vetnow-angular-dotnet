import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/service_catalog.dart';
import '../models/review.dart';
import '../models/staff_member.dart';
import '../models/vet_station.dart';
import '../widgets/app_button.dart';
import '../widgets/rating_badge.dart';
import 'booking_screen.dart';

/// Tapped from the staff list on VetStationDetailScreen. Premium
/// full-bleed hero (avatar, name, role, rating) instead of a flat app
/// bar + separately-centered avatar — the previous version had the
/// gradient bar touching the content with zero gap, making the two
/// look like one merged shape.
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.ink,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppGradients.ink,
                    ),
                    child: Stack(
                      children: [
                        // Faint decorative rings for depth, echoing the
                        // vet-brand paw motif without being literal.
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 20),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 96,
                                width: 96,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                                  boxShadow: AppShadows.glow(AppColors.accent),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [AppColors.accent, AppColors.gold]),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 44),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s3),
                              Text(
                                staff.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                staff.role,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                              ),
                              const SizedBox(height: AppSpacing.s3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: RatingBadge(rating: staff.rating, reviewCount: staff.reviewCount, dense: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s6, AppSpacing.pagePadding, AppSpacing.s16 + AppSpacing.s10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (staff.bio.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.s4),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Text(staff.bio, style: const TextStyle(color: AppColors.primaryDark, fontSize: 13, height: 1.5)),
                        ),
                        const SizedBox(height: AppSpacing.s5),
                      ],
                      Row(
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                            child: const Icon(Icons.home_work_outlined, size: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(station.name, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(l10n.servicesWithSpecialist, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                      Text(l10n.reviewsForSpecialist, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
          if (staff.services.isNotEmpty)
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
                child: AppButton(
                  label: l10n.bookAppointment,
                  icon: Icons.calendar_month_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(
                        station: station,
                        services: staff.services,
                        preselectedStaff: staff,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
