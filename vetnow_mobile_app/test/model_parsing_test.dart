// Parsing tests for the two models that read straight from the API.
//
// These are the seams where a backend change turns into a wrong number on
// screen rather than a crash, so they are worth pinning down: a rating that
// silently falls back to 0.0, or a review dated an hour into the future,
// would both look like working software.

import 'package:flutter_test/flutter_test.dart';

import 'package:vetnow_mobile/models/review.dart';
import 'package:vetnow_mobile/models/vet_station.dart';

void main() {
  group('VetStation.fromJson', () {
    // Exactly what GET /api/VetStationSearch returns for one clinic.
    Map<String, dynamic> station({Object? averageRating = 4.6, int reviewCount = 7}) => {
          'id': 1,
          'name': 'Happy Paws Vet Clinic',
          'contactNumber': '+387 33 123 456',
          'city': 'Sarajevo',
          'country': 'Bosnia and Herzegovina',
          'address': 'Ferhadija 15',
          'email': 'info@happypaws.ba',
          'description': 'Full-service veterinary clinic.',
          'stationImage': null,
          'averageRating': averageRating,
          'reviewCount': reviewCount,
          'inOffice': true,
          'onField': true,
          'parking': true,
          'wheelchair': true,
          'wifi': true,
        };

    test('reads the aggregated rating the search endpoint sends', () {
      final s = VetStation.fromJson(station());
      expect(s.rating, 4.6);
      expect(s.reviewCount, 7);
      expect(s.hasReviews, isTrue);
    });

    test('an integer average parses as a double', () {
      // JSON has no double/int distinction, so a clean 4.0 arrives as `4`.
      final s = VetStation.fromJson(station(averageRating: 4));
      expect(s.rating, 4.0);
    });

    test('a clinic with no reviews is not a zero-star clinic', () {
      final s = VetStation.fromJson(station(averageRating: 0, reviewCount: 0));
      expect(s.hasReviews, isFalse);
    });

    test('location line joins street and city, and skips a missing half', () {
      expect(VetStation.fromJson(station()).locationLine, 'Ferhadija 15, Sarajevo');

      final noAddress = station()..['address'] = '';
      expect(VetStation.fromJson(noAddress).locationLine, 'Sarajevo');

      final nowhere = station()
        ..['address'] = ''
        ..['city'] = '';
      expect(VetStation.fromJson(nowhere).locationLine, '');
    });

    test('missing optional fields fall back instead of throwing', () {
      final s = VetStation.fromJson({'id': 3, 'name': 'Bare'});
      expect(s.city, '');
      expect(s.rating, 0.0);
      expect(s.reviewCount, 0);
      expect(s.parking, isFalse);
    });
  });

  group('ReviewSummary.fromJson', () {
    final payload = {
      'vetStationId': 1,
      'averageRating': 4.6,
      'reviewCount': 7,
      'ratingCounts': {'1': 0, '2': 0, '3': 1, '4': 1, '5': 5},
      'reviews': [
        {
          'id': 9,
          'rating': 5,
          'comment': 'Ljubazno osoblje.',
          'createdAt': '2026-09-14T12:30:00',
          'authorName': 'User U.',
        },
      ],
    };

    test('maps the star histogram to int keys', () {
      final summary = ReviewSummary.fromJson(payload);
      expect(summary.ratingCounts[5], 5);
      expect(summary.ratingCounts[3], 1);
      expect(summary.ratingCounts[1], 0);
      expect(summary.averageRating, 4.6);
      expect(summary.hasReviews, isTrue);
    });

    test('an empty feed reports no reviews rather than a zero score', () {
      final summary = ReviewSummary.fromJson({
        'vetStationId': 3,
        'averageRating': 0,
        'reviewCount': 0,
        'ratingCounts': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        'reviews': <dynamic>[],
      });
      expect(summary.hasReviews, isFalse);
      expect(summary.reviews, isEmpty);
    });

    test('a timestamp with no zone suffix is read as UTC, not local time', () {
      final review = ReviewSummary.fromJson(payload).reviews.single;
      final created = review.createdAt!;

      // The instant must match the UTC the server meant. Comparing in UTC
      // keeps this passing on a machine in any timezone — which is the whole
      // point of the parse being explicit about the zone.
      expect(created.toUtc(), DateTime.utc(2026, 9, 14, 12, 30));
      expect(created.isUtc, isFalse, reason: 'surfaced to the UI in local time');
    });

    test('a timestamp that already carries a zone is not shifted twice', () {
      final review = Review.fromJson({
        'id': 1,
        'rating': 4,
        'comment': '',
        'createdAt': '2026-09-14T12:30:00Z',
        'authorName': 'A B.',
      });
      expect(review.createdAt!.toUtc(), DateTime.utc(2026, 9, 14, 12, 30));
    });

    test('a review with no timestamp parses rather than throwing', () {
      final review = Review.fromJson({'id': 2, 'rating': 3, 'authorName': 'C D.'});
      expect(review.createdAt, isNull);
      expect(review.comment, '');
      expect(review.rating, 3.0);
    });
  });

  group('PendingReview.fromJson', () {
    test('carries the visit a person can still rate', () {
      final pending = PendingReview.fromJson({
        'appointmentId': 9,
        'vetStationId': 1,
        'vetStationName': 'Happy Paws Vet Clinic',
        'visitDate': '2026-09-14T08:30:00',
        'animalName': 'Shadow',
      });

      expect(pending.appointmentId, 9);
      expect(pending.vetStationId, 1);
      expect(pending.animalName, 'Shadow');
      expect(pending.visitDate, DateTime(2026, 9, 14, 8, 30));
    });
  });
}
