// IO implementation used for mobile/desktop
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

Future<void> triggerDownload(String filename, Uint8List bytes) async {
  try {
    // Prefer public Downloads on Android if available and permitted
    if (Platform.isAndroid) {
      final candidates = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
      ];
      Directory? downloadsDir;
      for (final p in candidates) {
        final d = Directory(p);
        if (await d.exists()) {
          downloadsDir = d;
          break;
        }
      }

      if (downloadsDir != null) {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final file = File('${downloadsDir.path}/$filename');
          await file.writeAsBytes(bytes, flush: true);
          print('✅ Saved file: ${file.path}');
          try {
            await OpenFilex.open(file.path);
          } catch (openErr) {
            print('⚠️ Failed to open file (plugin not registered?): $openErr');
          }
          return;
        } else {
          print('⚠️ Storage permission denied, falling back to app dir');
        }
      } else {
        print('⚠️ Downloads dir not found, falling back to app dir');
      }
    }

    // Desktop platforms: use Downloads if available
    Directory? targetDir;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      targetDir = await getDownloadsDirectory();
      targetDir ??= await getApplicationDocumentsDirectory();
    } else {
      // iOS or Android fallback: app documents directory
      targetDir = await getApplicationDocumentsDirectory();
    }

    final file = File('${targetDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    print('✅ Saved file: ${file.path}');
    try {
      await OpenFilex.open(file.path);
    } catch (openErr) {
      print('⚠️ Failed to open file (plugin not registered?): $openErr');
    }
  } catch (e) {
    // Swallow to avoid crashing; the controller should handle snackbar errors.
    print('⚠️ Failed to save file: $e');
  }
}