import 'api_config.dart';

/// Who this build is.
///
/// Kept as plain constants rather than reading the package metadata at
/// runtime: that needs a platform plugin, and this is two strings that
/// change once per release. A test asserts they still match pubspec.yaml,
/// so "we forgot to bump it" is caught by the suite rather than by
/// someone reading a crash report from a version that does not exist.
class AppInfo {
  AppInfo._();

  /// Matches `version:` in pubspec.yaml, before the `+`.
  static const String version = '1.0.0';

  /// The part after the `+` — Play's versionCode.
  static const int build = 1;

  static String get fullVersion => '$version ($build)';

  /// The backend this build talks to, host only.
  ///
  /// Host rather than the full URL on purpose: it is enough to tell a
  /// production build from a staging one in a bug report, without putting
  /// internal paths in something a person is about to paste into a chat.
  static String get apiHost =>
      Uri.tryParse(ApiConfig.baseUrl)?.host ?? ApiConfig.baseUrl;

  /// Whether this build could work outside the machine it was made on.
  static bool get pointsAtRealBackend => ApiConfig.isProductionReady;

  /// Where reports of abusive content go.
  ///
  /// Play's content policy requires a way to flag user-generated content,
  /// and reviews are user-generated. This has to be a real, monitored
  /// inbox before the app is submitted — an address nobody reads fails
  /// review just as surely as no address at all.
  static const String supportEmail = 'podrska@vetnow.ba';
}
