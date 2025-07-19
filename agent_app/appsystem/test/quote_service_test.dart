import 'package:flutter_test/flutter_test.dart';
import 'package:appsystem/services/quote_service.dart';

void main() {
  group('QuoteService Tests', () {
    test('CompanyInfo should serialize correctly', () {
      final companyInfo = CompanyInfo(
        name: 'Test Company',
        address: 'Test Address',
        phone: '+1234567890',
        email: 'test@example.com',
        website: 'www.test.com',
        taxId: '123456789',
      );

      final json = companyInfo.toJson();

      expect(json['name'], 'Test Company');
      expect(json['address'], 'Test Address');
      expect(json['phone'], '+1234567890');
      expect(json['email'], 'test@example.com');
      expect(json['website'], 'www.test.com');
      expect(json['taxId'], '123456789');
    });

    test('QuoteRequest should serialize correctly', () {
      final request = QuoteRequest(
        propertyId: 'test-property-id',
        contactId: 'test-contact-id',
        language: 'ar',
        format: 'A4',
        orientation: 'portrait',
        companyInfo: CompanyInfo(name: 'Test Company'),
      );

      final json = request.toJson();

      expect(json['propertyId'], 'test-property-id');
      expect(json['contactId'], 'test-contact-id');
      expect(json['language'], 'ar');
      expect(json['format'], 'A4');
      expect(json['orientation'], 'portrait');
      expect(json['companyInfo'], isA<Map<String, dynamic>>());
    });

    test('QuoteResponse should deserialize correctly', () {
      final json = {
        'success': true,
        'pdf': {
          'fileName': 'test-quote.pdf',
          'downloadUrl': '/api/quotes/download/test-quote.pdf',
          'quote': {
            'quoteNumber': 'QUO-20250101-001',
            'totalAmount': 1000000,
            'currency': 'DZD',
            'validUntil': '2025-02-01T00:00:00.000Z',
          },
        },
        'message': 'Success',
      };

      final response = QuoteResponse.fromJson(json);

      expect(response.success, true);
      expect(response.message, 'Success');
      expect(response.pdf, isNotNull);
      expect(response.pdf!.fileName, 'test-quote.pdf');
      expect(response.pdf!.downloadUrl, '/api/quotes/download/test-quote.pdf');
      expect(response.pdf!.quote.quoteNumber, 'QUO-20250101-001');
      expect(response.pdf!.quote.totalAmount, 1000000);
      expect(response.pdf!.quote.currency, 'DZD');
    });

    test('QuoteService.formatPrice should format correctly', () {
      expect(QuoteService.formatPrice(1000), '1K دج');
      expect(QuoteService.formatPrice(1000000), '1.0M دج');
      expect(QuoteService.formatPrice(500), '500 دج');
      expect(QuoteService.formatPrice(1500000), '1.5M دج');
    });

    test('QuoteService.getDefaultCompanyInfo should return default values', () {
      final defaultInfo = QuoteService.getDefaultCompanyInfo();

      expect(defaultInfo.name, 'شركة العقارات الذكية');
      expect(defaultInfo.address, 'الجزائر العاصمة، الجزائر');
      expect(defaultInfo.phone, '+213 123 456 789');
      expect(defaultInfo.email, 'info@smartcontact.dz');
      expect(defaultInfo.website, 'www.smartcontact.dz');
      expect(defaultInfo.taxId, '123456789');
    });

    test('QuoteDetails should deserialize correctly', () {
      final json = {
        'quoteNumber': 'QUO-20250101-001',
        'totalAmount': 1000000,
        'currency': 'DZD',
        'validUntil': '2025-02-01T00:00:00.000Z',
      };

      final details = QuoteDetails.fromJson(json);

      expect(details.quoteNumber, 'QUO-20250101-001');
      expect(details.totalAmount, 1000000);
      expect(details.currency, 'DZD');
      expect(details.validUntil, DateTime.parse('2025-02-01T00:00:00.000Z'));
    });

    test('QuoteData should deserialize correctly', () {
      final json = {
        'fileName': 'test-quote.pdf',
        'downloadUrl': '/api/quotes/download/test-quote.pdf',
        'quote': {
          'quoteNumber': 'QUO-20250101-001',
          'totalAmount': 1000000,
          'currency': 'DZD',
          'validUntil': '2025-02-01T00:00:00.000Z',
        },
      };

      final data = QuoteData.fromJson(json);

      expect(data.fileName, 'test-quote.pdf');
      expect(data.downloadUrl, '/api/quotes/download/test-quote.pdf');
      expect(data.quote.quoteNumber, 'QUO-20250101-001');
      expect(data.quote.totalAmount, 1000000);
    });
  });
}
