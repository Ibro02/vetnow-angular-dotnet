// Mirrors VetStat/Models/Animal.cs where possible.
//
// NOTE — backend gap: the current Animal table has no weight or
// microchip columns. This model includes them anyway so the mobile UI
// is ready; treat weightKg/microchipNumber as app-only fields until
// they're added to the Animal table + AnimalDto on the backend.

class Pet {
  final int id;
  final String name;
  final String species; // Species.Name
  final String breed; // Breed.Name
  final DateTime? birthDate;
  final double? weightKg; // not in backend Animal model yet
  final String? microchipNumber; // not in backend Animal model yet

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    this.birthDate,
    this.weightKg,
    this.microchipNumber,
  });

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
