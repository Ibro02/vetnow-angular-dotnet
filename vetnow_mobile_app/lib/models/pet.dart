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

  String get ageLabel {
    if (birthDate == null) return 'Age unknown';
    final now = DateTime.now();
    var years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    if (years < 1) {
      final months = (now.difference(birthDate!).inDays / 30).floor();
      return '$months mo';
    }
    return '$years yr';
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
