import 'dart:typed_data';

/// Cross-platform download trigger stub.
/// Replaced at build time by web/io implementations via conditional imports.
Future<void> triggerDownload(String filename, Uint8List bytes) async {
  // Fallback: no-op to avoid crashes on unsupported platforms.
  // Controllers should still show a snackbar for success/failure.
}