// Mirrors the VetStationSearch response DTO.
//
// `city`, `country`, `address`, `email` and `description` all live on the
// backend entity and are now returned by the search projection, so the city
// picker and the address line below it are backed by real data rather than
// being decorative.
//
// `verifiedPartner` and `openNow` are the two the backend does not send yet.
// They default to values that render nothing, so a clinic looks correct either
// way and starts showing the badge the day the API grows the field.
//
// `distanceKm` used to live here too and was removed: with no geocoding on the
// server it was 0.0 for every clinic, which the card rendered as a literal
// "0.0 km" and the sort silently ordered by.

class VetStation {
  final int id;
  final String name;
  final String stationImage;
  final String contactNumber;
  final bool inOffice;
  final bool onField;
  final bool parking;
  final bool wheelchair;
  final bool wifi;

  // ─── Location (real, from the backend) ─────────────────
  final String city;
  final String country;
  final String address;
  final String email;
  final String description;

  /// Street and city on one line, skipping whichever half is missing —
  /// used wherever a clinic needs a human-readable location.
  String get locationLine {
    final parts = [address, city].where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }

  // ─── Ratings (real, aggregated from the Review table) ──
  /// Mean of every review for this clinic. 0 when it has none — check
  /// [hasReviews] before showing it, or a brand-new clinic reads as a
  /// one-star disaster.
  final double rating;
  final int reviewCount;

  bool get hasReviews => reviewCount > 0;

  // ─── Not yet backed by the API ─────────────────────────
  final bool verifiedPartner;
  final bool openNow;

  const VetStation({
    required this.id,
    required this.name,
    required this.stationImage,
    required this.contactNumber,
    required this.inOffice,
    required this.onField,
    required this.parking,
    required this.wheelchair,
    required this.wifi,
    this.city = '',
    this.country = '',
    this.address = '',
    this.email = '',
    this.description = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.verifiedPartner = false,
    this.openNow = true,
  });

  factory VetStation.fromJson(Map<String, dynamic> json) {
    return VetStation(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      stationImage: json['stationImage'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      inOffice: json['inOffice'] as bool? ?? false,
      onField: json['onField'] as bool? ?? false,
      parking: json['parking'] as bool? ?? false,
      wheelchair: json['wheelchair'] as bool? ?? false,
      wifi: json['wifi'] as bool? ?? false,
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      description: json['description'] as String? ?? '',
      // The search endpoint aggregates these per clinic; 'rating' is the
      // older spelling and is kept so a stale response still parses.
      rating: (json['averageRating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      verifiedPartner: json['verifiedPartner'] as bool? ?? false,
      openNow: json['openNow'] as bool? ?? true,
    );
  }
}
