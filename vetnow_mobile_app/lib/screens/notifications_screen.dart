import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import '../models/review.dart';
import '../services/appointment_api_service.dart';
import '../services/pets_api_service.dart';
import '../services/review_api_service.dart';
import '../state/resume_refresh.dart';
import '../state/auth_state.dart';
import '../widgets/auth_prompt.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/list_end.dart';
import '../widgets/notification_tile.dart';
import '../widgets/reviews.dart';
import '../widgets/skeleton.dart';

/// What the bell in the header actually opens.
///
/// The bell existed but did nothing. Rather than invent a notification
/// system the backend can't feed, this assembles the two things the API
/// already knows and a person actually wants to be reminded of: visits
/// that are still ahead, and visits that are done but unrated.
///
/// Both rows are actionable — a pending review opens the rating sheet
/// right here, so going from "you have something to do" to "done" is one
/// tap rather than a hunt through Explore for the right clinic.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver, ResumeRefresh<NotificationsScreen> {
  @override
  Future<void> onResumeRefresh() => _load();

  bool _loading = true;
  bool _started = false;

  List<RemoteAppointment> _upcoming = const [];
  List<PendingReview> _pending = const [];

  /// Pets with a birthday inside the fortnight. The dates were sitting in
  /// the database all along, used for nothing but an age label.
  List<Pet> _birthdays = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (!_started && auth.isLoggedIn) {
      _started = true;
      _load();
    } else if (!_started) {
      // A guest has nothing to load; don't leave them on a skeleton.
      _started = true;
      _loading = false;
    }
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    final token = auth.token;
    final userId = auth.userId;
    if (token == null || userId == null) return;

    if (mounted) setState(() => _loading = true);

    // Fired together rather than one after the other — they don't depend
    // on each other, and this screen opens from a tap, so the wait is felt.
    final results = await Future.wait([
      AppointmentApiService.getByCustomer(customerId: userId, token: token)
          .catchError((_) => <RemoteAppointment>[]),
      ReviewApiService.pending(token).catchError((_) => <PendingReview>[]),
      // Species names aren't needed to spot a birthday, so the pets are
      // fetched raw and mapped without waiting on the species list.
      PetsApiService.getByOwnerRaw(ownerId: userId, token: token)
          .catchError((_) => <Map<String, dynamic>>[]),
    ]);

    if (!mounted) return;

    final pets = PetsApiService.mapPets(results[2] as List<Map<String, dynamic>>, null);
    final soon = pets.where((p) => p.birthdayIsNear()).toList()
      ..sort((a, b) => a.daysUntilBirthday()!.compareTo(b.daysUntilBirthday()!));

    setState(() {
      _upcoming = results[0] as List<RemoteAppointment>;
      _pending = results[1] as List<PendingReview>;
      _birthdays = soon;
      _loading = false;
    });
  }

  Future<void> _rate(PendingReview pending) async {
    final token = AuthScope.of(context).token;
    if (token == null) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LeaveReviewSheet(pending: pending, token: token),
    );

    if (submitted == true && mounted) {
      // Drop it from the list immediately; the reload confirms.
      setState(() => _pending = _pending.where((p) => p.appointmentId != pending.appointmentId).toList());
      await _load();
    }
  }

  /// "Danas u 08:30" / "Sutra u 08:30" / "14.9.2026. u 08:30".
  String _whenLabel(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final time = '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final days = DateTime(when.year, when.month, when.day).difference(startOfToday).inDays;

    if (days == 0) return l10n.todayAt(time);
    if (days == 1) return l10n.tomorrowAt(time);
    return l10n.dateAt(formatReviewDate(when), time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.notifications),
      body: SafeArea(
        child: !auth.isLoggedIn
            ? AuthPrompt(
                icon: Icons.notifications_none_rounded,
                title: l10n.notifications,
                message: l10n.notificationsGuest,
                benefits: [l10n.guestBenefit1, l10n.guestBenefit2, l10n.guestBenefit3],
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: _loading ? _skeleton() : _content(context, l10n),
              ),
      ),
    );
  }

  Widget _skeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        SkeletonList(count: 3, itemBuilder: () => const AppointmentCardSkeleton()),
      ],
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n) {
    if (_upcoming.isEmpty && _pending.isEmpty && _birthdays.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          const SizedBox(height: AppSpacing.s16),
          Column(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                ),
                child: const Icon(Icons.notifications_none_rounded, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                l10n.notificationsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.45),
              ),
            ],
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.s4,
        AppSpacing.pagePadding,
        AppSpacing.s16,
      ),
      children: [
        // Birthdays lead when one is today — nothing else on this screen
        // is worth burying that under.
        if (_birthdays.isNotEmpty) ...[
          NotificationSectionLabel(text: l10n.notificationsBirthdays, count: _birthdays.length),
          const SizedBox(height: AppSpacing.s3),
          ..._birthdays.map(
            (p) => NotificationTile(
              icon: Icons.cake_rounded,
              iconGradient: AppGradients.gold,
              title: l10n.turnsAge(p.name, l10n.ageYears(p.turningAge() ?? 0)),
              subtitle: p.isBirthdayToday()
                  ? l10n.birthdayToday
                  : l10n.birthdayInDays(p.daysUntilBirthday()!),
              trailingNote: p.species,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
        // Ratings next: they're the only rows with something to do.
        if (_pending.isNotEmpty) ...[
          NotificationSectionLabel(text: l10n.notificationsAwaitingReview, count: _pending.length),
          const SizedBox(height: AppSpacing.s3),
          ..._pending.map(
            (p) => NotificationTile(
              icon: Icons.star_rounded,
              iconGradient: AppGradients.gold,
              title: p.vetStationName,
              subtitle: p.visitDate == null ? null : _whenLabel(context, p.visitDate!),
              actionLabel: l10n.notificationsRateCta,
              onTap: () => _rate(p),
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
        if (_upcoming.isNotEmpty) ...[
          NotificationSectionLabel(text: l10n.notificationsUpcoming, count: _upcoming.length),
          const SizedBox(height: AppSpacing.s3),
          ..._upcoming.map(
            (a) => NotificationTile(
              icon: Icons.event_available_rounded,
              iconGradient: AppGradients.brand,
              title: a.vetStationName ?? '',
              subtitle: _whenLabel(context, a.slotDateTime),
              trailingNote: a.animalName,
            ),
          ),
        ],
        const ListEnd(),
      ],
    );
  }
}

