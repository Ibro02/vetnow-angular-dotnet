import 'package:flutter/material.dart';

import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import 'pet_avatar.dart';

/// Choosing which animal the appointment is for.
///
/// This was a vertical list of cards, one per pet, in whatever order the
/// database returned them. Someone with nine animals scrolled past eight
/// of them to reach the one they came for, having already scrolled past
/// the service, the staff, the calendar and the times. The screen asks
/// four questions and the last one was the longest.
///
/// It is a single row now. A row of portraits fits five without moving
/// and the rest are one flick away, which is the difference between
/// picking a pet and hunting for one.
///
/// Sorting carries the rest of the weight: favourites first, then
/// alphabetical. A pet marked favourite is, in practice, the pet being
/// booked for — so the answer is usually the first thing in the row and
/// nobody has to look for it at all.
class PetStrip extends StatelessWidget {
  final List<Pet> pets;
  final int? selectedPetId;
  final ValueChanged<int> onSelect;

  /// Shown only when the filter has emptied the row, so the gap says
  /// something rather than looking like the pets have been lost.
  final String emptyMessage;

  const PetStrip({
    super.key,
    required this.pets,
    required this.selectedPetId,
    required this.onSelect,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, size: 17, color: AppColors.textMuted),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                emptyMessage,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // The row grows with the system text size, but only so far: past
    // about a third again the portraits start pushing the times off the
    // screen, and a portrait is not what anybody turned the text up to
    // read.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);

    return SizedBox(
      height: 104 * scale,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: pets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final pet = pets[i];
            return _PetTile(
              pet: pet,
              selected: selectedPetId == pet.id,
              onTap: () {
                Haptics.select();
                onSelect(pet.id);
              },
            );
          },
        ),
      ),
    );
  }
}

class _PetTile extends StatelessWidget {
  final Pet pet;
  final bool selected;
  final VoidCallback onTap;

  const _PetTile({required this.pet, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: pet.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          width: 74,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // A ring rather than a border on the portrait itself:
                  // the padding between the two is what makes the
                  // selected one read as lifted off the row instead of
                  // merely outlined.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.32),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: PetAvatar(species: pet.species, seed: pet.id, size: 54),
                  ),
                  if (pet.isFavourite)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: const Icon(Icons.star_rounded,
                            size: 12, color: AppColors.gold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.text : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The search field and the favourites toggle that sit above the row.
///
/// Both earn their place only once there are enough animals for the row
/// to need flicking. Below that they are two controls asking to be used
/// on a problem nobody has.
class PetFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool favouritesOnly;
  final ValueChanged<bool> onFavouritesChanged;
  final bool hasFavourites;

  const PetFilterBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.favouritesOnly,
    required this.onFavouritesChanged,
    required this.hasFavourites,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgMuted,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: AppColors.text),
              // The same manners as the clinic search on Explore: a key
              // that puts the keyboard away, and no autocorrect, because
              // a cat called Mica is not a dictionary word.
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.searchPetsHint,
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                prefixIcon:
                    Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 17, color: AppColors.textMuted),
                        tooltip: l10n.clearSearch,
                        onPressed: () {
                          controller.clear();
                          FocusScope.of(context).unfocus();
                          onChanged('');
                        },
                      ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        if (hasFavourites) ...[
          const SizedBox(width: 8),
          Semantics(
            button: true,
            selected: favouritesOnly,
            label: l10n.favourites,
            excludeSemantics: true,
            child: InkWell(
              onTap: () {
                Haptics.select();
                onFavouritesChanged(!favouritesOnly);
              },
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: favouritesOnly ? AppColors.goldSoft : AppColors.bgMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: favouritesOnly ? AppColors.gold : AppColors.border,
                  ),
                ),
                child: Icon(
                  favouritesOnly ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 20,
                  color: favouritesOnly ? AppColors.gold : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
