import 'dart:convert';
import 'package:http/http.dart' as http;

/// Company information model for quote generation
class CompanyInfo {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String taxId;

  const CompanyInfo({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.taxId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'taxId': taxId,
    };
  }
}

/// Quote generation request model
class QuoteRequest {
  final String propertyId;
  final String contactId;
  final String language;
  final String format;
  final String orientation;
  final CompanyInfo companyInfo;

  const QuoteRequest({
    required this.propertyId,
    required this.contactId,
    this.language = 'ar',
    this.format = '',
    this.orientation = '',
    this.companyInfo = const CompanyInfo(),
  });

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'contactId': contactId,
      'language': language,
      'format': format,
      'orientation': orientation,
      'companyInfo': companyInfo.toJson(),
    };
  }
}

/// Quote details model
class QuoteDetails {
  final String quoteNumber;
  final double totalAmount;
  final String currency;
  final DateTime validUntil;

  const QuoteDetails({
    required this.quoteNumber,
    required this.totalAmount,
    required this.currency,
    required this.validUntil,
  });

  factory QuoteDetails.fromJson(Map<String, dynamic> json) {
    return QuoteDetails(
      quoteNumber: json['quoteNumber'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'DZD',
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : DateTime.now().add(const Duration(days: 30)),
    );
  }
}

/// Quote data model
class QuoteData {
  final String fileName;
  final String downloadUrl;
  final QuoteDetails quote;

  const QuoteData({
    required this.fileName,
    required this.downloadUrl,
    required this.quote,
  });

  factory QuoteData.fromJson(Map<String, dynamic> json) {
    return QuoteData(
      fileName: json['fileName'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      quote: QuoteDetails.fromJson(json['quote'] ?? {}),
    );
  }
}

/// Quote response model
class QuoteResponse {
  final bool success;
  final QuoteData? pdf;
  final String? message;

  const QuoteResponse({required this.success, this.pdf, this.message});

  factory QuoteResponse.fromJson(Map<String, dynamic> json) {
    return QuoteResponse(
      success: json['success'] ?? false,
      pdf: json['pdf'] != null ? QuoteData.fromJson(json['pdf']) : null,
      message: json['message'],
    );
  }
}

/// Quote PDF Generation Service
///
/// Handles the generation of PDF quotes for properties with contact information.
/// Features:
/// - Generate PDF quotes with property and contact details
/// - Support for multiple languages (Arabic/English)
/// - Customizable company information
/// - Download functionality for generated PDFs
class QuoteService {
  static const String _baseUrl = 'https://junction.feeef.org/api';
  static const Duration _timeout = Duration(seconds: 60);

  /// Generate PDF quote
  ///
  /// [request] - The quote generation request containing property and contact details
  /// Returns a [QuoteResponse] with the generated PDF information
  static Future<QuoteResponse> generatePdfQuote(QuoteRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/quotes/pdf'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return QuoteResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        return QuoteResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to generate PDF quote',
        );
      }
    } catch (e) {
      return QuoteResponse(success: false, message: 'Network error: $e');
    }
  }

  /// Download PDF quote
  ///
  /// [fileName] - The name of the PDF file to download
  /// Returns the PDF file as bytes
  static Future<List<int>?> downloadPdfQuote(String fileName) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/quotes/download/$fileName'),
            headers: {'Accept': 'application/pdf'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Generate and download PDF quote in one operation
  ///
  /// [request] - The quote generation request
  /// Returns the PDF file as bytes if successful
  static Future<List<int>?> generateAndDownloadPdfQuote(
    QuoteRequest request,
  ) async {
    try {
      final quoteResponse = await generatePdfQuote(request);

      if (quoteResponse.success && quoteResponse.pdf != null) {
        return await downloadPdfQuote(quoteResponse.pdf!.fileName);
      } else {
        throw Exception(
          quoteResponse.message ?? 'Failed to generate PDF quote',
        );
      }
    } catch (e) {
      throw Exception('Error generating and downloading PDF: $e');
    }
  }

  /// Get formatted price in Algerian Dinar
  static String formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M دج';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K دج';
    }
    return '${price.toStringAsFixed(0)} دج';
  }

  /// Get default company information
  static CompanyInfo getDefaultCompanyInfo() {
    return const CompanyInfo(
      name: 'شركة العقارات الذكية',
      address: 'الجزائر العاصمة، الجزائر',
      phone: '+213 123 456 789',
      email: 'info@smartcontact.dz',
      website: 'www.smartcontact.dz',
      taxId: '123456789',
    );
  }
}
