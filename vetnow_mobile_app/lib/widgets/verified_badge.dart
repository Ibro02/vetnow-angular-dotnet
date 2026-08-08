import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';

/// "Verified Partner" badge — the trust signal for stations VetNow has
/// vetted and onboarded, shown on cards and the detail header.
class VerifiedBadge extends StatelessWidget {
  final bool compact;

  const VerifiedBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 9, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.glow(AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: compact ? 11 : 13, color: Colors.white),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.verifiedPartner,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
