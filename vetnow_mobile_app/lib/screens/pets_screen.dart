import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import '../services/api_client.dart';
import '../services/pets_api_service.dart';
import '../services/species_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/paw_loader.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

/// Mirrors frontend/src/app/pages/pets-settings. Backed by
/// GET /api/Animal/GetByOwnerId (real, [Authorize] — fine since this
/// screen already sits behind our login gate).
class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  bool _loaded = false;
  bool _isLoading = true;
  String? _error;
  List<Pet> _pets = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    if (auth.token == null || auth.userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'not_logged_in';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Species names aren't included on the Animal entity itself
      // (only animalSpeciesId), so we fetch the species list once to
      // resolve id -> display name.
      final species = await SpeciesApiService.getAll();
      final speciesMap = {for (final s in species) s.id: s.name};

      final pets = await PetsApiService.getByOwner(
        ownerId: auth.userId!,
        token: auth.token!,
        speciesNames: speciesMap,
      );
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'network';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.myPets),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: PawLoader(size: 32, color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.pagePadding),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                      child: Text(l10n.networkError, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    ),
                  ..._pets.map(
                    (p) => InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PetDetailScreen(pet: p)),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s3),
                        padding: const EdgeInsets.all(AppSpacing.s4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 56,
                              width: 56,
                              decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
                              child: const Icon(Icons.pets, color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(width: AppSpacing.s4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.species.isNotEmpty ? '${p.species} · ${p.ageLabel}' : p.ageLabel,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  AppButton(
                    label: l10n.addPet,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.add,
                    onPressed: () async {
                      final added = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const AddPetScreen()),
                      );
                      if (added == true) _load();
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
