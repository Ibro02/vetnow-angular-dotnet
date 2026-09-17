import 'dart:convert';
import 'dart:typed_data';

/// Turns whatever the backend put in a picture column into bytes.
///
/// Both Person.Picture and Animal.Picture are `byte[]` on the entity and
/// base64 on the wire, and both have been travelling in responses the
/// app already makes while the app drew generated portraits instead.
///
/// Null rather than an exception on anything unusable. These columns
/// have been written to by more than one version of an admin panel, and
/// a list of pets is the wrong place to find out that one row is
/// malformed: the avatar falls back to its monogram and the screen
/// carries on.
Uint8List? decodePhoto(String? raw) {
  if (raw == null) return null;

  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  try {
    // Some rows hold a whole data: URI rather than the payload alone.
    final comma = trimmed.indexOf(',');
    final payload =
        trimmed.startsWith('data:') && comma > 0 ? trimmed.substring(comma + 1) : trimmed;

    final bytes = base64Decode(payload);
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}
