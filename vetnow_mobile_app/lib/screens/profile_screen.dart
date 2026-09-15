import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import '../services/pets_api_service.dart';
import '../services/species_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/auth_prompt.dart';
import '../widgets/hover_card.dart';
import '../widgets/paw_loader.dart';
import '../widgets/theme_picker.dart';
import '../widgets/pet_age.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/section_hero.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/language_picker.dart';
import '../widgets/section_title.dart';
import 'diagnostics_screen.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';
import 'pets_screen.dart';

/// Premium profile: dark gradient hero with avatar + stats, then
/// sectioned white cards for pets and settings. Mirrors the "ink"
/// hero language used on Explore/Detail so the whole app feels of a
/// piece.
///
/// Pets (both the hero's count chip and the preview row) come from
/// GET /api/Animal/GetByOwnerId — the same real data PetsScreen shows
/// on "View all", loaded once here and shared with both.
class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loaded = false;
  bool _isLoadingPets = true;
  List<Pet> _pets = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    if (!_loaded && auth.isLoggedIn) {
      _loaded = true;
      _loadPets();
    }
  }

  Future<void> _loadPets() async {
    final auth = AuthScope.of(context);
    if (auth.token == null || auth.userId == null) {
      setState(() => _isLoadingPets = false);
      return;
    }
    try {
      // Fired together rather than chained — the species list is only
      // needed to map the pets response, not to request it.
      final results = await Future.wait([
        SpeciesApiService.getAll(),
        PetsApiService.getByOwnerRaw(ownerId: auth.userId!, token: auth.token!),
      ]);

      final species = results[0] as List<SpeciesOption>;
      final speciesMap = {for (final s in species) s.id: s.name};
      final pets = PetsApiService.mapPets(results[1] as List<Map<String, dynamic>>, speciesMap);
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _isLoadingPets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPets = false);
    }
  }

  Future<void> _refreshAfterAdd() async {
    setState(() => _isLoadingPets = true);
    await _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    final Widget content = !auth.isLoggedIn
        ? AuthPrompt(
            icon: Icons.person_outline,
            title: l10n.guestTitle,
            message: l10n.guestMessage,
            benefits: [
              l10n.guestBenefit1,
              l10n.guestBenefit2,
              l10n.guestBenefit3,
            ],
          )
        : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHero(auth: auth, isLoadingPets: _isLoadingPets, petsCount: _pets.length),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s6, AppSpacing.pagePadding, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SectionTitle(l10n.myPets),
                          TextButton(
                            onPressed: () async {
                              final changed = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(builder: (_) => const PetsScreen()),
                              );
                              if (changed == true) _refreshAfterAdd();
                            },
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero),
                            child: Text(l10n.viewAll, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      _PetsRow(isLoading: _isLoadingPets, pets: _pets, onAdded: _refreshAfterAdd),
                      const SizedBox(height: AppSpacing.s8),
                      SectionTitle(l10n.account),
                      const SizedBox(height: AppSpacing.s3),
                      _SettingsGroup(onProfileChanged: () => setState(() {})),
                      const SizedBox(height: AppSpacing.s8),
                      _LogoutButton(),
                    ],
                  ),
                ),
              ),
            ],
          );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: GradientAppBar(title: l10n.profileTitle),
      body: SafeArea(child: content),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AuthState auth;
  final bool isLoadingPets;
  final int petsCount;
  const _ProfileHero({required this.auth, required this.isLoadingPets, required this.petsCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SectionHero(
      title: auth.displayName ?? 'Pet Owner',
      subtitle: auth.email ?? '',
      titleBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 11, color: AppColors.gold),
            const SizedBox(width: 3),
            Text(l10n.member, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
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
          child: const Icon(Icons.person, color: Colors.white, size: 26),
        ),
      ),
      chips: [
        HeroChip(icon: Icons.pets, value: isLoadingPets ? '—' : '$petsCount', label: l10n.pets),
        // Real "member since" isn't returned by /api/ProfileEndpoint/GetUserInfo
        // (no ProfileCreationDate on that DTO) — stays a placeholder for now.
        HeroChip(icon: Icons.calendar_month_outlined, value: '—', label: l10n.memberSince),
      ],
    );
  }
}

class _PetsRow extends StatelessWidget {
  final bool isLoading;
  final List<Pet> pets;
  final VoidCallback onAdded;
  const _PetsRow({required this.isLoading, required this.pets, required this.onAdded});

  static const _palette = [AppColors.primary, AppColors.accent, AppColors.gold, AppColors.info, AppColors.secondary];
  Color _colorFor(int i) => _palette[i % _palette.length];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const SizedBox(
        height: 130,
        child: Center(child: PawLoader(size: 26, color: AppColors.primary)),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...pets.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value;
            final color = _colorFor(index);
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s3),
              child: HoverCard(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () async {
                  final deleted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => PetDetailScreen(pet: p)),
                  );
                  if (deleted == true) onAdded();
                },
                child: Container(
                  width: 106,
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: p.isFavourite ? AppColors.gold.withValues(alpha: 0.55) : AppColors.borderLight, width: p.isFavourite ? 1.5 : 1),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.pets, color: Colors.white, size: 20),
                          ),
                          if (p.isFavourite)
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                                child: const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      const SizedBox(height: 3),
                      if (p.species.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
                          child: Text(p.species, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                        )
                      else
                        Text(petAgeLabel(context, p), style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            );
          }),
          HoverCard(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddPetScreen()),
              );
              if (added == true) onAdded();
            },
            child: Container(
              width: 106,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 36,
                      width: 36,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.addPet, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  /// Called after the person saves a profile edit, so the header above
  /// can refresh with the new name.
  final VoidCallback onProfileChanged;

  const _SettingsGroup({required this.onProfileChanged});

  /// Both "personal info" and "password & security" open the same edit
  /// screen — it is one form with a personal section and a security
  /// section, and splitting it into two screens would mean two saves.
  Future<void> _openEditProfile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );

    if (saved != true || !context.mounted) return;
    onProfileChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.profileUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = <(IconData, String, Color, VoidCallback)>[
      (Icons.person_outline, l10n.personalInfo, AppColors.primary, () => _openEditProfile(context)),
      (Icons.lock_outline, l10n.passwordSecurity, AppColors.info, () => _openEditProfile(context)),
      (
        Icons.notifications_outlined,
        l10n.notifications,
        AppColors.gold,
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
      ),
      (Icons.translate_rounded, l10n.language, AppColors.accent, () => showLanguagePicker(context)),
      (Icons.contrast_rounded, l10n.appearance, AppColors.ink, () => showThemePicker(context)),
      // Was a row that did nothing when tapped. It now opens the one
      // screen that can answer "which version is this and what went
      // wrong" without anyone having to ask.
      (
        Icons.help_outline,
        l10n.helpSupport,
        AppColors.secondary,
        () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
            ),
      ),
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
          for (int i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].$4,
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(AppRadius.xl) : Radius.zero,
                bottom: i == items.length - 1 ? const Radius.circular(AppRadius.xl) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
                child: Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [items[i].$3, items[i].$3.withValues(alpha: 0.7)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: items[i].$3.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(items[i].$1, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(items[i].$2, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text))),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.bgMuted, shape: BoxShape.circle),
                      child: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 15),
                    ),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1) const Divider(height: 1, indent: 60, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return HoverCard(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: () => _confirmLogout(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, size: 15, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l10n.logOut, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.danger)),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right, color: AppColors.danger, size: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showPremiumConfirmDialog(
      context,
      icon: Icons.logout_rounded,
      accentColor: AppColors.danger,
      title: l10n.logOutConfirmTitle,
      message: l10n.logOutConfirmMessage,
      confirmLabel: l10n.logOut,
      cancelLabel: l10n.stayLoggedIn,
      isDangerous: true,
    );
    if (confirmed && context.mounted) {
      // Local state clears immediately; the server-side token invalidation
      // runs inside logOut() and never blocks the UI.
      await AuthScope.of(context).logOut();
    }
  }
}
