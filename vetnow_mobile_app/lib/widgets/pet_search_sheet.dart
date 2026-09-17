import 'package:flutter/material.dart';

import '../config/haptics.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';
import 'pet_avatar.dart';

/// Every pet, searchable, in a sheet.
///
/// The search used to be a text field parked above the row, on a screen
/// that is already four questions long: a box asking to be filled in
/// before you were allowed to carry on, when almost nobody needs it.
/// Behind a tile it costs nothing until it is wanted, and once it is
/// wanted it gets a whole sheet rather than one cramped line.
///
/// Returns the chosen pet's id, or null if it was dismissed.
Future<int?> showPetSearchSheet(
  BuildContext context, {
  required List<Pet> pets,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PetSearchSheet(pets: pets),
  );
}

class _PetSearchSheet extends StatefulWidget {
  final List<Pet> pets;

  const _PetSearchSheet({required this.pets});

  @override
  State<_PetSearchSheet> createState() => _PetSearchSheetState();
}

class _PetSearchSheetState extends State<_PetSearchSheet> {
  final _query = TextEditingController();
  bool _favouritesOnly = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Pet> get _matching {
    final q = _query.text.trim().toLowerCase();
    final found = widget.pets.where((p) {
      if (_favouritesOnly && !p.isFavourite) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.species.toLowerCase().contains(q) ||
          p.breed.toLowerCase().contains(q);
    }).toList();

    found.sort((a, b) {
      if (a.isFavourite != b.isFavourite) return a.isFavourite ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matching = _matching;
    final hasFavourites = widget.pets.any((p) => p.isFavourite);

    return Padding(
      // So the sheet rides above the keyboard rather than under it.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.s3),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                l10n.choosePet,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 20,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgMuted,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: TextField(
                        controller: _query,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 14.5, color: AppColors.text),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.searchPetsHint,
                          hintStyle:
                              TextStyle(color: AppColors.textMuted, fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 19, color: AppColors.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  if (hasFavourites) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      selected: _favouritesOnly,
                      label: l10n.favourites,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () {
                          Haptics.select();
                          setState(() => _favouritesOnly = !_favouritesOnly);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: _favouritesOnly
                                ? AppColors.goldSoft
                                : AppColors.bgMuted,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _favouritesOnly
                                  ? AppColors.gold
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            _favouritesOnly
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 21,
                            color: _favouritesOnly
                                ? AppColors.gold
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Flexible(
                child: matching.isEmpty
                    ? Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.s6),
                        child: Text(
                          l10n.noPetsMatchFilter,
                          style: TextStyle(
                              fontSize: 13.5, color: AppColors.textSecondary),
                        ),
                      )
                    // Material, because a ListTile paints its ink on the
                    // nearest Material ancestor and the sheet's own
                    // coloured Container sits in between -- which makes
                    // every tap splash invisible, and which Flutter
                    // asserts about rather than letting it slide.
                    : Material(
                        type: MaterialType.transparency,
                        child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: matching.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: AppColors.borderLight),
                        itemBuilder: (context, i) {
                          final pet = matching[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: PetAvatar(
                              species: pet.species,
                              seed: pet.id,
                              size: 42,
                              name: pet.name,
                              photoBase64: pet.photoBase64,
                            ),
                            title: Text(
                              pet.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.text,
                              ),
                            ),
                            subtitle: pet.species.isEmpty
                                ? null
                                : Text(
                                    pet.species,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary),
                                  ),
                            trailing: pet.isFavourite
                                ? const Icon(Icons.star_rounded,
                                    size: 18, color: AppColors.gold)
                                : null,
                            onTap: () => Navigator.of(context).pop(pet.id),
                          );
                        },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
