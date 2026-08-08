// Mirrors frontend/src/app/pages/home-page/VetStation.ts, extended with
// marketplace fields (rating, city, verified) used by the Explore screen.
// These extra fields aren't in the current backend DTO yet — treat them
// as the shape to add server-side once the search endpoint grows filters.

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

  // ─── Marketplace / discovery fields ────────────────────
  final String city;
  final double rating; // 0.0 - 5.0
  final int reviewCount;
  final bool verifiedPartner;
  final double distanceKm;
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
    this.rating = 0.0,
    this.reviewCount = 0,
    this.verifiedPartner = false,
    this.distanceKm = 0.0,
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
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      verifiedPartner: json['verifiedPartner'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      openNow: json['openNow'] as bool? ?? true,
    );
  }
}
