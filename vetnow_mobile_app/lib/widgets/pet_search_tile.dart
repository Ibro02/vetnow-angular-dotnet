import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';

/// The circle at the tail of the pet row that opens the search.
///
/// Muted rather than gradient-filled, so it reads as "and the rest of
/// them" instead of as another animal.
class PetSearchTile extends StatelessWidget {
  final VoidCallback onTap;

  const PetSearchTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.allPets,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 59,
                width: 59,
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(Icons.search_rounded,
                    size: 22, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.allPets,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
