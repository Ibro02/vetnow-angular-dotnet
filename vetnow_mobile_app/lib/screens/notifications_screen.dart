import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/review.dart';
import '../services/appointment_api_service.dart';
import '../services/review_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/auth_prompt.dart';
import '../widgets/gradient_app_bar.dart';
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

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  bool _started = false;

  List<RemoteAppointment> _upcoming = const [];
  List<PendingReview> _pending = const [];

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
    ]);

    if (!mounted) return;
    setState(() {
      _upcoming = results[0] as List<RemoteAppointment>;
      _pending = results[1] as List<PendingReview>;
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
    if (_upcoming.isEmpty && _pending.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          const SizedBox(height: AppSpacing.s16),
          Column(
            children: [
              Container(
                height: 68,
                width: 68,
                decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                child: const Icon(Icons.notifications_none_rounded, size: 30, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                l10n.notificationsEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, height: 1.45),
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
        // Ratings first: they're the only rows with something to do.
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
      ],
    );
  }
}

