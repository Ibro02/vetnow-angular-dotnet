import 'package:flutter/material.dart';

import '../config/haptics.dart';
import '../config/theme.dart';
import '../models/pet.dart';
import 'pet_avatar.dart';
import 'pet_search_sheet.dart';
import 'pet_search_tile.dart';

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

  /// Every pet, regardless of the filter — what the search sheet
  /// opens onto. Null hides the search tile, which is what happens
  /// below a handful of animals: a row that fits on screen does not
  /// need searching.
  final List<Pet>? searchable;

  const PetStrip({
    super.key,
    required this.pets,
    required this.selectedPetId,
    required this.onSelect,
    required this.emptyMessage,
    this.searchable,
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
          // The search leads the row rather than trailing it.
          //
          // At the tail it was past the right-hand edge behind five
          // portraits, so the one control that exists for people with
          // too many pets was the one thing they had to scroll to find.
          // At the head it is always the first thing under the thumb,
          // and the row reads as "all of them, then these".
          //
          // It is a circle among the portraits either way, not a form
          // field above them asking to be filled in before you may
          // carry on.
          itemCount: pets.length + (searchable == null ? 0 : 1),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            if (searchable != null && i == 0) {
              return PetSearchTile(
                onTap: () async {
                  Haptics.select();
                  final picked =
                      await showPetSearchSheet(context, pets: searchable!);
                  if (picked != null) onSelect(picked);
                },
              );
            }

            final pet = pets[searchable == null ? i : i - 1];
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
                    child: PetAvatar(
                      species: pet.species,
                      seed: pet.id,
                      size: 54,
                      name: pet.name,
                      photoBase64: pet.photoBase64,
                    ),
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

