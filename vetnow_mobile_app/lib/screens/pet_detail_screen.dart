import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import '../services/api_client.dart';
import '../services/pets_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/hero_shell.dart';
import '../widgets/paw_loader.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/pet_age.dart';
import '../widgets/premium_dialog.dart';

/// Shows a pet's profile — mirrors Animal.cs fields where the backend
/// has them (name, species, breed, birth date) plus a couple that
/// aren't on the Animal table yet (weight, microchip — see pet.dart).
/// Deleting calls DELETE /api/Pets/SoftDelete (real, [Authorize]).
class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);
    if (auth.token == null) return;

    final confirmed = await showPremiumConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      accentColor: AppColors.danger,
      title: l10n.deletePetConfirmTitle(widget.pet.name),
      message: l10n.deletePetConfirmMessage,
      confirmLabel: l10n.deletePetAction,
      cancelLabel: l10n.keepIt,
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await PetsApiService.delete(id: widget.pet.id, token: auth.token!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
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
            actions: [
              IconButton(
                icon: _isDeleting
                    ? const PawLoader(size: 18, color: Colors.white)
                    : const Icon(Icons.delete_outline_rounded, color: Colors.white),
                onPressed: _isDeleting ? null : _delete,
                tooltip: l10n.deletePet,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.ink)),
                  // The same lit-from-the-top-left surface every other
                  // header in the app is built on.
                  const IgnorePointer(
                    child: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.inkSheen)),
                  ),
                  const HeroVignette(),
                  Center(
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
                          // This pet's own portrait, not the generic paw every
                          // pet used to share.
                          child: PetAvatar(species: pet.species, seed: pet.id, size: 78),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Text(pet.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(
                          pet.species.isNotEmpty
                              ? '${pet.species} · ${petAgeLabel(context, pet)}'
                              : petAgeLabel(context, pet),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.details,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: AppSpacing.s3),
                  _InfoGrid(pet: pet),
                  const SizedBox(height: AppSpacing.s8),
                  Text(l10n.vaccinationHistory,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMuted)),
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
      (Icons.pets_outlined, l10n.species, pet.species.isNotEmpty ? pet.species : '—'),
      (Icons.category_outlined, l10n.breed, pet.breed.isNotEmpty ? pet.breed : '—'),
      (Icons.cake_outlined, l10n.age, petAgeLabel(context, pet)),
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
                  Expanded(
                      child: Text(rows[i].$2,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
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
            child: Icon(Icons.vaccines_outlined, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            l10n.noVaccinationRecords,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}
