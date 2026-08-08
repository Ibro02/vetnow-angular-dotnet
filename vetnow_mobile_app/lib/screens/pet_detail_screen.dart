import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';

/// Shows a pet's profile — mirrors Animal.cs fields where the backend
/// has them (name, species, breed, birth date) plus a couple that
/// aren't on the Animal table yet (weight, microchip — see pet.dart).
class PetDetailScreen extends StatelessWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.ink,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.ink, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 84,
                        width: 84,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.accent, AppColors.gold]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pets, color: Colors.white, size: 38),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      Text(pet.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(
                        '${pet.species} · ${pet.ageLabel}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.details, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: AppSpacing.s3),
                  _InfoGrid(pet: pet),
                  const SizedBox(height: AppSpacing.s8),
                  Text(l10n.vaccinationHistory, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: AppSpacing.s3),
                  const _EmptyVaccinations(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Pet pet;
  const _InfoGrid({required this.pet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <(IconData, String, String)>[
      (Icons.pets_outlined, l10n.species, pet.species),
      (Icons.category_outlined, l10n.breed, pet.breed),
      (Icons.cake_outlined, l10n.age, pet.ageLabel),
      if (pet.weightKg != null) (Icons.monitor_weight_outlined, l10n.weight, '${pet.weightKg} kg'),
      if (pet.microchipNumber != null) (Icons.qr_code_2_outlined, l10n.microchip, pet.microchipNumber!),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
                    child: Icon(rows[i].$1, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(rows[i].$2, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
                  Text(rows[i].$3, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                ],
              ),
            ),
            if (i != rows.length - 1) const Divider(height: 1, indent: 60, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _EmptyVaccinations extends StatelessWidget {
  const _EmptyVaccinations();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
            child: const Icon(Icons.vaccines_outlined, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            l10n.noVaccinationRecords,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
