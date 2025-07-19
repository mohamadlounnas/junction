import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service for handling property comparison functionality
class ComparisonService {
  static const String _baseUrl = 'https://junction.feeef.org';

  /// Compare two properties and generate a professional comparison PDF
  static Future<Map<String, dynamic>> compareProperties({
    required String property1Id,
    required String property2Id,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/quotes/compare-pdf'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'property1Id': property1Id,
          'property2Id': property2Id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to compare properties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Download comparison PDF
  static Future<http.Response> downloadComparisonPDF(String fileName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/quotes/download-comparison/$fileName'),
      );

      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }

  /// Open comparison PDF in browser
  static Future<bool> openComparisonPDF(String fileName) async {
    try {
      final url = Uri.parse('$_baseUrl/api/quotes/download-comparison/$fileName');
      
      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch URL: $url');
      }
    } catch (e) {
      throw Exception('Failed to open PDF: $e');
    }
  }

  /// Open comparison PDF in new tab (web only)
  static Future<bool> openComparisonPDFInNewTab(String fileName) async {
    try {
      final url = Uri.parse('$_baseUrl/api/quotes/download-comparison/$fileName');
      
      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } else {
        throw Exception('Could not launch URL: $url');
      }
    } catch (e) {
      throw Exception('Failed to open PDF in new tab: $e');
    }
  }
} 