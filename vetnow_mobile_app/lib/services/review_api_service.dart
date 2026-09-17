import '../config/api_config.dart';
import '../models/review.dart';
import 'api_client.dart';

/// Clinic reviews.
///
/// Reading is anonymous, which matters: someone comparing clinics has to be
/// able to read reviews before they have an account. Writing is not — the
/// backend ties every review to one of the author's own past appointments.
class ReviewApiService {
  ReviewApiService._();

  /// GET /api/Review/GetByVetStation?vetStationId= — AllowAnonymous.
  static Future<ReviewSummary> getByVetStation(int vetStationId) async {
    final result = await ApiClient.get(
      ApiConfig.reviewByVetStation,
      query: {'vetStationId': vetStationId},
    );
    return ReviewSummary.fromJson(result as Map<String, dynamic>);
  }

  /// POST /api/Review/Add — [Authorize].
  ///
  /// The server rejects a rating for a visit that isn't this person's, hasn't
  /// happened yet, or has already been rated, so the caller should be ready
  /// to surface an [ApiException] message rather than assume success.
  static Future<void> add({
    required int appointmentId,
    required int rating,
    String? comment,
    required String token,
  }) async {
    await ApiClient.post(
      ApiConfig.reviewAdd,
      token: token,
      body: {
        'appointmentId': appointmentId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
  }

  /// GET /api/Review/Pending — [Authorize]. Past visits still unrated.
  static Future<List<PendingReview>> pending(String token) async {
    final result = await ApiClient.get(ApiConfig.reviewPending, token: token);
    final list = result as List<dynamic>? ?? const [];
    return list.map((e) => PendingReview.fromJson(e as Map<String, dynamic>)).toList();
  }
}
