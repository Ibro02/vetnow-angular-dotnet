import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../l10n/service_catalog.dart';
import '../models/review.dart';
import '../models/staff_member.dart';
import '../models/vet_station.dart';
import '../widgets/app_button.dart';
import '../services/review_api_service.dart';
import '../widgets/hero_shell.dart';
import '../widgets/paw_loader.dart';
import '../widgets/rating_badge.dart';
import '../widgets/reviews.dart';
import '../widgets/person_avatar.dart';
import '../widgets/section_title.dart';
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
                // Scales with the text: the header holds a 96pt portrait
                // above a name, a role and a rating, and at a larger size
                // that column no longer fits a fixed 260.
                expandedHeight:
                    MediaQuery.textScalerOf(context).scale(260).clamp(260.0, 360.0),
                pinned: true,
                backgroundColor: AppColors.ink,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: DecoratedBox(
                    decoration: const BoxDecoration(gradient: AppGradients.ink),
                    child: Stack(
                      children: [
                        // The same lit-from-the-top-left surface, and the
                        // same vignette, as every other header in the app.
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(gradient: AppGradients.inkSheen),
                            ),
                          ),
                        ),
                        const Positioned.fill(child: HeroVignette()),
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
                                // 86, not 96: the ring around it takes 3pt
                                // of padding and a 2pt border on each side.
                                child: PersonAvatar(
                                  name: staff.name,
                                  size: 86,
                                  colors: const [AppColors.accent, AppColors.gold],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s3),
                              // Padded: a name with a title on it runs the
                              // full width of the screen otherwise, and off
                              // both edges at a larger text size.
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s6,
                                ),
                                child: Text(
                                  staff.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s6,
                                ),
                                child: Text(
                                  staff.role,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s3),
                              // Employee ratings are not recorded on the backend,
                              // so this only appears when a score actually exists.
                              if (staff.reviewCount > 0)
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
                            decoration: BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                            child: Icon(Icons.home_work_outlined, size: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(station.name, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      SectionTitle(l10n.servicesWithSpecialist),
                      const SizedBox(height: AppSpacing.s3),
                      if (staff.services.isEmpty)
                        Text(l10n.noServicesListed, style: TextStyle(color: AppColors.textMuted, fontSize: 12.5))
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
                                            Icon(Icons.schedule, size: 11, color: AppColors.textMuted),
                                            const SizedBox(width: 3),
                                            Text('${s.durationMinutes} min', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${s.priceKm.toStringAsFixed(0)} KM', style: TextStyle(color: ServiceCatalog.color(s.kind), fontWeight: FontWeight.w800, fontSize: 14.5)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.s8),
                      // Reviews are recorded per clinic, not per employee, so
                      // this shows the clinic's feed under a heading that says
                      // so. It used to show two invented reviews attributed to
                      // whichever specialist was on screen — a made-up opinion
                      // about a named real person.
                      SectionTitle(l10n.clinicReviews),
                      const SizedBox(height: AppSpacing.s3),
                      FutureBuilder<ReviewSummary>(
                        future: ReviewApiService.getByVetStation(station.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.s5),
                              child: Center(child: PawLoader(size: 26)),
                            );
                          }
                          final data = snapshot.data;
                          if (data == null || !data.hasReviews) {
                            return Text(
                              l10n.noReviewsYet,
                              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                            );
                          }
                          // Capped: this is context on the clinic, not the
                          // point of the page.
                          return Column(
                            children: data.reviews
                                .take(3)
                                .map((r) => ReviewCard(review: r))
                                .toList(),
                          );
                        },
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
