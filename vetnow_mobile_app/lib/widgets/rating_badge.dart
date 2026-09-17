import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Small "★ 4.9 (128)" pill used on cards and detail headers.
///
/// With no reviews yet it shows a neutral "new" pill instead of "★ 0.0": a
/// clinic nobody has rated is not a clinic everyone rated zero, and the two
/// must not look the same.
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final bool dense;

  /// Label for the no-reviews state. Passed in rather than looked up here so
  /// this widget stays independent of the localisation delegate.
  final String? emptyLabel;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.dense = false,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 3 : 4),
        decoration: BoxDecoration(
          color: AppColors.bgMuted,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded, size: dense ? 12 : 14, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Text(
              emptyLabel ?? '—',
              style: TextStyle(
                fontSize: dense ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 3 : 4),
      decoration: BoxDecoration(
        color: AppColors.goldSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: dense ? 12 : 14, color: AppColors.gold),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: dense ? 10 : 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
