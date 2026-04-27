// // lib/utils/image_service.dart
// import 'dart:io';
// import 'dart:isolate';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;
//
// class ImageService {
//   static final _picker = ImagePicker();
//
//   static Future<String?> pickAndCompress({bool fromCamera = false}) async {
//     final XFile? picked = await _picker.pickImage(
//       source: fromCamera ? ImageSource.camera : ImageSource.gallery,
//       imageQuality: 80,
//     );
//     if (picked == null) return null;
//     return await _compressInBackground(picked.path);
//   }
//
//   static Future<String?> _compressInBackground(String inputPath) async {
//     final result = await Isolate.run(() async {
//       final dir = await getApplicationDocumentsDirectory();
//       final imgDir = Directory('${dir.path}/job_images');
//       if (!imgDir.existsSync()) imgDir.createSync(recursive: true);
//
//       final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
//       final outputPath = p.join(imgDir.path, fileName);
//
//       final compressed = await FlutterImageCompress.compressAndGetFile(
//         inputPath,
//         outputPath,
//         quality: 70,
//         minWidth: 800,
//         minHeight: 800,
//       );
//       return compressed?.path;
//     });
//     return result;
//   }
//
//   static Future<void> deleteImage(String? path) async {
//     if (path == null) return;
//     final file = File(path);
//     if (await file.exists()) await file.delete();
//   }
// }

// lib/utils/image_service.dart
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  static final _picker = ImagePicker();

  static Future<String?> pickAndCompress({bool fromCamera = false}) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return null;

    final result = await _compressInBackground(picked.path);

    // 🔥 FINAL SAFETY (VERY IMPORTANT)
    if (result == null) {
      print("Compression failed, using original image");
      return picked.path; // fallback
    }

    return result;
  }

  static Future<String?> _compressInBackground(String inputPath) async {
    try {
      final result = await Isolate.run(() async {
        final dir = await getApplicationDocumentsDirectory();

        // ✅ SAFE APP-SPECIFIC FOLDER
        final imgDir = Directory('${dir.path}/jeweltrack_images');
        if (!imgDir.existsSync()) {
          imgDir.createSync(recursive: true);
        }

        final fileName =
            'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final outputPath = p.join(imgDir.path, fileName);

        final compressed =
        await FlutterImageCompress.compressAndGetFile(
          inputPath,
          outputPath,
          quality: 70,
          minWidth: 800,
          minHeight: 800,
        );

        // 🔥 CRITICAL FIX
        if (compressed == null) {
          return inputPath; // fallback if compression fails
        }

        return compressed.path;
      });

      return result;
    } catch (e) {
      print("Image compression error: $e");

      // 🔥 FINAL FALLBACK
      return inputPath;
    }
  }

  static Future<void> deleteImage(String? path) async {
    if (path == null) return;

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Delete image error: $e");
    }
  }
}