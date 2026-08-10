import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import '../services/api_client.dart';
import '../services/appointment_api_service.dart';
import '../services/pets_api_service.dart';
import '../services/species_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/paw_loader.dart';
import '../widgets/action_sheet.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/section_hero.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

enum _ViewMode { list, dashboard }

/// "My pets" — two ways to browse, because someone with 2 dogs and
/// someone with 50 farm animals need different tools:
///
/// - List: a small, personal, reorderable stack (drag the whole card —
///   built for a handful of pets you want arranged just so).
/// - Dashboard: a searchable, filterable grid built to stay usable
///   even with a large number of animals.
///
/// Favourite state and visit counts are real (Animal.IsFavourite +
/// counted from GET /api/Appointment/GetByCustomerId). Card ORDER in
/// List view is session-only — the backend has no field to persist a
/// custom sort order.
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
  Map<int, int> _visitCounts = {}; // animalId -> appointment count
  _ViewMode _viewMode = _ViewMode.list;
  final _searchController = TextEditingController();
  String? _speciesFilter;
  bool _favouritesOnly = false;

  static const _palette = [AppColors.primary, AppColors.accent, AppColors.gold, AppColors.info, AppColors.secondary];
  Color _paletteFor(int index) => _palette[index % _palette.length];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final species = await SpeciesApiService.getAll();
      final speciesMap = {for (final s in species) s.id: s.name};

      final pets = await PetsApiService.getByOwner(
        ownerId: auth.userId!,
        token: auth.token!,
        speciesNames: speciesMap,
      );

      Map<int, int> counts = {};
      try {
        final appointments = await AppointmentApiService.getByCustomer(customerId: auth.userId!, token: auth.token!);
        for (final a in appointments) {
          counts[a.animalId] = (counts[a.animalId] ?? 0) + 1;
        }
      } catch (_) {
        // Visit counts are a bonus, not critical — silently show 0s if this fails.
      }

      pets.sort((a, b) {
        if (a.isFavourite != b.isFavourite) return a.isFavourite ? -1 : 1;
        return 0;
      });

      if (!mounted) return;
      setState(() {
        _pets = pets;
        _visitCounts = counts;
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

  Future<void> _toggleFavourite(Pet pet) async {
    final auth = AuthScope.of(context);
    if (auth.token == null) return;
    final newValue = !pet.isFavourite;
    setState(() {
      _pets = _pets.map((p) => p.id == pet.id ? p.copyWith(isFavourite: newValue) : p).toList();
    });
    try {
      await PetsApiService.save(token: auth.token!, id: pet.id, isFavourite: newValue);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pets = _pets.map((p) => p.id == pet.id ? p.copyWith(isFavourite: !newValue) : p).toList();
      });
    }
  }

  Future<void> _deletePet(Pet pet) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = AuthScope.of(context);
    if (auth.token == null) return;

    final confirmed = await showPremiumConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      accentColor: AppColors.danger,
      title: l10n.deletePetConfirmTitle(pet.name),
      message: l10n.deletePetConfirmMessage,
      confirmLabel: l10n.deletePetAction,
      cancelLabel: l10n.keepIt,
      isDangerous: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await PetsApiService.delete(id: pet.id, token: auth.token!);
      if (!mounted) return;
      setState(() => _pets = _pets.where((p) => p.id != pet.id).toList());
    } catch (_) {
      // Leave the pet in place if delete failed — no silent data loss.
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pets.removeAt(oldIndex);
      _pets.insert(newIndex, item);
    });
  }

  List<String> get _availableSpecies {
    final set = <String>{};
    for (final p in _pets) {
      if (p.species.isNotEmpty) set.add(p.species);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Pet> get _filteredPets {
    final query = _searchController.text.trim().toLowerCase();
    return _pets.where((p) {
      final matchesSearch = query.isEmpty || p.name.toLowerCase().contains(query);
      final matchesSpecies = _speciesFilter == null || p.species == _speciesFilter;
      final matchesFavourite = !_favouritesOnly || p.isFavourite;
      return matchesSearch && matchesSpecies && matchesFavourite;
    }).toList();
  }

  (Pet, int)? _mostVisitedPet() {
    if (_visitCounts.isEmpty) return null;
    int? bestId;
    int bestCount = 0;
    _visitCounts.forEach((id, count) {
      if (count > bestCount) {
        bestCount = count;
        bestId = id;
      }
    });
    if (bestId == null) return null;
    final match = _pets.where((p) => p.id == bestId);
    if (match.isEmpty) return null;
    return (match.first, bestCount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final favouriteCount = _pets.where((p) => p.isFavourite).length;
    final mostVisited = _mostVisitedPet();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.myPets),
      floatingActionButton: _isLoading
          ? null
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentHover]),
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AddPetScreen()),
                  );
                  if (added == true) _load();
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: PawLoader(size: 32, color: AppColors.primary))
            : Column(
                children: [
                  SectionHero(
                    title: l10n.myPets,
                    subtitle: l10n.petsDashboardSubtitle,
                    leading: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.accent, AppColors.gold]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 24),
                      ),
                    ),
                    chips: [
                      HeroChip(icon: Icons.pets, value: '${_pets.length}', label: l10n.myPets),
                      HeroChip(icon: Icons.favorite, value: '$favouriteCount', label: l10n.favourites),
                      HeroChip(
                        icon: Icons.event_available,
                        value: mostVisited != null ? mostVisited.$1.name : '—',
                        label: l10n.mostVisited,
                      ),
                    ],
                  ),
                  if (_pets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s4, AppSpacing.pagePadding, 0),
                      child: _ViewModeSwitch(
                        mode: _viewMode,
                        onChanged: (m) => setState(() => _viewMode = m),
                      ),
                    ),
                  Expanded(
                    child: _error != null && _pets.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.pagePadding),
                              child: Text(l10n.networkError, style: const TextStyle(color: AppColors.textMuted)),
                            ),
                          )
                        : _pets.isEmpty
                            ? _EmptyPetsState(l10n: l10n)
                            : (_viewMode == _ViewMode.list ? _buildListView(l10n) : _buildDashboardView(l10n)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildListView(AppLocalizations l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s3, AppSpacing.pagePadding, 0),
          child: Row(
            children: [
              const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.dragWholeCardHint, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s3, AppSpacing.pagePadding, 100),
            itemCount: _pets.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final pet = _pets[index];
              return Padding(
                key: ValueKey(pet.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: _PetListCard(
                    pet: pet,
                    color: _paletteFor(index),
                    visitCount: _visitCounts[pet.id] ?? 0,
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
                      );
                      if (changed == true) _load();
                    },
                    onEdit: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => AddPetScreen(existingPet: pet)),
                      );
                      if (changed == true) _load();
                    },
                    onDelete: () => _deletePet(pet),
                    onToggleFavourite: () => _toggleFavourite(pet),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardView(AppLocalizations l10n) {
    final filtered = _filteredPets;
    final species = _availableSpecies;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s4, AppSpacing.pagePadding, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: AppShadows.card,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.searchPetsHint,
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
                    child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                  ),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () => setState(() => _searchController.clear()),
                      ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            children: [
              _FilterPill(
                label: l10n.favourites,
                icon: Icons.star_rounded,
                selected: _favouritesOnly,
                accentColor: AppColors.gold,
                onTap: () => setState(() => _favouritesOnly = !_favouritesOnly),
              ),
              const SizedBox(width: 8),
              _FilterPill(label: l10n.filterAllSpecies, selected: _speciesFilter == null, onTap: () => setState(() => _speciesFilter = null)),
              ...species.map((s) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterPill(label: s, selected: _speciesFilter == s, onTap: () => setState(() => _speciesFilter = s)),
                  )),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(l10n.noPetsMatchFilter, style: const TextStyle(color: AppColors.textMuted)))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, 0, AppSpacing.pagePadding, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.s3,
                    mainAxisSpacing: AppSpacing.s3,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final pet = filtered[index];
                    final colorIndex = _pets.indexOf(pet);
                    return _PetGridCard(
                      pet: pet,
                      color: _paletteFor(colorIndex),
                      visitCount: _visitCounts[pet.id] ?? 0,
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
                        );
                        if (changed == true) _load();
                      },
                      onEdit: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => AddPetScreen(existingPet: pet)),
                        );
                        if (changed == true) _load();
                      },
                      onDelete: () => _deletePet(pet),
                      onToggleFavourite: () => _toggleFavourite(pet),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ViewModeSwitch extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;
  const _ViewModeSwitch({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.bgMuted, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        children: [
          Expanded(child: _segment(context, _ViewMode.list, Icons.view_list_rounded, l10n.viewList)),
          Expanded(child: _segment(context, _ViewMode.dashboard, Icons.grid_view_rounded, l10n.viewDashboard)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, _ViewMode value, IconData icon, String label) {
    final selected = mode == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [AppColors.ink, AppColors.primaryDark]) : null,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;
  const _FilterPill({required this.label, required this.selected, required this.onTap, this.icon, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.accent;
    final colorHover = accentColor != null ? color : AppColors.accentHover;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: [color, colorHover.withValues(alpha: 0.85)]) : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: selected ? Colors.transparent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 5),
            ],
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _PetListCard extends StatelessWidget {
  final Pet pet;
  final Color color;
  final int visitCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavourite;

  const _PetListCard({
    required this.pet,
    required this.color,
    required this.visitCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: pet.isFavourite ? AppColors.gold.withValues(alpha: 0.5) : AppColors.borderLight, width: pet.isFavourite ? 1.5 : 1),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 26),
                    ),
                    if (pet.isFavourite)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          child: const Icon(Icons.star_rounded, color: Colors.white, size: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (pet.species.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
                              child: Text(pet.species, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
                            ),
                          Text(pet.ageLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          if (visitCount > 0) ...[
                            const Icon(Icons.event_available, size: 12, color: AppColors.textMuted),
                            Text('$visitCount ${l10n.visits}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: onToggleFavourite,
                      icon: Icon(
                        pet.isFavourite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: pet.isFavourite ? AppColors.gold : AppColors.textMuted,
                        size: 22,
                      ),
                      tooltip: pet.isFavourite ? l10n.unmarkFavourite : l10n.markFavourite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    ),
                    InkWell(
                      onTap: () => showActionSheet(
                        context,
                        title: pet.name,
                        items: [
                          ActionSheetItem(icon: Icons.edit_outlined, label: l10n.editPet, color: AppColors.primary, onTap: onEdit),
                          ActionSheetItem(icon: Icons.delete_outline, label: l10n.deletePet, color: AppColors.danger, onTap: onDelete, isDestructive: true),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final Pet pet;
  final Color color;
  final int visitCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavourite;

  const _PetGridCard({
    required this.pet,
    required this.color,
    required this.visitCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: pet.isFavourite ? AppColors.gold.withValues(alpha: 0.6) : AppColors.borderLight, width: pet.isFavourite ? 1.5 : 1),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.65)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: const Center(child: Icon(Icons.pets, color: Colors.white, size: 38)),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: onToggleFavourite,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), shape: BoxShape.circle),
                          child: Icon(
                            pet.isFavourite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: pet.isFavourite ? AppColors.gold : Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: InkWell(
                        onTap: () => showActionSheet(
                          context,
                          title: pet.name,
                          items: [
                            ActionSheetItem(icon: Icons.edit_outlined, label: l10n.editPet, color: AppColors.primary, onTap: onEdit),
                            ActionSheetItem(icon: Icons.delete_outline, label: l10n.deletePet, color: AppColors.danger, onTap: onDelete, isDestructive: true),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), shape: BoxShape.circle),
                          child: const Icon(Icons.more_vert, color: Colors.white, size: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s3, AppSpacing.s2, AppSpacing.s3, AppSpacing.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    if (pet.species.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
                        child: Text(pet.species, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                    const SizedBox(height: 3),
                    Text(pet.ageLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    if (visitCount > 0) ...[
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          const Icon(Icons.event_available, size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text('$visitCount ${l10n.visits}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPetsState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyPetsState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
              child: const Icon(Icons.pets, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(l10n.noPetsYet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
