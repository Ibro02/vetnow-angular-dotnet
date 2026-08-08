import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/pets_api_service.dart';
import '../services/species_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/paw_loader.dart';

/// Add-pet form, saved via POST /api/PetsUpdateOrInsert/Save (real,
/// [Authorize] — fine since this screen sits behind our login gate).
/// Species come from GET /api/SpeciesGetAll/Get (real, anonymous).
///
/// Weight isn't sent — the Animal table has no weight column yet (see
/// the note in models/pet.dart); the field stays local-only for now.
class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingSpecies = true;
  String? _error;
  List<SpeciesOption> _speciesOptions = [];
  SpeciesOption? _selectedSpecies;
  DateTime? _birthDate;

  static const _palette = [AppColors.primary, AppColors.accent, AppColors.gold, AppColors.info, AppColors.secondary];
  static const _icons = [Icons.pets, Icons.pets, Icons.flutter_dash, Icons.cruelty_free, Icons.eco];

  Color _colorFor(int index) => _palette[index % _palette.length];
  IconData _iconFor(int index) => _icons[index % _icons.length];

  @override
  void initState() {
    super.initState();
    _loadSpecies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecies() async {
    try {
      final species = await SpeciesApiService.getAll();
      if (!mounted) return;
      setState(() {
        _speciesOptions = species;
        _selectedSpecies = species.isNotEmpty ? species.first : null;
        _isLoadingSpecies = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSpecies = false);
    }
  }

  Color get _selectedColor {
    if (_selectedSpecies == null) return AppColors.primary;
    final index = _speciesOptions.indexOf(_selectedSpecies!);
    return _colorFor(index);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);
    if (auth.token == null) {
      setState(() => _error = l10n.networkError);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await PetsApiService.save(
        token: auth.token!,
        name: _nameController.text.trim(),
        animalSpeciesId: _selectedSpecies?.id,
        birthDate: _birthDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = l10n.networkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 168,
            pinned: true,
            backgroundColor: AppColors.ink,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.ink, _selectedColor.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Icon(
                          _selectedSpecies != null ? _iconFor(_speciesOptions.indexOf(_selectedSpecies!)) : Icons.pets,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      Text(
                        l10n.tellUsAboutFriend,
                        style: const TextStyle(fontFamily: AppFonts.display, fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
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
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.card,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(label: l10n.petName, controller: _nameController, prefixIcon: Icons.badge_outlined),
                        const SizedBox(height: AppSpacing.s5),
                        Text(l10n.species, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        if (_isLoadingSpecies)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: PawLoader(size: 22, color: AppColors.primary),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _speciesOptions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final s = entry.value;
                              final selected = _selectedSpecies?.id == s.id;
                              final color = _colorFor(index);
                              return InkWell(
                                onTap: () => setState(() => _selectedSpecies = s),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: selected ? color.withValues(alpha: 0.14) : AppColors.bgSoft,
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_iconFor(index), size: 15, color: selected ? color : AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        s.name,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: selected ? color : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: AppSpacing.s5),
                        InkWell(
                          onTap: _pickBirthDate,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.age,
                              prefixIcon: const Icon(Icons.cake_outlined, size: 20, color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.surface,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Text(
                              _birthDate != null
                                  ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                  : '—',
                              style: const TextStyle(fontSize: 15, color: AppColors.text),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s5),
                        AppTextField(
                          label: l10n.weightOptional,
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.monitor_weight_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.petInfoNote,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.primaryDark, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.dangerHover))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s6),
                  AppButton(label: l10n.savePet, icon: Icons.favorite_rounded, onPressed: _save, isLoading: _isSaving),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
