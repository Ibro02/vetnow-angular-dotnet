import 'dart:typed_data';

import '../config/api_config.dart';
import 'api_client.dart';

/// The medical record the backend already knows how to print.
///
/// `api/PetsReport/Generate` builds a PDF of every pet an owner has —
/// name, species, breed — with QuestPDF, and has done since before the
/// mobile app existed. Nothing called it. Somebody moving clinics, or
/// asked for their animal's details at a counter, had no way to get them
/// out of the app at all.
///
/// Returns the file's bytes. Saving or sending them is the caller's
/// business: on a phone that means handing them to the system share
/// sheet, which avoids asking for storage permission to write a file
/// most people will forward and then forget.
class PetsReportApiService {
  PetsReportApiService._();

  /// GET /api/PetsReport/Generate?ownerId= — [Authorize].
  ///
  /// The backend refuses an ownerId that is not the caller's unless they
  /// are staff, so there is nothing to check here that it does not
  /// already check better.
  static Future<Uint8List> forOwner({
    required int ownerId,
    required String token,
  }) {
    return ApiClient.getBytes(
      ApiConfig.petsReport,
      query: {'ownerId': ownerId},
      token: token,
    );
  }
}
