import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/pet.dart';

/// A pet's age, in the reader's language.
///
/// This used to be built in the model as `'$years yr'` — English, and the
/// only untranslated string left on the pets screen. Age is also one of
/// the few places plural rules actually bite here: 1 godina, 2 godine,
/// 5 godina.
String petAgeLabel(BuildContext context, Pet pet) {
  final l10n = AppLocalizations.of(context)!;

  final years = pet.ageInYears();
  if (years != null) return l10n.ageYears(years);

  final months = pet.ageInMonths();
  // Under a year, months say something a rounded-down year cannot.
  if (months != null) return l10n.ageMonths(months);

  return l10n.ageUnknown;
}

/// Shown next to a pet when its birthday is close.
///
/// Deliberately quiet until the day itself: a countdown is a note, a
/// birthday is an occasion, so only the day gets the gold treatment.
class PetBirthdayBadge extends StatelessWidget {
  final Pet pet;

  /// Overridable so tests can stand on a chosen day rather than today.
  final DateTime? asOf;

  const PetBirthdayBadge({super.key, required this.pet, this.asOf});

  @override
  Widget build(BuildContext context) {
    if (!pet.birthdayIsNear(asOf)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final days = pet.daysUntilBirthday(asOf)!;
    final today = days == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: today ? AppGradients.gold : null,
        color: today ? null : AppColors.goldSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cake_rounded,
            size: 11,
            color: today ? Colors.white : AppColors.gold,
          ),
          const SizedBox(width: 4),
          Text(
            today ? l10n.birthdayToday : l10n.birthdayInDays(days),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: today ? Colors.white : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
