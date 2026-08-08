import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import '../services/api_client.dart';
import '../services/pets_api_service.dart';
import '../services/species_api_service.dart';
import '../state/auth_state.dart';
import '../widgets/auth_prompt.dart';
import '../widgets/hover_card.dart';
import '../widgets/paw_loader.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/section_hero.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/language_picker.dart';
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
                  padding: const EdgeInsets.fromLTRB(AppSpacing.pagePadding, AppSpacing.s6, AppSpacing.pagePadding, AppSpacing.s10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.myPets, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                      Text(l10n.account, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: AppSpacing.s3),
                      const _SettingsGroup(),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const SizedBox(
        height: 118,
        child: Center(child: PawLoader(size: 26, color: AppColors.primary)),
      );
    }

    return SizedBox(
      height: 118,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...pets.map(
            (p) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s3),
              child: HoverCard(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PetDetailScreen(pet: p)),
                ),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.accent, AppColors.primary]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pets, color: Colors.white, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(p.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      Text(
                        p.species.isNotEmpty ? '${p.species} · ${p.ageLabel}' : p.ageLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          HoverCard(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddPetScreen()),
              );
              if (added == true) onAdded();
            },
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    const SizedBox(height: 4),
                    Text(l10n.addPet, style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
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
  const _SettingsGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = <(IconData, String, Color, VoidCallback)>[
      (Icons.person_outline, l10n.personalInfo, AppColors.primary, () {}),
      (Icons.lock_outline, l10n.passwordSecurity, AppColors.info, () {}),
      (Icons.notifications_outlined, l10n.notifications, AppColors.gold, () {}),
      (Icons.translate_rounded, l10n.language, AppColors.accent, () => showLanguagePicker(context)),
      (Icons.help_outline, l10n.helpSupport, AppColors.secondary, () {}),
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
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: items[i].$3.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(items[i].$1, size: 16, color: items[i].$3),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(items[i].$2, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
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
              decoration: const BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, size: 15, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l10n.logOut, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.danger)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
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
      AuthScope.of(context).logOut();
    }
  }
}
