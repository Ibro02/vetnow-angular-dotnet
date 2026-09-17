import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';

/// Says that what is on screen came off the disk rather than the wire.
///
/// A cached list with nothing marking it as cached is worse than an
/// error page: an error tells you to try again, while three-day-old
/// appointments presented as current will send somebody to a clinic on
/// the wrong day. The point of showing stale data is that it is better
/// than nothing, and that only holds while the person knows it is stale.
///
/// Lifted out of Explore, which had this as a private widget and was the
/// only screen with a cache. Pets and Termini now have one too, and
/// three copies of the same bar would have drifted apart within a month.
class OfflineNotice extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflineNotice({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s3, AppSpacing.s2, AppSpacing.s2, AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 15, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.offlineShowingSaved,
              style: TextStyle(fontSize: 11.5, color: AppColors.text, height: 1.35),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: l10n.retry,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.refresh_rounded, size: 17, color: AppColors.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
