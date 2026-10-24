import 'dart:convert';

/// FNV-1a 64-bit hash, used only to detect re-importing the same source
/// (not for security).
String contentHash(List<int> bytes) {
  var hash = 0xcbf29ce484222325;
  for (final b in bytes) {
    hash ^= b;
    hash *= 0x100000001b3; // wraps at 64 bits on the Dart VM
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

/// Same text regardless of spacing and letter case.
String textHash(String text) =>
    contentHash(utf8.encode(text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ')));
