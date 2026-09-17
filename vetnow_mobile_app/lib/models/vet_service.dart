enum ServiceKind { vaccination, checkup, dental, grooming }

class VetService {
  final String name;
  final String description;
  final double priceKm;
  final int durationMinutes;
  final ServiceKind? kind;

  const VetService({
    required this.name,
    required this.description,
    required this.priceKm,
    required this.durationMinutes,
    this.kind,
  });
}
