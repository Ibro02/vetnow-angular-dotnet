/// One review of a clinic, as returned by /api/Review/GetByVetStation.
///
/// [authorName] arrives already shortened by the server ("Amir H.") — the
/// full identity of a reviewer is not something a public feed needs.
class Review {
  final int id;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  const Review({
    this.id = 0,
    required this.authorName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int? ?? 0,
      authorName: (json['authorName'] as String? ?? '').trim(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: _parseUtc(json['createdAt']),
    );
  }

  /// The API stores review timestamps in UTC but serialises them without a
  /// zone suffix, so a plain parse would read them as local time and date a
  /// review an hour or two off. Add the marker when it's missing.
  static DateTime? _parseUtc(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
    return DateTime.tryParse(hasZone ? value : '${value}Z')?.toLocal();
  }
}

/// The aggregate shown above the list: the score, the number behind it, and
/// how the stars are spread.
class ReviewSummary {
  final double averageRating;
  final int reviewCount;

  /// Star value (1–5) to how many reviews gave it.
  final Map<int, int> ratingCounts;

  final List<Review> reviews;

  const ReviewSummary({
    this.averageRating = 0,
    this.reviewCount = 0,
    this.ratingCounts = const {},
    this.reviews = const [],
  });

  bool get hasReviews => reviewCount > 0;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['ratingCounts'] as Map<String, dynamic>? ?? const {};
    return ReviewSummary(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      ratingCounts: {
        for (final entry in raw.entries)
          if (int.tryParse(entry.key) != null) int.parse(entry.key): (entry.value as num?)?.toInt() ?? 0,
      },
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A past visit this person can still rate — the backend's "pending" list.
class PendingReview {
  final int appointmentId;
  final int vetStationId;
  final String vetStationName;
  final DateTime? visitDate;
  final String? animalName;

  const PendingReview({
    required this.appointmentId,
    required this.vetStationId,
    required this.vetStationName,
    this.visitDate,
    this.animalName,
  });

  factory PendingReview.fromJson(Map<String, dynamic> json) {
    return PendingReview(
      appointmentId: json['appointmentId'] as int? ?? 0,
      vetStationId: json['vetStationId'] as int? ?? 0,
      vetStationName: json['vetStationName'] as String? ?? '',
      visitDate: DateTime.tryParse('${json['visitDate']}'),
      animalName: json['animalName'] as String?,
    );
  }
}
