import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../services/review_api_service.dart';
import 'app_button.dart';
import 'paw_loader.dart';

/// Day.month.year, the way a date is written locally.
///
/// Deliberately plain rather than relative: "3 days ago" needs correct plural
/// rules in three languages, and a wrong plural reads worse than a date.
String formatReviewDate(DateTime date) => '${date.day}.${date.month}.${date.year}.';

/// The reviews block on a clinic page: score, star spread, the list, and —
/// for someone who actually visited — the prompt to rate that visit.
class ReviewsSection extends StatelessWidget {
  final ReviewSummary? summary;
  final bool isLoading;

  /// The unrated past visit at this clinic, if the signed-in person has one.
  final PendingReview? pending;
  final VoidCallback? onRate;

  const ReviewsSection({
    super.key,
    required this.summary,
    required this.isLoading,
    this.pending,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.reviews, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (data != null && data.hasReviews)
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    '${data.averageRating.toStringAsFixed(1)} · ${l10n.reviewsCount(data.reviewCount)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        if (pending != null && onRate != null) ...[
          _RateVisitPrompt(pending: pending!, onTap: onRate!),
          const SizedBox(height: AppSpacing.s3),
        ],
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s6),
            child: Center(child: PawLoader(size: 28)),
          )
        else if (data == null || !data.hasReviews)
          _EmptyReviews(canRate: pending != null)
        else ...[
          _RatingBreakdown(summary: data),
          const SizedBox(height: AppSpacing.s3),
          ...data.reviews.map((r) => ReviewCard(review: r)),
        ],
      ],
    );
  }
}

/// Shown when a clinic has no reviews at all — deliberately not a zero score.
class _EmptyReviews extends StatelessWidget {
  final bool canRate;
  const _EmptyReviews({required this.canRate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6, horizontal: AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined, size: 26, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.s2),
          Text(
            l10n.noReviewsYet,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.text),
          ),
          if (canRate) ...[
            const SizedBox(height: 4),
            Text(
              l10n.beFirstToReview,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// Star histogram. Gives the average its context: "4.6 from mostly fives"
/// reads very differently from "4.6 from a one and a five".
class _RatingBreakdown extends StatelessWidget {
  final ReviewSummary summary;
  const _RatingBreakdown({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.reviewCount;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      margin: const EdgeInsets.only(bottom: AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          for (int star = 5; star >= 1; star--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    child: Text(
                      '$star',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),
                  const Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: (summary.ratingCounts[star] ?? 0) / total,
                        minHeight: 5,
                        backgroundColor: AppColors.bgMuted,
                        valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${summary.ratingCounts[star] ?? 0}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One review in the feed.
class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary50,
                      child: Icon(Icons.person, size: 13, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        review.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(
                  formatReviewDate(review.createdAt!),
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < review.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                size: 13,
                color: AppColors.gold,
              ),
            ),
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "you were here — how was it?" card. Only ever shown when the backend
/// says this person has an unrated past visit at this clinic.
class _RateVisitPrompt extends StatelessWidget {
  final PendingReview pending;
  final VoidCallback onTap;

  const _RateVisitPrompt({required this.pending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = pending.visitDate;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          gradient: AppGradients.gold,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.rateYourVisit,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date == null ? l10n.rateVisitHint : l10n.visitOn(formatReviewDate(date)),
                    style: const TextStyle(fontSize: 11.5, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for writing a review. Pops `true` once one is saved.
class LeaveReviewSheet extends StatefulWidget {
  final PendingReview pending;
  final String token;

  const LeaveReviewSheet({super.key, required this.pending, required this.token});

  @override
  State<LeaveReviewSheet> createState() => _LeaveReviewSheetState();
}

class _LeaveReviewSheetState extends State<LeaveReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating == 0) {
      setState(() => _error = l10n.pickRating);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ReviewApiService.add(
        appointmentId: widget.pending.appointmentId,
        rating: _rating,
        comment: _comment.text,
        token: widget.token,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // The backend's own wording is the useful message here — "already
      // reviewed", "visit hasn't happened yet" — so it is shown verbatim.
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = l10n.networkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      // Lifts the sheet clear of the keyboard while the comment is typed.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding, AppSpacing.s3, AppSpacing.pagePadding, AppSpacing.s6),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl2),
            topRight: Radius.circular(AppRadius.xl2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: AppSpacing.s5),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Text(
              widget.pending.vetStationName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.text),
            ),
            const SizedBox(height: 2),
            Text(
              widget.pending.visitDate == null
                  ? l10n.rateVisitHint
                  : l10n.visitOn(formatReviewDate(widget.pending.visitDate!)),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s5),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: _submitting ? null : () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 38,
                      color: star <= _rating ? AppColors.gold : AppColors.border,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              controller: _comment,
              enabled: !_submitting,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n.reviewCommentHint,
                filled: true,
                fillColor: AppColors.bgMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            AppButton(
              label: l10n.submitReview,
              icon: Icons.send_rounded,
              isLoading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
