import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import '../services/api_client.dart';
import '../services/pets_api_service.dart';
import '../services/species_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/paw_loader.dart';
import '../widgets/vet_hero_background.dart';
import '../widgets/section_title.dart';

/// Add-or-edit pet form, saved via POST /api/PetsUpdateOrInsert/Save
/// (real, [Authorize] — fine since this screen sits behind our login
/// gate). Species come from GET /api/SpeciesGetAll/Get (real, anonymous),
/// picked from a searchable sheet since a station could plausibly have
/// dozens of species on file (farms, exotics, etc.) — a Wrap of chips
/// doesn't scale to that. Pass [existingPet] to edit instead of create.
///
/// Weight isn't sent — the Animal table has no weight column yet (see
/// the note in models/pet.dart); the field stays local-only for now.
class AddPetScreen extends StatefulWidget {
  final Pet? existingPet;

  const AddPetScreen({super.key, this.existingPet});

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

  bool get _isEditing => widget.existingPet != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingPet != null) {
      _nameController.text = widget.existingPet!.name;
      _birthDate = widget.existingPet!.birthDate;
      _weightController.text = widget.existingPet!.weightKg?.toString() ?? '';
    }
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
        if (widget.existingPet?.speciesId != null) {
          final matches = species.where((s) => s.id == widget.existingPet!.speciesId);
          _selectedSpecies = matches.isNotEmpty ? matches.first : (species.isNotEmpty ? species.first : null);
        } else {
          _selectedSpecies = species.isNotEmpty ? species.first : null;
        }
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

  String? _ageLabelFor(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) years--;
    if (years < 1) {
      final months = (now.difference(birthDate).inDays / 30).floor();
      return '$months mo';
    }
    return '$years yr';
  }

  void _openSpeciesPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _SpeciesPickerSheet(
        options: _speciesOptions,
        colorFor: _colorFor,
        iconFor: _iconFor,
        selectedId: _selectedSpecies?.id,
        onSelect: (s) {
          setState(() => _selectedSpecies = s);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
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
        id: widget.existingPet?.id,
        name: _nameController.text.trim(),
        animalSpeciesId: _selectedSpecies?.id,
        birthDate: _birthDate,
        isFavourite: widget.existingPet?.isFavourite,
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
    final speciesIndex = _selectedSpecies != null ? _speciesOptions.indexOf(_selectedSpecies!) : -1;
    final ageLabel = _ageLabelFor(_birthDate);

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 176,
            pinned: true,
            backgroundColor: AppColors.ink,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.ink, _selectedColor.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  const VetHeroBackground(showPulse: false, showFloatingHearts: true),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 76,
                          width: 76,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                            boxShadow: [BoxShadow(color: _selectedColor.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                            child: Icon(
                              speciesIndex >= 0 ? _iconFor(speciesIndex) : Icons.pets,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        Text(
                          _isEditing ? l10n.editPet : l10n.tellUsAboutFriend,
                          style: const TextStyle(fontFamily: AppFonts.display, fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
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
                        Text(l10n.species, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        if (_isLoadingSpecies)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: PawLoader(size: 22, color: AppColors.primary),
                          )
                        else
                          InkWell(
                            onTap: _speciesOptions.isEmpty ? null : _openSpeciesPicker,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.bgSoft,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [_selectedColor, _selectedColor.withValues(alpha: 0.7)]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(speciesIndex >= 0 ? _iconFor(speciesIndex) : Icons.pets, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedSpecies?.name ?? l10n.chooseSpecies,
                                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.text),
                                    ),
                                  ),
                                  Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.s5),
                        InkWell(
                          onTap: _pickBirthDate,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSoft,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
                                  child: const Icon(Icons.cake_outlined, size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _birthDate != null
                                            ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                            : l10n.selectBirthDate,
                                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.text),
                                      ),
                                      if (ageLabel != null)
                                        Text(l10n.approxAge(ageLabel), style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                              ],
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
                  AppButton(label: _isEditing ? l10n.saveChanges : l10n.savePet, icon: Icons.favorite_rounded, onPressed: _save, isLoading: _isSaving),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesPickerSheet extends StatefulWidget {
  final List<SpeciesOption> options;
  final Color Function(int) colorFor;
  final IconData Function(int) iconFor;
  final int? selectedId;
  final ValueChanged<SpeciesOption> onSelect;

  const _SpeciesPickerSheet({
    required this.options,
    required this.colorFor,
    required this.iconFor,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_SpeciesPickerSheet> createState() => _SpeciesPickerSheetState();
}

class _SpeciesPickerSheetState extends State<_SpeciesPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options.where((s) => s.name.toLowerCase().contains(query)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl2), topRight: Radius.circular(AppRadius.xl2)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s3),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s4, AppSpacing.s6, AppSpacing.s3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionTitle(l10n.chooseSpecies, fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                      child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                autofocus: false,
                decoration: InputDecoration(
                  hintText: l10n.searchSpeciesHint,
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.bgSoft,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide(color: AppColors.border)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(l10n.noSpeciesFound, style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s2, AppSpacing.s6, AppSpacing.s8),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final s = filtered[i];
                        final originalIndex = widget.options.indexOf(s);
                        final color = widget.colorFor(originalIndex);
                        final selected = widget.selectedId == s.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                          child: InkWell(
                            onTap: () => widget.onSelect(s),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s3),
                              decoration: BoxDecoration(
                                color: selected ? color.withValues(alpha: 0.10) : AppColors.bgSoft,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: selected ? color : AppColors.borderLight, width: selected ? 1.5 : 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(widget.iconFor(originalIndex), color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: AppSpacing.s3),
                                  Expanded(
                                    child: Text(s.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.text)),
                                  ),
                                  if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
