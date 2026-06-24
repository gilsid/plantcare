import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Compress to 80% quality to save space
        maxWidth: 1024, // Max width 1024px to prevent huge file sizes
      );

      if (pickedFile == null) return null;

      // Get app directory to store files persistently
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String plantsImagesDirPath = path.join(appDir.path, 'plant_images');

      // Ensure directory exists
      final Directory plantsImagesDir = Directory(plantsImagesDirPath);
      if (!await plantsImagesDir.exists()) {
        await plantsImagesDir.create(recursive: true);
      }

      // Generate a unique filename using timestamp
      final String extension = path.extension(pickedFile.path);
      final String filename =
          'plant_${DateTime.now().microsecondsSinceEpoch}$extension';
      final String savedPath = path.join(plantsImagesDirPath, filename);

      // Copy the file from temp directory to persistent directory
      final File savedFile = await File(pickedFile.path).copy(savedPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error picking/saving image: $e');
      return null;
    }
  }

  Future<bool> deleteImage(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
    return false;
  }

  Future<void> deleteAllImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String plantsImagesDirPath = path.join(appDir.path, 'plant_images');
      final Directory plantsImagesDir = Directory(plantsImagesDirPath);
      if (await plantsImagesDir.exists()) {
        await plantsImagesDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting all images: $e');
    }
  }
}
