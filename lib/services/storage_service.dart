/// Storage Service
///
/// Handles Firebase Storage operations for uploading images and files.
library;

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile image
  ///
  /// [userId] - User's UID
  /// [imageFile] - Image file to upload
  /// Returns download URL of uploaded image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child(AppConstants.profileImagesPath)
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Upload product image
  ///
  /// [productId] - Product ID
  /// [imageFile] - Image file to upload
  /// Returns download URL of uploaded image
  Future<String> uploadProductImage(String productId, File imageFile) async {
    try {
      final String fileName =
          '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child(AppConstants.productImagesPath)
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload product image: ${e.toString()}');
    }
  }

  /// Upload multiple product images
  ///
  /// Returns list of download URLs
  Future<List<String>> uploadProductImages(
    String productId,
    List<File> imageFiles,
  ) async {
    try {
      final List<String> downloadUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final String fileName =
            '${productId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = _storage
            .ref()
            .child(AppConstants.productImagesPath)
            .child(fileName);

        final UploadTask uploadTask = ref.putFile(imageFiles[i]);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload product images: ${e.toString()}');
    }
  }

  /// Delete file by URL
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  /// Delete multiple files by URLs
  Future<void> deleteFiles(List<String> downloadUrls) async {
    try {
      for (final url in downloadUrls) {
        await deleteFile(url);
      }
    } catch (e) {
      throw Exception('Failed to delete files: ${e.toString()}');
    }
  }

  /// Get upload progress stream
  Stream<double> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
