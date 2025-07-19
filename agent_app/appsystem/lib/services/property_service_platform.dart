import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Platform-agnostic interface for handling file uploads
/// This is the default implementation for web platforms
abstract class PropertyServicePlatform {
  /// Add images to a multipart request
  /// This method handles platform-specific file upload logic
  static Future<void> addImagesToRequest(
    http.MultipartRequest request,
    List<dynamic> images,
  ) async {
    // Web platform implementation using XFile and Uint8List
    for (int i = 0; i < images.length; i++) {
      if (images[i] is XFile) {
        try {
          final XFile xFile = images[i];
          final Uint8List bytes = await xFile.readAsBytes();
          final String fileName = xFile.name;
          
          final multipartFile = http.MultipartFile.fromBytes(
            'imageFiles',
            bytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error adding image to request: $e');
        }
      }
    }
  }
} 