import 'dart:io';
import 'package:http/http.dart' as http;

/// IO-specific implementation for handling file uploads on mobile platforms
/// This implementation uses dart:io and can handle File objects
class PropertyServicePlatform {
  /// Add images to a multipart request
  /// This method handles File objects for mobile platforms
  static Future<void> addImagesToRequest(
    http.MultipartRequest request,
    List<dynamic> images,
  ) async {
    for (int i = 0; i < images.length; i++) {
      if (images[i] is File) {
        final file = await http.MultipartFile.fromPath(
          'imageFiles',
          images[i].path,
        );
        request.files.add(file);
      }
    }
  }
} 