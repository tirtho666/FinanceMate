import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Synchronous SHA-256 helper for the App Lock password.
///
/// The hashing runs on the UI isolate (no `compute`/isolate hop) so the App Lock
/// password can be hashed and compared in RAM before any navigation happens.
abstract final class AppLockHasher {
  static String hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  /// Compares [password] against an already computed [hashValue].
  static bool matches({required String password, required String hashValue}) {
    if (hashValue.isEmpty) return false;
    return _constantTimeEquals(hash(password), hashValue);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var index = 0; index < a.length; index++) {
      difference |= a.codeUnitAt(index) ^ b.codeUnitAt(index);
    }
    return difference == 0;
  }
}
