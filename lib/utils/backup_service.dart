// lib/utils/backup_service.dart
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'database_service.dart';

class BackupService {
  static Future<String?> createBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final encoder = ZipFileEncoder();
      final backupPath = p.join(
          dir.path,
          'jeweltrack_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
      encoder.create(backupPath);

      // Add isar DB file
      final isarPath = p.join(dir.path, 'default.isar');
      if (File(isarPath).existsSync()) {
        encoder.addFile(File(isarPath), 'default.isar');
      }
      // isar lock file
      final isarLockPath = p.join(dir.path, 'default.isar.lock');
      if (File(isarLockPath).existsSync()) {
        encoder.addFile(File(isarLockPath), 'default.isar.lock');
      }

      // ✅ FIX: folder name matches ImageService ('jeweltrack_images' not 'job_images')
      final imgDir = Directory(p.join(dir.path, 'jeweltrack_images'));
      if (imgDir.existsSync()) {
        encoder.addDirectory(imgDir, includeDirName: true);
      }

      encoder.close();
      return backupPath;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> shareBackup() async {
    final path = await createBackup();
    if (path == null) return false;
    await Share.shareXFiles([XFile(path)],
        text:
            'JewelTrack Backup - ${DateTime.now().toString().substring(0, 10)}');
    return true;
  }

  static Future<RestoreResult> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.isEmpty) {
        return RestoreResult.cancelled;
      }

      final zipPath = result.files.first.path!;
      final dir = await getApplicationDocumentsDirectory();

      // Close isar before overwriting
      await DatabaseService.isar.close();

      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final outPath = p.join(dir.path, file.name);
        if (file.isFile) {
          final outFile = File(outPath);
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(outPath).createSync(recursive: true);
        }
      }

      // ✅ FIX: After restore, rebase all image paths to the current app documents dir.
      // Paths stored in DB may contain a different device's absolute prefix.
      await DatabaseService.init();
      await _rebaseImagePaths(dir.path);

      return RestoreResult.success;
    } catch (e) {
      try {
        await DatabaseService.init();
      } catch (_) {}
      return RestoreResult.failed;
    }
  }

  /// Rewrites imagePath fields in all Jobs so they point to the current
  /// device's documents directory instead of the backed-up device's path.
  static Future<void> _rebaseImagePaths(String currentDocDir) async {
    try {
      final isar = DatabaseService.isar;
      // We use raw Isar access to avoid importing Job here — but since
      // database_service already imports Job, we delegate via DatabaseService.
      await DatabaseService.rebaseImagePaths(currentDocDir);
    } catch (_) {}
  }
}

enum RestoreResult { success, failed, cancelled }
