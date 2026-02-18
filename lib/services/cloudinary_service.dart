/// Cloudinary Image Upload Service
///
/// Handles image uploads to Cloudinary CDN
library;

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // 🔐 CLOUDINARY CREDENTIALS
  // ⚠️ Replace with your actual values from Cloudinary Dashboard
  static const String cloudName =
      "dfoxfil5q"; // Get from: https://cloudinary.com/console
  static const String uploadPreset =
      "uzhavu_products"; // Create in: Settings → Upload → Upload presets

  /// Uploads an image file to Cloudinary
  ///
  /// Returns the secure HTTPS URL of the uploaded image
  /// Returns null if upload fails
  ///
  /// Example:
  /// ```dart
  /// File imageFile = File('/path/to/image.jpg');
  /// String? imageUrl = await CloudinaryService().uploadImage(imageFile);
  /// if (imageUrl != null) {
  ///   print('Image uploaded: $imageUrl');
  /// }
  /// ```
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Step 1: Create Cloudinary upload URL
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // Step 2: Create multipart request (required for file uploads)
      final request = http.MultipartRequest('POST', url);

      // Step 3: Attach the image file
      // MultipartFile.fromPath automatically reads the file and sets the content type
      final file = await http.MultipartFile.fromPath(
        'file', // Field name expected by Cloudinary
        imageFile.path,
      );
      request.files.add(file);

      // Step 4: Add upload preset (enables unsigned uploads)
      // This preset must be created in Cloudinary dashboard
      request.fields['upload_preset'] = uploadPreset;

      // Step 5: Send the request to Cloudinary
      print('📤 Uploading image to Cloudinary...');
      final response = await request.send();

      // Step 6: Read the response
      final responseData = await response.stream.bytesToString();

      // Step 7: Check if upload was successful
      if (response.statusCode == 200) {
        // Parse JSON response
        final jsonResponse = json.decode(responseData);

        // Extract secure URL (HTTPS)
        final imageUrl = jsonResponse['secure_url'] as String;

        print('✅ Image uploaded successfully!');
        print('🔗 URL: $imageUrl');

        return imageUrl;
      } else {
        // Upload failed - log error
        print('❌ Upload failed with status: ${response.statusCode}');
        print('Response: $responseData');
        return null;
      }
    } catch (e) {
      // Handle any errors during upload
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Optional: Upload multiple images at once
  ///
  /// Returns a list of image URLs
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];

    for (File imageFile in imageFiles) {
      final url = await uploadImage(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }
}
