// Mirrors VetStat/Models/Animal.cs where possible.
//
// NOTE — backend gap: the current Animal table has no weight or
// microchip columns. This model includes them anyway so the mobile UI
// is ready; treat weightKg/microchipNumber as app-only fields until
// they're added to the Animal table + AnimalDto on the backend.
// isFavourite IS a real Animal column though (Animal.IsFavourite),
// wired to PetsUpdateOrInsert/Save like everything else here.

class Pet {
  final int id;
  final String name;
  final String species; // Species.Name (display only — see speciesId)
  final int? speciesId; // AnimalSpeciesId, needed to re-save this pet
  final String breed; // Breed.Name
  final DateTime? birthDate;
  final double? weightKg; // not in backend Animal model yet
  final String? microchipNumber; // not in backend Animal model yet
  final bool isFavourite;

  /// The pet's photo, base64, exactly as the backend sends it.
  ///
  /// Animal.Picture has been on the entity all along and the response
  /// has always carried it — the app simply never read the field, and
  /// drew a species silhouette instead. Four dogs therefore looked
  /// like four copies of the same picture, because that is what they
  /// were.
  ///
  /// Kept as the raw string rather than decoded bytes: most pets have
  /// no photo, and decoding one on the off chance is work for nothing.
  final String? photoBase64;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.speciesId,
    required this.breed,
    this.birthDate,
    this.weightKg,
    this.microchipNumber,
    this.isFavourite = false,
    this.photoBase64,
  });

  Pet copyWith({bool? isFavourite}) => Pet(
        id: id,
        name: name,
        species: species,
        speciesId: speciesId,
        breed: breed,
        birthDate: birthDate,
        weightKg: weightKg,
        microchipNumber: microchipNumber,
        isFavourite: isFavourite ?? this.isFavourite,
      );

  /// Completed years, or null when there is no birth date — and null for
  /// a pet under one, where months are the useful unit.
  int? ageInYears([DateTime? asOf]) {
    if (birthDate == null) return null;
    final now = asOf ?? DateTime.now();
    var years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years < 1 ? null : years;
  }

  /// Whole months, used only while a pet is under a year old — "8 months"
  /// says something about a puppy that "0 years" does not.
  int? ageInMonths([DateTime? asOf]) {
    if (birthDate == null || ageInYears(asOf) != null) return null;
    final now = asOf ?? DateTime.now();
    var months = (now.year - birthDate!.year) * 12 + now.month - birthDate!.month;
    if (now.day < birthDate!.day) months--;
    return months < 0 ? 0 : months;
  }

  // ─── Birthdays ───────────────────────────────────────────────────────
  //
  // Every pet in the database has a birth date and nothing ever used it
  // beyond an untranslated "7 yr". A vet app that knows when your dog was
  // born and never mentions it is leaving the nicest thing it knows on
  // the floor.

  /// The next time this pet's birthday comes round, from [asOf].
  /// Today counts as the birthday, not as one already missed.
  DateTime? nextBirthday([DateTime? asOf]) {
    if (birthDate == null) return null;
    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // A 29 February birthday falls back to the 28th in common years,
    // rather than silently rolling into March.
    DateTime on(int year) {
      final lastDay = DateTime(year, birthDate!.month + 1, 0).day;
      return DateTime(year, birthDate!.month, birthDate!.day.clamp(1, lastDay));
    }

    final thisYear = on(today.year);
    return thisYear.isBefore(today) ? on(today.year + 1) : thisYear;
  }

  /// Days until the next birthday; 0 means it is today.
  int? daysUntilBirthday([DateTime? asOf]) {
    final next = nextBirthday(asOf);
    if (next == null) return null;
    final now = asOf ?? DateTime.now();
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool isBirthdayToday([DateTime? asOf]) => daysUntilBirthday(asOf) == 0;

  /// The age this pet reaches on its next birthday.
  int? turningAge([DateTime? asOf]) {
    final next = nextBirthday(asOf);
    if (next == null || birthDate == null) return null;
    return next.year - birthDate!.year;
  }

  /// Whether the birthday is close enough to be worth mentioning.
  /// Two weeks: far enough to be useful, near enough not to be noise.
  bool birthdayIsNear([DateTime? asOf]) {
    final days = daysUntilBirthday(asOf);
    return days != null && days <= 14;
  }
}

class VaccinationRecord {
  final String name;
  final DateTime date;
  final String clinic;

  const VaccinationRecord({
    required this.name,
    required this.date,
    required this.clinic,
  });
}
